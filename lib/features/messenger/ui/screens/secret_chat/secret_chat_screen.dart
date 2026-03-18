import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/widgets/chat_bubble.dart';
import 'package:dreadmoor/ui/widgets/choice_overlay.dart';
import 'package:dreadmoor/ui/widgets/gun_typing_indicator.dart';

class SecretChatScreen extends ConsumerStatefulWidget {
  final String threadId;
  const SecretChatScreen({super.key, required this.threadId});

  @override
  ConsumerState<SecretChatScreen> createState() =>
      _SecretChatScreenState();
}

class _SecretChatScreenState
    extends ConsumerState<SecretChatScreen> {
  final _scrollController = ScrollController();
  late final Stream<Thread?> _threadStream;
  late final Stream<List<Message>> _messagesStream;
  int _lastCount = 0;

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
        ref.read(activeThreadIdProvider.notifier).state =
            widget.threadId;
      }
    });
  }

  @override
  void dispose() {
    ref.read(activeAppProvider.notifier).state = PhoneApp.messenger;
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(max,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut);
    } else {
      _scrollController.jumpTo(max);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // From mockup: radial gradient, black centre → deep navy edges
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF000000),
              Color(0xFF0D1B2A),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── HEADER ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: StreamBuilder<Thread?>(
                      stream: _threadStream,
                      builder: (context, snap) {
                        final title =
                            snap.data?.title ?? 'Unknown';
                        return Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            // Back arrow
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pop(context),
                              child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                  size: 24),
                            ),

                            // Centre pill — bottom-rounded corners only
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white
                                      .withOpacity(0.8),
                                  width: 1.5,
                                ),
                                borderRadius:
                                    const BorderRadius.only(
                                  bottomLeft:
                                      Radius.circular(20),
                                  bottomRight:
                                      Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.w400,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Online',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration:
                                            const BoxDecoration(
                                          color: Colors.green,
                                          shape:
                                              BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Live icon
                            const Icon(Icons.live_tv,
                                color: Colors.white, size: 24),
                          ],
                        );
                      },
                    ),
                  ),

                  // ── MESSAGES ──────────────────────────────────────
                  Expanded(
                    child: StreamBuilder<List<Message>>(
                      stream: _messagesStream,
                      builder: (context, snap) {
                        final messages = snap.data ?? [];

                        if (messages.length != _lastCount) {
                          _lastCount = messages.length;
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) =>
                                  _scrollToBottom(
                                      animated:
                                          _lastCount > 1));
                        }

                        if (messages.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          physics:
                              const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: messages.length + 1,
                          itemBuilder: (context, i) {
                            if (i == messages.length) {
                              return _buildTypingIndicator();
                            }
                            final msg = messages[i];
                            return ChatBubble(
                              text:    msg.content ?? '',
                              isMe:    msg.isPlayerMessage,
                              senderId: msg.senderId,
                              timestamp: msg.timestamp,
                              isSecret: true,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Space for bottom status bar + choice overlay
                  const SizedBox(height: 50),
                ],
              ),

              // ── CHOICE OVERLAY / INPUT BAR ─────────────────────────
              const ChoiceOverlay(),

              // ── STATUS BAR — fixed at bottom ───────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 10),
                  color: Colors.black.withOpacity(0.3),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                    children: const [
                      _StatusText(
                          label: 'VPN', value: 'ACTIVE'),
                      _StatusText(
                          label: 'ENCRYPTION', value: 'HIGH'),
                      _StatusText(
                          label: 'IDENTITY',
                          value: 'HIDDEN'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<Thread?>(
      stream: _threadStream,
      builder: (context, snap) {
        if (snap.data?.isTyping == true) {
          return const Padding(
            padding: EdgeInsets.only(left: 20, bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GunTypingIndicator(),
            ),
          );
        }
        return const SizedBox(height: 8);
      },
    );
  }
}

// ── STATUS TEXT ───────────────────────────────────────────────────────────────

class _StatusText extends StatelessWidget {
  final String label;
  final String value;

  const _StatusText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.5,
      ),
    );
  }
}
