import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/ui/widgets/chat_bubble.dart';
import 'package:dreadmoor/ui/widgets/choice_overlay.dart';
import 'package:dreadmoor/ui/widgets/gun_typing_indicator.dart';
import 'chat_header_neon_group.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String threadId;
  const ChatScreen({super.key, required this.threadId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  late final Stream<Thread?> _threadStream;
  late final Stream<List<TypedResult>> _messagesStream;
  late final Stream<List<ThreadMember>> _membersStream;
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
        .join([
          leftOuterJoin(
            db.characters,
            db.characters.id.equalsExp(db.messages.senderId),
          ),
        ]).watch();

    // Watch members to know if this is a group thread
    _membersStream = (db.select(db.threadMembers)
          ..where((m) => m.threadId.equals(widget.threadId)))
        .watch();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(activeThreadIdProvider.notifier).state = widget.threadId;
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1520),
        body: StreamBuilder<List<ThreadMember>>(
          stream: _membersStream,
          builder: (context, membersSnap) {
            final members = membersSnap.data ?? [];
            final isGroup = members.length > 1;

            // Build avatar path list for all members
            final avatarPaths = members
                .map((m) => 'assets/images/characters/${m.characterId}.png')
                .toList();

            return Stack(
              fit: StackFit.expand,
              children: [
                // ── BACKGROUND IMAGE (switches single ↔ group) ───────────
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: Image.asset(
                      isGroup
                          ? 'assets/media/images/group_chat_bg.png'   // ← your group bg
                          : 'assets/media/images/forest_bg.png',       // ← your single bg
                      key: ValueKey(isGroup),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _FallbackBackground(
                        isGroup: isGroup,
                      ),
                    ),
                  ),
                ),

                // ── TOP GRADIENT (readability) ───────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 160,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.40),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── MAIN LAYOUT ──────────────────────────────────────────
                Column(
                  children: [
                    // 1. DYNAMIC HEADER
                    StreamBuilder<Thread?>(
                      stream: _threadStream,
                      builder: (context, snap) {
                        final thread = snap.data;
                        return ChatHeaderNeonGroup(
                          title: thread?.title ?? 'Unknown',
                          onBackPressed: () => Navigator.pop(context),
                          avatarPaths: avatarPaths,
                          isOnline: true,
                        );
                      },
                    ),

                    // 2. MESSAGES
                    Expanded(
                      child: StreamBuilder<List<TypedResult>>(
                        stream: _messagesStream,
                        builder: (context, snapshot) {
                          final messages = snapshot.data ?? [];

                          if (messages.length != _lastMessageCount) {
                            _lastMessageCount = messages.length;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToBottom(animated: _lastMessageCount > 1);
                            });
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            itemCount: messages.length + 1,
                            itemBuilder: (context, index) {
                              if (index == messages.length) {
                                return _buildTypingIndicator();
                              }

                              final row = messages[index];
                              final db = ref.read(databaseProvider);
                              final msg = row.readTable(db.messages);
                              final character =
                                  row.readTableOrNull(db.characters);

                              return ChatBubble(
                                text: msg.content ?? '',
                                isMe: msg.isPlayerMessage,
                                senderId: msg.senderId,
                                senderName: character?.name,
                                timestamp: msg.timestamp,
                                isSecret: msg.isSecret,
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // 3. Bottom clearance for the input overlay
                    const SizedBox(height: 90),
                  ],
                ),

                // 4. CHOICE OVERLAY / INPUT BAR
                const ChoiceOverlay(),
              ],
            );
          },
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
            padding: EdgeInsets.only(left: 20, bottom: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GunTypingIndicator(),
            ),
          );
        }
        return const SizedBox(height: 20);
      },
    );
  }
}

// ── FALLBACK GRADIENT BACKGROUND ─────────────────────────────────────────────

class _FallbackBackground extends StatelessWidget {
  final bool isGroup;
  const _FallbackBackground({required this.isGroup});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isGroup
              // Group: deeper blue-teal gradient
              ? const [
                  Color(0xFF0D2233),
                  Color(0xFF091828),
                  Color(0xFF050F18),
                ]
              // Single: dark forest navy gradient
              : const [
                  Color(0xFF1A2535),
                  Color(0xFF0D1520),
                  Color(0xFF060C12),
                ],
        ),
      ),
    );
  }
}
