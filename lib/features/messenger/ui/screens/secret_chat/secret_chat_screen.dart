import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/os/os_state.dart';
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

    _threadStream = (db.select(db.threads)
          ..where((t) => t.id.equals(widget.threadId)))
        .watchSingleOrNull();

    _messagesStream = (db.select(db.messages)
          ..where((m) => m.threadId.equals(widget.threadId))
          ..orderBy([(m) => OrderingTerm(expression: m.timestamp)]))
        .watch();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(showNavigationBarProvider.notifier).state = false;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(showNavigationBarProvider.notifier).state = true;
      }
    });
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
    const navyBackground = Color(0xFF0B1220);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: navyBackground,
          body: Stack(
            children: [
              // ── ASSET BACKGROUND ──────────────────────────────────────────────
              Positioned.fill(
                child: Image.asset(
                  'assets/images/forest_bg.png', // Assuming this is used instead of a specific hacked bg as none was listed in the directive checklist, but I will tint it navy.
                  fit: BoxFit.cover,
                  color: navyBackground.withOpacity(0.9),
                  colorBlendMode: BlendMode.srcATop,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

              // ── RADIAL VIGNETTE ───────────────────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.75,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            // ── MAIN LAYOUT ───────────────────────────────────────────────────
            Column(
              children: [
                // ── HEADER ────────────────────────────────────────────────────
                _SecretHeader(
                  threadStream: _threadStream,
                  onClose: () => Navigator.pop(context),
                ),

                // ── MESSAGES ──────────────────────────────────────────────────
                Expanded(
                  child: StreamBuilder<List<Message>>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      final messages = snapshot.data ?? [];

                      if (messages.length != _lastMessageCount) {
                        _lastMessageCount = messages.length;
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToBottom(),
                        );
                      }

                      if (messages.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return ChatBubble(
                            text: msg.content ?? '',
                            isMe: false,
                            senderId: msg.senderId,
                            timestamp: msg.timestamp,
                            isSecret: true,
                          );
                        },
                      );
                    },
                  ),
                ),

                // ── STATUS BAR ────────────────────────────────────────────────
                const _SpyStatusBar(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── HEADER ────────────────────────────────────────────────────────────────────

class _SecretHeader extends StatelessWidget {
  final Stream<Thread?> threadStream;
  final VoidCallback onClose;

  const _SecretHeader({required this.threadStream, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding + 8,
        bottom: 12,
        left: 12,
        right: 12,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── PILL ────────────────────────────────────────────────────────────
          StreamBuilder<Thread?>(
            stream: threadStream,
            builder: (context, snapshot) {
              final name = snapshot.data?.title ?? 'Amelia & Michael';

              return Container(
                width: MediaQuery.of(context).size.width * 0.62,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white, width: 1.4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Online',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3DDB5E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // ── BACK ARROW ──────────────────────────────────────────────────────
          // Intentionally removed per directive "Player cannot navigate away manually"

          // ── LIVE BADGE ──────────────────────────────────────────────────────
          Positioned(
            right: 0,
            child: _LiveBadge(),
          ),
        ],
      ),
    );
  }
}

// ── LIVE BADGE ────────────────────────────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70, width: 1.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 3),
          FadeTransition(
            opacity: _blink,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SPY STATUS BAR ────────────────────────────────────────────────────────────

class _SpyStatusBar extends StatefulWidget {
  const _SpyStatusBar();

  @override
  State<_SpyStatusBar> createState() => _SpyStatusBarState();
}

class _SpyStatusBarState extends State<_SpyStatusBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
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
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
        left: 20,
        right: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              FadeTransition(
                opacity: _blink,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _statusText('VPN: ACTIVE'),
            ],
          ),
          _statusText('ENCRYPTION: HIGH'),
          _statusText('IDENTITY: HIDDEN'),
        ],
      ),
    );
  }

  Widget _statusText(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 10,
        color: Colors.white.withOpacity(0.75),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}
