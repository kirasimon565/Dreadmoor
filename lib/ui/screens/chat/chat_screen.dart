import 'dart:ui';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/state/game_state.dart';
import '../../navigation/routes.dart';
import '../../theme/colors.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/choice_overlay.dart';
import '../../widgets/gun_typing_indicator.dart';
import 'chat_header_neon_group.dart';
import 'intercept_banner.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String threadId;

  const ChatScreen({super.key, required this.threadId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    final threadStream =
        (db.select(db.threads)..where((t) => t.id.equals(widget.threadId)))
            .watchSingleOrNull();

    final messagesStream = (db.select(db.messages)
          ..where((m) => m.threadId.equals(widget.threadId))
          ..orderBy([(m) => OrderingTerm(expression: m.timestamp)]))
        .watch();

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          // Background (static texture)
          Image.asset(
            'assets/backgrounds/chat_bg_texture.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.75),
            colorBlendMode: BlendMode.darken,
          ),

          // Glitch overlay
          IgnorePointer(
            child: Opacity(
              opacity: 0.03,
              child: Image.asset('assets/ui/glitch_overlay.png', fit: BoxFit.cover),
            ),
          ),

          Column(
            children: [
              StreamBuilder<Thread?>(
                stream: threadStream,
                builder: (context, snapshot) {
                  final thread = snapshot.data;
                  final avatars = (thread?.participants.split(',') ?? [])
                      .map((id) => 'assets/characters/$id.png')
                      .toList();

                  return ChatHeaderNeonGroup(
                    title: thread?.title ?? 'CHAT',
                    avatarPaths: avatars,
                    onBackPressed: () => context.pop(),
                  );
                },
              ),

              // Intercept banner (conditional hook)
              const InterceptBanner(),

              Expanded(
                child: StreamBuilder<List<Message>>(
                  stream: messagesStream,
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? [];

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(
                          _scrollController.position.maxScrollExtent,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return StreamBuilder<Thread?>(
                            stream: threadStream,
                            builder: (context, snap) {
                              if (snap.data?.isTyping ?? false) {
                                return const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 10),
                                  child: GunTypingIndicator(),
                                );
                              }
                              return const SizedBox(height: 90);
                            },
                          );
                        }

                        final msg = messages[index];

                        return ChatBubble(
                          text: msg.content,
                          isMe: msg.senderId == 'player',
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
