import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/ui/screens/profiles/character_profile_screen.dart';

import 'package:dreadmoor/ui/widgets/chat_bubble.dart';
import 'package:dreadmoor/ui/widgets/gun_typing_indicator.dart';
import 'package:dreadmoor/ui/widgets/choice_overlay.dart';

import 'chat_header_neon_group.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String threadId;

  const ChatScreen({super.key, required this.threadId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  late Stream<Thread?> _threadStream;
  late Stream<List<TypedResult>> _messagesStream;
  late Stream<List<ThreadMember>> _membersStream;
  late Stream<List<TypedResult>> _membersWithNamesStream;

  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    final db = ref.read(databaseProvider);

    _threadStream = (db.select(
      db.threads,
    )..where((t) => t.id.equals(widget.threadId))).watchSingleOrNull();

    _messagesStream =
        (db.select(db.messages)
              ..where((m) => m.threadId.equals(widget.threadId))
              ..orderBy([(m) => OrderingTerm(expression: m.timestamp)]))
            .join([
              leftOuterJoin(
                db.characters,
                db.characters.id.equalsExp(db.messages.senderId),
              ),
            ])
            .watch();

    _membersStream = (db.select(
      db.threadMembers,
    )..where((m) => m.threadId.equals(widget.threadId))).watch();

    _membersWithNamesStream =
        (db.select(
          db.threadMembers,
        )..where((m) => m.threadId.equals(widget.threadId))).join([
          innerJoin(
            db.characters,
            db.characters.id.equalsExp(db.threadMembers.characterId),
          ),
        ]).watch();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      ref.read(activeThreadIdProvider.notifier).setId(widget.threadId);
      ref.read(globalSchedulerProvider).resumeIfThreadActive(widget.threadId);

      final activeChoiceRow = await (db.select(
        db.storyState,
      )..where((t) => t.key.equals('active_choice_id'))).getSingleOrNull();

      if (activeChoiceRow?.stringValue != null) {
        ref
            .read(activeNodeIdProvider.notifier)
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
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(max);
    }
  }

  Map<String, VoidCallback> _buildMemberTapMap(List<ThreadMember> members) {
    return {
      for (final m in members.where((m) => m.characterId != 'player'))
        m.characterId: () {
          HapticFeedback.selectionClick();
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
    // Listen to choice overlay expansion state to auto-scroll
    ref.listen(isChoiceOverlayExpandedProvider, (prev, next) {
      if (next == true) {
        // Scroll continuously during expansion
        _scrollToBottom(animated: true);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _scrollToBottom(animated: true);
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0B1520),
      body: StreamBuilder<List<ThreadMember>>(
        stream: _membersStream,
        builder: (context, membersSnap) {
          final members = membersSnap.data ?? [];
          final isGroup = members.length > 1;

          final nonPlayer = members
              .where((m) => m.characterId != 'player')
              .toList();

          final avatarPaths = nonPlayer
              .map((m) => 'assets/characters/${m.characterId}.png')
              .toList();

          final memberIds = nonPlayer.map((m) => m.characterId).toList();

          final memberTapMap = _buildMemberTapMap(members);

          final singleProfileId = nonPlayer.isNotEmpty
              ? nonPlayer.first.characterId
              : null;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background Fullscreen
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: Image.asset(
                    'assets/media/images/forest_moon_bg.png', // Dynamic loading if added to thread table in future, fallback for now
                    key: const ValueKey('forest_moon_bg'),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/media/images/default_chat_bg.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFF0B1520)),
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
                        title: snap.data?.title ?? 'Unknown',
                        onBackPressed: () {
                          ref.read(activeThreadIdProvider.notifier).setId(null);
                          ref
                              .read(activeAppProvider.notifier)
                              .setApp(PhoneApp.messenger);
                          Navigator.pop(context);
                        },
                        avatarPaths: avatarPaths,
                        memberIds: memberIds,
                        isOnline: true,
                        onAvatarTap: isGroup
                            ? null
                            : singleProfileId != null
                            ? () {
                                HapticFeedback.selectionClick();
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
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _scrollToBottom(
                              animated: _lastMessageCount > 1,
                            ),
                          );
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

                            final db = ref.read(databaseProvider);
                            final row = messages[index];
                            final msg = row.readTable(db.messages);
                            final character = row.readTableOrNull(
                              db.characters,
                            );

                            return ChatBubble(
                              text: msg.content ?? '',
                              isMe: msg.isPlayerMessage,
                              senderId: msg.senderId,
                              senderName: character?.name,
                              timestamp: msg.timestamp,
                              isSecret: msg.isSecret,
                              mediaType: msg.type,
                              mediaPath: msg.mediaPath,
                              isGroup:
                                  isGroup, // pass isGroup to handle names above bubbles properly
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const ChoiceOverlay(),
                ],
              ),
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

        final typingUserId = threadSnap.data?.typingUserId;

        return StreamBuilder<List<TypedResult>>(
          stream: _membersWithNamesStream,
          builder: (context, membersSnap) {
            final db = ref.read(databaseProvider);

            String? senderName;

            if (membersSnap.hasData && typingUserId != null) {
              for (final row in membersSnap.data!) {
                final char = row.readTableOrNull(db.characters);
                if (char != null && char.id == typingUserId) {
                  senderName = char.name;
                  break;
                }
              }
            }

            return FeatherTypingIndicator(
              senderName: senderName ?? 'Someone',
              isSecret: false,
            );
          },
        );
      },
    );
  }
}
