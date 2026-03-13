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
import 'chat_header_neon_group.dart'; // Updated to the "Unknown Pill" header

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

    // Notify the scheduler which thread is active for real-time injections
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
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // MAIN CONVERSATION LAYER
          SafeArea(
            child: Column(
              children: [
                // 1. DYNAMIC HEADER (The Grey Pill Redesign)
                StreamBuilder<Thread?>(
                  stream: _threadStream,
                  builder: (context, snapshot) {
                    final thread = snapshot.data;
                    return ChatHeaderNeonGroup(
                      title: thread?.title ?? 'UNKNOWN',
                      onBackPressed: () => Navigator.pop(context),
                      // Pass character avatar if exists
                      avatarPaths: thread != null ? [thread.id] : [], 
                    );
                  },
                ),

                // 2. SCROLLABLE MESSAGE LIST
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        itemCount: messages.length + 1,
                        itemBuilder: (context, index) {
                          // Typing Indicator Placeholder
                          if (index == messages.length) {
                            return _buildTypingIndicator();
                          }

                          final row = messages[index];
                          final msg = row.readTable(ref.read(databaseProvider).messages);
                          final character = row.readTableOrNull(ref.read(databaseProvider).characters);

                          return ChatBubble(
                            text: msg.content ?? "",
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
                
                // 3. BOTTOM SPACING (To clear the Choice Overlay)
                const SizedBox(height: 100),
              ],
            ),
          ),

          // 4. THE INTERACTIVE DOCK (The Quill & Choices)
          // This sits on top and expands based on waitingForChoiceProvider
          const ChoiceOverlay(),
        ],
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
