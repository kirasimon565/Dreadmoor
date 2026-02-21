import 'dart:ui';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/state/game_state.dart';
import '../../theme/colors.dart';
import '../../widgets/gun_typing_indicator.dart';
import 'messenger_header.dart';

class MessengerListScreen extends ConsumerWidget {
  const MessengerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          // [0] Background
          Image.asset(
            'assets/backgrounds/messenger_bg_loop.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.72),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (c,e,s) => Container(color: const Color(0xFF0F0F0F)),
          ),
          // [1] Glitch Overlay
          Opacity(
            opacity: 0.035,
            child: Image.asset(
              'assets/ui/glitch_overlay.png',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c,e,s) => const SizedBox(),
            ),
          ),
          // [2] Content
          SafeArea(
            child: Column(
              children: [
                const MessengerHeader(),
                Expanded(
                  child: StreamBuilder<List<ThreadWithLastMessage>>(
                    stream: _watchThreads(db),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                         return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: DreadmoorColors.accentCyan));
                      }
                      final threads = snapshot.data!;
                      if (threads.isEmpty) {
                        return Center(child: Text("NO MESSAGES", style: GoogleFonts.michroma(color: DreadmoorColors.textMeta)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: threads.length,
                        itemBuilder: (context, index) {
                          return _ThreadTile(threadData: threads[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<ThreadWithLastMessage>> _watchThreads(AppDatabase db) {
    return (db.select(db.threads)
          ..orderBy([(t) => OrderingTerm(expression: t.lastMessageId, mode: OrderingMode.desc)]))
        .join([
          leftOuterJoin(db.messages, db.messages.id.equalsExp(db.threads.lastMessageId)),
        ])
        .watch()
        .map((rows) {
          return rows.map((row) {
            return ThreadWithLastMessage(
              thread: row.readTable(db.threads),
              lastMessage: row.readTableOrNull(db.messages),
            );
          }).toList();
        });
  }
}

class ThreadWithLastMessage {
  final Thread thread;
  final Message? lastMessage;
  ThreadWithLastMessage({required this.thread, this.lastMessage});
}


class _ThreadTile extends StatelessWidget {
  final ThreadWithLastMessage threadData;

  const _ThreadTile({required this.threadData});

  @override
  Widget build(BuildContext context) {
    final thread = threadData.thread;
    final message = threadData.lastMessage;
    final isUnread = (thread.unreadCount ?? 0) > 0;
    final isTyping = thread.isTyping ?? false;
    final isLocked = false; // logic for locked threads? Spec says locked threads exist. Maybe based on participants? assuming unlocked for now or add logic later.

    return GestureDetector(
      onTap: () {
        if (!isLocked) {
          context.push('/chat/${thread.id}');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isUnread ? 0.06 : 0.025),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUnread ? DreadmoorColors.accentCyan.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: isLocked
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                             Image.asset('assets/ui/locked_episode_overlay.png', fit: BoxFit.cover, errorBuilder: (c,e,s) => const SizedBox()),
                             BackdropFilter(filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: Container(color: Colors.transparent)),
                             Icon(Icons.lock_outline, size: 24, color: DreadmoorColors.accentRed.withOpacity(0.5)),
                          ],
                        )
                      : Image.asset('assets/ui/neon_group_square.png', fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(Icons.person, color: DreadmoorColors.textSecondary)),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  thread.title ?? 'Unknown',
                                  style: GoogleFonts.michroma(
                                    fontSize: 13,
                                    letterSpacing: 1.5,
                                    color: isLocked ? Colors.white.withOpacity(0.25) : DreadmoorColors.textPrimary,
                                  ),
                                ),
                                if (isLocked) Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Icon(Icons.lock_outline, size: 14, color: DreadmoorColors.accentRed.withOpacity(0.5)),
                                ),
                              ],
                            ),
                            if (message != null && !isLocked)
                              Text(
                                _formatTimestamp(message.timestamp),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  color: DreadmoorColors.textMeta,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        if (isTyping)
                          const CompactGunTypingIndicator()
                        else if (message != null)
                          Text(
                            message.content,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: DreadmoorColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            "No messages",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: DreadmoorColors.textMeta,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isUnread && !isLocked)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: DreadmoorColors.accentCyan,
                        boxShadow: [
                          BoxShadow(color: DreadmoorColors.glowCyan, blurRadius: 6),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    // Format: HH:MM usually
    return DateFormat('HH:mm').format(timestamp);
  }
}
