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
                  return OSHeader(
                    title: thread?.title ?? 'UNKNOWN',
                    subtitle: thread?.isTyping == true ? 'typing...' : 'online',
                    leading: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                      },
                      child: const Icon(Icons.arrow_back_ios, color: DreadmoorColors.textSecondary, size: 20),
                    ),
                    trailing: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: DreadmoorColors.surfaceGlass,
                        shape: BoxShape.circle,
                        border: Border.all(color: DreadmoorColors.borderGlass),
                      ),
                      child: const Icon(Icons.person, color: DreadmoorColors.textSecondary, size: 16),
                    ),
                  );
                },
              ),

              const InterceptBanner(isVisible: false),

              // Message list
              Expanded(
                child: StreamBuilder<List<Message>>(
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

                        final msg = messages[index];
                        // Add spacing between groups of messages
                        bool isFirstInGroup = true;
                        if (index > 0 && messages[index - 1].senderId == msg.senderId) {
                            isFirstInGroup = false;
                        }

                        return Padding(
                          padding: EdgeInsets.only(top: isFirstInGroup ? 12.0 : 4.0),
                          child: ChatBubble(
                            text: msg.content ?? "",
                            isMe: msg.isPlayerMessage,
                            senderId: msg.senderId,
                            timestamp: msg.timestamp,
                            isSecret: msg.isSecret,
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
