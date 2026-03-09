import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/widgets/chat_bubble.dart';
import 'package:dreadmoor/ui/widgets/choice_overlay.dart';
import 'package:dreadmoor/ui/widgets/gun_typing_indicator.dart';
import 'package:dreadmoor/ui/os/components/os_header.dart';
import 'intercept_banner.dart';

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
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    final db = ref.read(databaseProvider);

    _threadStream = (db.select(db.threads)..where((t) => t.id.equals(widget.threadId))).watchSingleOrNull();

    _messagesStream = (db.select(db.messages)
          ..where((m) => m.threadId.equals(widget.threadId))
          ..orderBy([(m) => OrderingTerm(expression: m.timestamp)]))
        .join([
          leftOuterJoin(db.characters, db.characters.id.equalsExp(db.messages.senderId)),
        ]).watch();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(activeThreadIdProvider.notifier).state = widget.threadId;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(maxExtent, duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    } else {
      _scrollController.jumpTo(maxExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          // Background Gradient for depth
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    DreadmoorColors.surfaceAlt.withOpacity(0.4),
                    DreadmoorColors.background,
                  ],
                ),
              ),
            ),
          ),

          // Grain overlay
          IgnorePointer(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/ui/glitch_overlay.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // Main column
          Column(
            children: [
              // Unified Header
              StreamBuilder<Thread?>(
                stream: _threadStream,
                builder: (context, snapshot) {
                  final thread = snapshot.data;
                  return StreamBuilder<Character?>(
                    stream: (ref.read(databaseProvider).select(ref.read(databaseProvider).characters)
                      ..where((c) => c.id.equals(thread?.id ?? '')))
                    .watchSingleOrNull(),
                    builder: (context, charSnapshot) {
                      final character = charSnapshot.data;

                      return OSHeader(
                        title: thread?.title ?? 'UNKNOWN',
                        subtitle: thread?.isTyping == true ? 'typing...' : 'online',
                        onTitleTap: () {
                          Navigator.of(context).pushNamed('/profile/character', arguments: thread?.id);
                        },
                        leading: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pop();
                          },
                          child: const Icon(Icons.arrow_back_ios, color: DreadmoorColors.textSecondary, size: 20),
                        ),
                        trailing: GestureDetector(
                          onTap: () {
                             // Opens Character Profile
                             Navigator.of(context).pushNamed('/profile/character', arguments: thread?.id);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: DreadmoorColors.surfaceGlass,
                              shape: BoxShape.circle,
                              border: Border.all(color: DreadmoorColors.borderGlass),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: character?.avatarPath != null
                                ? Image.asset(character!.avatarPath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: DreadmoorColors.textSecondary, size: 16))
                                : const Icon(Icons.person, color: DreadmoorColors.textSecondary, size: 16),
                          ),
                        ),
                      );
                    }
                  );
                },
              ),

              const InterceptBanner(isVisible: false),

              // Message list
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), // Increased vertical padding
                      itemCount: messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return StreamBuilder<Thread?>(
                            stream: _threadStream,
                            builder: (context, snap) {
                              final typing = snap.data?.isTyping ?? false;
                              if (typing) {
                                return const Padding(
                                  padding: EdgeInsets.only(left: 8, bottom: 16, top: 4),
                                  child: GunTypingIndicator(),
                                );
                              }
                              return const SizedBox(height: 100);
                            },
                          );
                        }

                        final row = messages[index];
                        final msg = row.readTable(ref.read(databaseProvider).messages);
                        final character = row.readTableOrNull(ref.read(databaseProvider).characters);

                        // Grouping logic
                        bool isFirstInGroup = true;
                        if (index > 0) {
                          final prevMsg = messages[index - 1].readTable(ref.read(databaseProvider).messages);
                          if (prevMsg.senderId == msg.senderId) {
                              isFirstInGroup = false;
                          }
                        }

                        // Group timestamps by minute
                        bool isLastInMinuteGroup = true;
                        if (index < messages.length - 1) {
                          final nextMsg = messages[index + 1].readTable(ref.read(databaseProvider).messages);
                          if (nextMsg.senderId == msg.senderId && msg.timestamp != null && nextMsg.timestamp != null) {
                             if (msg.timestamp!.hour == nextMsg.timestamp!.hour && msg.timestamp!.minute == nextMsg.timestamp!.minute) {
                               isLastInMinuteGroup = false;
                             }
                          }
                        }

                        return Padding(
                          padding: EdgeInsets.only(top: isFirstInGroup ? 12.0 : 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: msg.isPlayerMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              if (!msg.isPlayerMessage && isLastInMinuteGroup)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: DreadmoorColors.borderSubtle),
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                    child: character?.avatarPath != null
                                        ? Image.asset(character!.avatarPath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 12, color: DreadmoorColors.textSecondary))
                                        : const Icon(Icons.person, size: 12, color: DreadmoorColors.textSecondary),
                                  ),
                                )
                              else if (!msg.isPlayerMessage)
                                const SizedBox(width: 32),

                              Flexible(
                                child: ChatBubble(
                                  text: msg.content ?? "",
                                  isMe: msg.isPlayerMessage,
                                  senderId: msg.senderId,
                                  // Only pass timestamp if it's the last message in that minute group
                                  timestamp: isLastInMinuteGroup ? msg.timestamp : null,
                                  isSecret: msg.isSecret,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          const ChoiceOverlay(),
        ],
      ),
    );
  }
}
