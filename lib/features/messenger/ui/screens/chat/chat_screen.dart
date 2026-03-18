import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/widgets/chat_bubble.dart';
import 'package:dreadmoor/ui/widgets/choice_overlay.dart';
import 'package:dreadmoor/ui/widgets/gun_typing_indicator.dart';
import 'package:dreadmoor/ui/screens/profiles/character_profile_screen.dart';
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
      leftOuterJoin(db.characters,
          db.characters.id.equalsExp(db.messages.senderId)),
    ]).watch();

    _membersStream = (db.select(db.threadMembers)
          ..where((m) => m.threadId.equals(widget.threadId)))
        .watch();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        ref.read(activeThreadIdProvider.notifier).state =
            widget.threadId;

        // Restore choice card if active
        final activeChoiceNodeIdRow = await (db.select(db.storyState)
              ..where((t) => t.key.equals('active_choice_id')))
            .getSingleOrNull();
        if (activeChoiceNodeIdRow != null && activeChoiceNodeIdRow.stringValue != null) {
          ref.read(activeNodeIdProvider.notifier).setId(activeChoiceNodeIdRow.stringValue!);
          ref.read(waitingForChoiceProvider.notifier).setWaiting(true);
        }
      }
    });
  }

  @override
  void dispose() {
    // Reset activeThreadId so the nav bar reappears after leaving chat.
    ref.read(activeThreadIdProvider.notifier).state = null;
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

  String? _resolveProfileId(List<ThreadMember> members) {
    return members
        .where((m) => m.characterId != 'player')
        .map((m) => m.characterId)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1520),
      body: StreamBuilder<List<ThreadMember>>(
        stream: _membersStream,
        builder: (context, membersSnap) {
          final members = membersSnap.data ?? [];
          final isGroup = members.length > 1;
          final profileId = _resolveProfileId(members);

          final avatarPaths = members
              .where((m) => m.characterId != 'player')
              .map((m) =>
                  'assets/characters/${m.characterId}.png')
              .toList();

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: Image.asset(
                    isGroup
                        ? 'assets/images/group_chat_bg.png'
                        : 'assets/images/forest_bg.png',
                    key: ValueKey(isGroup),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF0B1520)),
                  ),
                ),
              ),

              // Top gradient
              Positioned(
                top: 0, left: 0, right: 0, height: 180,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Layout
              Column(
                children: [
                  // Header
                  StreamBuilder<Thread?>(
                    stream: _threadStream,
                    builder: (context, snap) {
                      return ChatHeaderNeonGroup(
                        title: snap.data?.title ?? 'Unknown',
                        onBackPressed: () =>
                            Navigator.pop(context),
                        avatarPaths: avatarPaths,
                        isOnline: true,
                        onAvatarTap: profileId != null
                            ? () {
                                HapticFeedback.selectionClick();
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).push(MaterialPageRoute(
                                  builder: (_) =>
                                      CharacterProfileScreen(
                                    characterId: profileId,
                                  ),
                                ));
                              }
                            : null,
                      );
                    },
                  ),

                  // Messages
                  Expanded(
                    child: StreamBuilder<List<TypedResult>>(
                      stream: _messagesStream,
                      builder: (context, snapshot) {
                        final messages = snapshot.data ?? [];

                        if (messages.length !=
                            _lastMessageCount) {
                          _lastMessageCount = messages.length;
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) {
                            _scrollToBottom(
                                animated:
                                    _lastMessageCount > 1);
                          });
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          physics:
                              const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          itemCount: messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              return _buildTypingIndicator();
                            }
                            final db =
                                ref.read(databaseProvider);
                            final row = messages[index];
                            final msg =
                                row.readTable(db.messages);
                            final character = row
                                .readTableOrNull(db.characters);

                            return ChatBubble(
                              text: msg.content ?? '',
                              isMe: msg.isPlayerMessage,
                              senderId: msg.senderId,
                              senderName: character?.name,
                              timestamp: msg.timestamp,
                              isSecret: msg.isSecret,
                              mediaType: msg.type,
                              mediaPath: msg.mediaPath,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 90),
                ],
              ),

              // Choice overlay / input bar
              const ChoiceOverlay(),
            ],
          );
        },
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
