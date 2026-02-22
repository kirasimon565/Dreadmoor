import 'dart:convert';
import 'dart:ui';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // ✅ Streams created once in initState — never recreated on rebuild
  late final Stream<Thread?> _threadStream;
  late final Stream<List<Message>> _messagesStream;

  // Track last message count to only scroll on new messages
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

    // Mark this thread as active
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
      _scrollController.animateTo(
        maxExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(maxExtent);
    }
  }

  // Parse participants JSON safely — schema stores as JSON list
  List<String> _parseParticipants(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      // Fallback: try comma-separated for backward compat
      return raw.split(',').map((s) => s.trim()).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          // ── Background texture ────────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/chat_bg_texture.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.75),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF0A0A0A)),
            ),
          ),

          // ── Grain overlay ─────────────────────────────────────────────
          IgnorePointer(
            child: Opacity(
              opacity: 0.03,
              child: Image.asset(
                'assets/ui/glitch_overlay.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // ── Main column ───────────────────────────────────────────────
          Column(
            children: [
              // ── Header ─────────────────────────────────────────────
              StreamBuilder<Thread?>(
                stream: _threadStream,
                builder: (context, snapshot) {
                  final thread = snapshot.data;
                  final participants = _parseParticipants(thread?.participants);
                  final avatars = participants
                      .map((id) => 'assets/characters/$id.png')
                      .toList();

                  return ChatHeaderNeonGroup(
                    title: thread?.title ?? 'CHAT',
                    avatarPaths: avatars,
                    onBackPressed: () {
                      HapticFeedback.selectionClick();
                      context.pop();
                    },
                  );
                },
              ),

              // ── Intercept banner (conditional) ──────────────────────
              // TODO: Wire isVisible to actual intercept state flag
              const InterceptBanner(isVisible: false),

              // ── Message list ────────────────────────────────────────
              Expanded(
                child: StreamBuilder<List<Message>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? [];

                    // ✅ Scroll to bottom only when new messages arrive —
                    // not on every rebuild
                    if (messages.length != _lastMessageCount) {
                      _lastMessageCount = messages.length;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom(
                            animated: _lastMessageCount > 1);
                      });
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      // +1 for typing indicator / spacer at end
                      itemCount: messages.length + 1,
                      itemBuilder: (context, index) {
                        // Last item: typing indicator or bottom spacer
                        if (index == messages.length) {
                          return StreamBuilder<Thread?>(
                            stream: _threadStream,
                            builder: (context, snap) {
                              // ✅ isTyping is non-nullable (has withDefault)
                              final typing = snap.data?.isTyping ?? false;
                              if (typing) {
                                return const Padding(
                                  padding: EdgeInsets.only(
                                      left: 8, bottom: 16, top: 4),
                                  child: GunTypingIndicator(),
                                );
                              }
                              // Space so last bubble isn't behind choice overlay
                              return const SizedBox(height: 100);
                            },
                          );
                        }

                        final msg = messages[index];
                        final isMe = msg.isPlayerMessage;

                        return ChatBubble(
                          text: msg.content,
                          isMe: isMe,
                          senderId: msg.senderId,
                          timestamp: msg.timestamp,
                          isSecret: msg.isSecret,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // ── Choice overlay (floats above messages) ────────────────────
          const ChoiceOverlay(),
        ],
      ),
    );
  }
}
