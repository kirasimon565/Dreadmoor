import 'dart:ui';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/widgets/chat_bubble.dart';

class SecretChatScreen extends ConsumerStatefulWidget {
  final String threadId;
  const SecretChatScreen({super.key, required this.threadId});

  @override
  ConsumerState<SecretChatScreen> createState() => _SecretChatScreenState();
}

class _SecretChatScreenState extends ConsumerState<SecretChatScreen> {
  final _scrollController = ScrollController();
  late final Stream<Thread?> _threadStream;
  late final Stream<List<Message>> _messagesStream;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    final db = ref.read(databaseProvider);

    _threadStream = (db.select(db.threads)..where((t) => t.id.equals(widget.threadId))).watchSingleOrNull();
    _messagesStream = (db.select(db.messages)
          ..where((m) => m.threadId.equals(widget.threadId))
          ..orderBy([(m) => OrderingTerm(expression: m.timestamp)]))
        .watch();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(max, duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    } else {
      _scrollController.jumpTo(max);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Near pure black for secret mode
      body: Stack(
        children: [
          // ── MAIN COLUMN ───────────────────────────────────────────────
          Column(
            children: [
              // ── REDESIGNED HEADER (Pill Style) ───────────────────────
              _SecretHeader(
                threadStream: _threadStream,
                onClose: () => Navigator.pop(context),
              ),

              // ── MESSAGES ──────────────────────────────────────────────
              Expanded(
                child: StreamBuilder<List<Message>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? [];

                    if (messages.length != _lastMessageCount) {
                      _lastMessageCount = messages.length;
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                    }

                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          "SYNCHRONIZING...",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            letterSpacing: 4.0,
                            color: DreadmoorColors.evidenceRed.withOpacity(0.4),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return ChatBubble(
                          text: msg.content ?? "",
                          isMe: false, // You are just eavesdropping
                          senderId: msg.senderId,
                          timestamp: msg.timestamp,
                          isSecret: true,
                        );
                      },
                    );
                  },
                ),
              ),

              // ── SPY STATUS BAR (Moved to bottom per request) ──────────
              const _SpyStatusBar(),
            ],
          ),
        ],
      ),
    );
  }
}

// ── HEADER (Following the "Unknown" pill design) ───────────────────────────

class _SecretHeader extends StatelessWidget {
  final Stream<Thread?> threadStream;
  final VoidCallback onClose;

  const _SecretHeader({required this.threadStream, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 10),
      color: Colors.black,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: DreadmoorColors.evidenceRed.withOpacity(0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: DreadmoorColors.evidenceRed.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, color: Colors.white70, size: 20),
              ),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "INTERCEPTED SIGNAL",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.5
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.security, color: Colors.white38, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SPY STATUS BAR (Bottom Navigation Style) ────────────────────────────────

class _SpyStatusBar extends StatefulWidget {
  const _SpyStatusBar();
  @override
  State<_SpyStatusBar> createState() => _SpyStatusBarState();
}

class _SpyStatusBarState extends State<_SpyStatusBar> with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 12, 
        bottom: MediaQuery.of(context).padding.bottom + 12, 
        left: 20, 
        right: 20
      ),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // VPN: ACTIVE
          Row(
            children: [
              FadeTransition(
                opacity: _blink,
                child: Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: DreadmoorColors.evidenceRed)),
              ),
              const SizedBox(width: 8),
              _statusText("VPN: ACTIVE"),
            ],
          ),
          _statusText("ENCRYPTION: 256-BIT"),
          _statusText("IDENTITY: HIDDEN"),
        ],
      ),
    );
  }

  Widget _statusText(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 9,
        color: Colors.white.withOpacity(0.6),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }
}
