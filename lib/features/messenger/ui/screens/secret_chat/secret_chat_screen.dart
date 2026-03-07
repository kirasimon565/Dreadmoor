import 'dart:ui';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/widgets/chat_bubble.dart';

class SecretChatScreen extends ConsumerStatefulWidget {
  final String threadId;
  const SecretChatScreen({super.key, required this.threadId});

  @override
  ConsumerState<SecretChatScreen> createState() => _SecretChatScreenState();
}

class _SecretChatScreenState extends ConsumerState<SecretChatScreen> {
  final _scrollController = ScrollController();

  // ✅ Streams created once in initState — never recreated on rebuild
  late final Stream<Thread?> _threadStream;
  late final Stream<List<Message>> _messagesStream;

  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    // ✅ ref.read — we only need the db instance once to set up streams
    final db = ref.read(databaseProvider);

    _threadStream = (db.select(
      db.threads,
    )..where((t) => t.id.equals(widget.threadId))).watchSingleOrNull();

    _messagesStream =
        (db.select(db.messages)
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
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(max);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Dark muted background ─────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/chat_bg_texture.png',
              fit: BoxFit.cover,
              color: Colors.red.withOpacity(0.08),
              colorBlendMode: BlendMode.overlay,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF080808)),
            ),
          ),

          // ── Stronger glitch overlay (spy mode feels hacked) ───────────
          IgnorePointer(
            child: Opacity(
              opacity: 0.10,
              child: Image.asset(
                'assets/ui/glitch_overlay.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // ── Main column ───────────────────────────────────────────────
          Column(
            children: [
              // ── Header ───────────────────────────────────────────────
              _SecretHeader(
                threadStream: _threadStream,
                onClose: () {
                  HapticFeedback.selectionClick();
                  context.pop();
                },
              ),

              // ── Spy status bar ────────────────────────────────────────
              const _SpyStatusBar(),

              // ── Messages ──────────────────────────────────────────────
              Expanded(
                child: StreamBuilder<List<Message>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? [];

                    // ✅ Scroll only when message count changes
                    if (messages.length != _lastMessageCount) {
                      _lastMessageCount = messages.length;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom(animated: _lastMessageCount > 1);
                      });
                    }

                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          "DECRYPTING...",
                          style: GoogleFonts.michroma(
                            fontSize: 11,
                            letterSpacing: 3.0,
                            color: DreadmoorColors.accentRed.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        // ✅ Spy mode: muted opacity, never shows as player
                        return Opacity(
                          opacity: 0.72,
                          child: ChatBubble(
                            text: msg.content ?? "",
                            isMe: false,
                            senderId: msg.senderId,
                            timestamp: msg.timestamp,
                            isSecret: true,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Read-only footer ──────────────────────────────────────
              const _ReadOnlyFooter(),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _SecretHeader extends StatelessWidget {
  final Stream<Thread?> threadStream;
  final VoidCallback onClose;

  const _SecretHeader({required this.threadStream, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            top: topPadding + 8,
            bottom: 10,
            left: 8,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.82),
            border: Border(
              bottom: BorderSide(
                color: DreadmoorColors.accentRed.withOpacity(0.35),
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            children: [
              // Close button
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: DreadmoorColors.accentRed,
                  size: 20,
                ),
                onPressed: onClose,
                tooltip: 'Close',
              ),

              const SizedBox(width: 4),

              // Titles
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "INTERCEPTED CONVERSATION",
                      style: GoogleFonts.michroma(
                        fontSize: 11,
                        color: DreadmoorColors.accentRed,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    StreamBuilder<Thread?>(
                      stream: threadStream,
                      builder: (context, snapshot) {
                        final title = snapshot.data?.title ?? "UNKNOWN SOURCE";
                        return Text(
                          title.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: DreadmoorColors.accentRed.withValues(
                              alpha: 0.55,
                            ),
                            letterSpacing: 1.0,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Lock icon
              Icon(
                Icons.lock_outline_rounded,
                color: DreadmoorColors.accentRed.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Spy status bar ──────────────────────────────────────────────────────────
// Layout: VPN: ACTIVE (left) | ENCRYPTION: HIGH (center) | MODE: INVISIBLE (right)

class _SpyStatusBar extends StatefulWidget {
  const _SpyStatusBar();

  @override
  State<_SpyStatusBar> createState() => _SpyStatusBarState();
}

class _SpyStatusBarState extends State<_SpyStatusBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;
  late final Animation<double> _blinkOpacity;

  @override
  void initState() {
    super.initState();
    // VPN label blinks slowly to feel live
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _blinkOpacity = Tween<double>(
      begin: 0.45,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _blink, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.78),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // ── Left: VPN (blinks to feel active) ────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _blinkOpacity,
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: DreadmoorColors.accentRed,
                    ),
                  ),
                  Text(
                    "VPN: ACTIVE",
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: DreadmoorColors.accentRed,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Center: ENCRYPTION ────────────────────────────────────
          Expanded(
            child: Center(
              child: Text(
                "ENCRYPTION: HIGH",
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.45),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // ── Right: MODE ───────────────────────────────────────────
          Expanded(
            child: Text(
              "MODE: INVISIBLE",
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: Colors.white.withOpacity(0.45),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Read-only footer ────────────────────────────────────────────────────────

class _ReadOnlyFooter extends StatelessWidget {
  const _ReadOnlyFooter();

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(
        top: 12,
        bottom: 12 + bottomPadding,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.92),
        border: Border(
          top: BorderSide(
            color: DreadmoorColors.accentRed.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Center(
        child: Text(
          "READ-ONLY  ·  DECRYPTION ACTIVE",
          style: GoogleFonts.michroma(
            fontSize: 9,
            color: DreadmoorColors.accentRed.withOpacity(0.4),
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}
