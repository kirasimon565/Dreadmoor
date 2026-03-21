import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/os/os_state.dart';
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

  late final Stream<Thread?>           _threadStream;
  late final Stream<List<TypedResult>> _messagesStream;
  late final Stream<List<TypedResult>> _membersWithNamesStream;
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

    _membersWithNamesStream = (db.select(db.threadMembers)
          ..where((m) => m.threadId.equals(widget.threadId)))
        .join([
          innerJoin(db.characters,
              db.characters.id.equalsExp(db.threadMembers.characterId)),
        ]).watch();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(activeThreadIdProvider.notifier).setId(widget.threadId);

      final activeChoiceRow = await (db.select(db.storyState)
            ..where((t) => t.key.equals('active_choice_id')))
          .getSingleOrNull();
      if (activeChoiceRow?.stringValue != null) {
        ref.read(activeNodeIdProvider.notifier)
            .setId(activeChoiceRow!.stringValue!);
        ref.read(waitingForChoiceProvider.notifier).setWaiting(true);
      }
    });
  }

  @override
  void dispose() {
    ref.read(activeThreadIdProvider.notifier).setId(null);
    ref.read(activeAppProvider.notifier).setApp(PhoneApp.messenger);
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

  Map<String, VoidCallback> _buildMemberTapMap(List<ThreadMember> members) {
    return {
      for (final m in members.where((m) => m.characterId != 'player'))
        m.characterId: () {
          HapticFeedback.selectionClick();
          // BUG 2 FIX: removed rootNavigator: true so CharacterProfileScreen
          // renders inside DreadmoorOS and receives the global status bar.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CharacterProfileScreen(characterId: m.characterId),
            ),
          );
        },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1520),
      body: StreamBuilder<List<ThreadMember>>(
        stream: _membersStream,
        builder: (context, membersSnap) {
          final members   = membersSnap.data ?? [];
          final isGroup   = members.length > 1;
          final nonPlayer = members
              .where((m) => m.characterId != 'player')
              .toList();

          final avatarPaths = nonPlayer
              .map((m) => 'assets/characters/${m.characterId}.png')
              .toList();
          final memberIds = nonPlayer.map((m) => m.characterId).toList();
          final memberTapMap = _buildMemberTapMap(members);
          final singleProfileId =
              nonPlayer.isNotEmpty ? nonPlayer.first.characterId : null;

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
                      end:   Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main layout
              Column(
                children: [
                  StreamBuilder<Thread?>(
                    stream: _threadStream,
                    builder: (context, snap) {
                      return ChatHeaderNeonGroup(
                        title:        snap.data?.title ?? 'Unknown',
                        onBackPressed: () => Navigator.pop(context),
                        avatarPaths:  avatarPaths,
                        memberIds:    memberIds,
                        isOnline:     true,
                        onAvatarTap: isGroup
                            ? null
                            : singleProfileId != null
                                ? () {
                                    HapticFeedback.selectionClick();
                                    // BUG 2 FIX: removed rootNavigator: true
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CharacterProfileScreen(
                                          characterId: singleProfileId,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                        onMemberTap: isGroup ? memberTapMap : null,
                      );
                    },
                  ),

                  Expanded(
                    child: StreamBuilder<List<TypedResult>>(
                      stream: _messagesStream,
                      builder: (context, snapshot) {
                        final messages = snapshot.data ?? [];

                        if (messages.length != _lastMessageCount) {
                          _lastMessageCount = messages.length;
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) => _scrollToBottom(
                                  animated: _lastMessageCount > 1));
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          itemCount: messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              return _buildTypingIndicator();
                            }
                            final db  = ref.read(databaseProvider);
                            final row = messages[index];
                            final msg = row.readTable(db.messages);
                            final character =
                                row.readTableOrNull(db.characters);

                            return ChatBubble(
                              text:       msg.content ?? '',
                              isMe:       msg.isPlayerMessage,
                              senderId:   msg.senderId,
                              senderName: character?.name,
                              timestamp:  msg.timestamp,
                              isSecret:   msg.isSecret,
                              mediaType:  msg.type,
                              mediaPath:  msg.mediaPath,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 90),
                ],
              ),

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
      builder: (context, threadSnap) {
        if (threadSnap.data?.isTyping != true) {
          return const SizedBox(height: 20);
        }
        return StreamBuilder<List<TypedResult>>(
          stream: _membersWithNamesStream,
          builder: (context, membersSnap) {
            final db = ref.read(databaseProvider);
            String? senderName;
            if (membersSnap.hasData) {
              for (final row in membersSnap.data!) {
                final char = row.readTableOrNull(db.characters);
                if (char != null && char.id != 'player') {
                  senderName = char.name;
                  break;
                }
              }
            }
            return FeatherTypingIndicator(
              senderName: senderName,
              isSecret:   false,
            );
          },
        );
      },
    );
  }
}
