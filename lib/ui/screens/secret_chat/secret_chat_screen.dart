import 'dart:ui';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/state/game_state.dart';
import '../../theme/colors.dart';
import '../../widgets/chat_bubble.dart';

class SecretChatScreen extends ConsumerStatefulWidget {
  final String threadId;

  const SecretChatScreen({super.key, required this.threadId});

  @override
  ConsumerState<SecretChatScreen> createState() => _SecretChatScreenState();
}

class _SecretChatScreenState extends ConsumerState<SecretChatScreen> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    final threadStream =
        (db.select(db.threads)..where((t) => t.id.equals(widget.threadId)))
            .watchSingleOrNull();

    final messagesStream = (db.select(db.messages)
          ..where((m) => m.threadId.equals(widget.threadId))
          ..orderBy([(m) => OrderingTerm(expression: m.timestamp)]))
        .watch();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // [0] Dark Muted Background (static texture)
          Image.asset(
            'assets/backgrounds/chat_bg_texture.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            color: Colors.red.withOpacity(0.12),
            colorBlendMode: BlendMode.overlay,
          ),

          // [1] Stronger Glitch Overlay
          IgnorePointer(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/ui/glitch_overlay.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          Column(
            children: [
              // ───────── HEADER ─────────
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      bottom: 10,
                      left: 16,
                      right: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      border: Border(
                        bottom: BorderSide(
                          color: DreadmoorColors.accentRed.withOpacity(0.4),
                          width: 0.6,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: DreadmoorColors.accentRed),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "INTERCEPTED CONVERSATION",
                                style: GoogleFonts.michroma(
                                  fontSize: 13,
                                  color: DreadmoorColors.accentRed,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              StreamBuilder<Thread?>(
                                stream: threadStream,
                                builder: (context, snapshot) {
                                  return Text(
                                    (snapshot.data?.title ??
                                            "UNKNOWN SOURCE")
                                        .toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: DreadmoorColors.accentRed
                                          .withOpacity(0.6),
                                      letterSpacing: 1.0,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.lock,
                            color: DreadmoorColors.accentRed, size: 16),
                      ],
                    ),
                  ),
                ),
              ),

              // ───────── STATUS BAR ─────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "MODE: HIDDEN",
                        style: GoogleFonts.shareTechMono(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "VPN: ACTIVATED",
                          style: GoogleFonts.shareTechMono(
                            fontSize: 10,
                            color: DreadmoorColors.accentRed.withOpacity(0.7),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "ENCRYPTION: HIGH",
                        textAlign: TextAlign.end,
                        style: GoogleFonts.shareTechMono(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ───────── CHAT ─────────
              Expanded(
                child: StreamBuilder<List<Message>>(
                  stream: messagesStream,
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? [];

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(
                          _scrollController.position.maxScrollExtent,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return Opacity(
                          opacity: 0.75, // Muted look
                          child: ChatBubble(
                            text: msg.content,
                            isMe: false, // Spy mode: never player
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ───────── FOOTER ─────────
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: Text(
                    "READ-ONLY MODE // DECRYPTION ACTIVE",
                    style: GoogleFonts.michroma(
                      fontSize: 10,
                      color: DreadmoorColors.accentRed.withOpacity(0.5),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
