import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/state/game_state.dart';
import '../../theme/colors.dart';
import '../../widgets/chat_bubble.dart';

class SecretChatScreen extends ConsumerWidget {
  final String threadId;

  const SecretChatScreen({super.key, required this.threadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    final threadStream = (db.select(db.threads)..where((t) => t.id.equals(threadId))).watchSingleOrNull();
    final messagesStream = (db.select(db.messages)
      ..where((m) => m.threadId.equals(threadId))
      ..orderBy([(m) => OrderingTerm(expression: m.timestamp, mode: OrderingMode.asc)]))
      .watch();

    return Scaffold(
      backgroundColor: Colors.black, // darker than standard background
      body: Stack(
        children: [
          // [0] Background
          Image.asset(
            'assets/backgrounds/chat_bg_loop.png', // Reuse or new? Spec says "Same as Chat Screen but..."
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            color: Colors.red.withOpacity(0.1), // Red tint for danger
            colorBlendMode: BlendMode.overlay,
            errorBuilder: (c,e,s) => Container(color: const Color(0xFF050000)),
          ),
          // [1] Glitch Overlay (Stronger)
          Opacity(
            opacity: 0.1, // Stronger glitch
            child: Image.asset(
              'assets/ui/glitch_overlay.png',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c,e,s) => const SizedBox(),
            ),
          ),

          // [2] Content
          Column(
            children: [
              // Custom Header
              Container(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 10, left: 16, right: 16),
                color: Colors.black.withOpacity(0.8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: DreadmoorColors.accentRed),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "INTERCEPTED FEED",
                            style: GoogleFonts.michroma(
                              fontSize: 14,
                              color: DreadmoorColors.accentRed,
                              letterSpacing: 2.0,
                            ),
                          ),
                          StreamBuilder<Thread?>(
                            stream: threadStream,
                            builder: (context, snapshot) {
                              return Text(
                                (snapshot.data?.title ?? "UNKNOWN SOURCE").toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: DreadmoorColors.accentRed.withOpacity(0.6),
                                  letterSpacing: 1.0,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.lock, color: DreadmoorColors.accentRed, size: 16),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<List<Message>>(
                  stream: messagesStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: DreadmoorColors.accentRed));
                    final messages = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return Opacity(
                          opacity: 0.8,
                          child: ChatBubble(
                            text: msg.content,
                            isMe: false, // Never me in spy mode
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Footer Warning
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black,
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
