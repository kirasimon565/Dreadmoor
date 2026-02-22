import 'dart:ui';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/state/game_state.dart';
import '../../navigation/routes.dart';
import '../../theme/colors.dart';
import '../../widgets/gun_typing_indicator.dart';
import 'messenger_header.dart';

class MessengerListScreen extends ConsumerStatefulWidget {
  const MessengerListScreen({super.key});

  @override
  ConsumerState<MessengerListScreen> createState() =>
      _MessengerListScreenState();
}

class _MessengerListScreenState extends ConsumerState<MessengerListScreen> {
  bool _searching = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          // [0] Static background texture (no video)
          Image.asset(
            'assets/backgrounds/messenger_bg_texture.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.75),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFF0F0F0F)),
          ),

          // [1] Glitch overlay
          IgnorePointer(
            child: Opacity(
              opacity: 0.035,
              child: Image.asset(
                'assets/ui/glitch_overlay.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // [2] Content
          SafeArea(
            child: Column(
              children: [
                MessengerHeader(
                  isSearching: _searching,
                  onSearchTap: () => setState(() {
                    _searching = !_searching;
                    _query = '';
                  }),
                  onProfileTap: () => context.push(Routes.playerProfile),
                ),

                if (_searching) _SearchBar(onChanged: (q) => setState(() => _query = q)),

                Expanded(
                  child: RefreshIndicator(
                    color: DreadmoorColors.accentCyan,
                    backgroundColor: DreadmoorColors.surface,
                    onRefresh: () async {
                      await Future.delayed(const Duration(milliseconds: 600));
                    },
                    child: StreamBuilder<List<ThreadWithLastMessage>>(
                      stream: _watchThreads(db, ref, _query),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red)),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: DreadmoorColors.accentCyan),
                          );
                        }
                        final threads = snapshot.data!;
                        if (threads.isEmpty) {
                          return Center(
                            child: Text("NO MESSAGES",
                                style: GoogleFonts.michroma(
                                    color: DreadmoorColors.textMeta)),
                          );
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<ThreadWithLastMessage>> _watchThreads(
      AppDatabase db, WidgetRef ref, String query) {
    return (db.select(db.threads)
          ..where((t) => t.isSecret.equals(false)) // Secret chats hidden
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.lastMessageId, mode: OrderingMode.desc)
          ]))
        .join([
          leftOuterJoin(db.messages,
              db.messages.id.equalsExp(db.threads.lastMessageId)),
        ])
        .watch()
        .map((rows) {
          var list = rows.map((row) {
            return ThreadWithLastMessage(
              thread: row.readTable(db.threads),
              lastMessage: row.readTableOrNull(db.messages),
            );
          }).toList();

          if (query.isNotEmpty) {
            list = list
                .where((e) =>
                    (e.thread.title ?? '')
                        .toLowerCase()
                        .contains(query.toLowerCase()) ||
                    (e.lastMessage?.content ?? '')
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                .toList();
          }

          return list;
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
    final isLocked = thread.isLocked ?? false;

    return GestureDetector(
      onTap: isLocked ? null : () => context.push(Routes.chat(thread.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DreadmoorColors.surface.withOpacity(isUnread ? 0.5 : 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUnread
                      ? DreadmoorColors.accentCyan.withOpacity(0.2)
                      : Colors.white.withOpacity(0.06),
                  width: 0.6,
                ),
              ),
              child: Row(
                children: [
                  _Avatar(isLocked: isLocked),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              thread.title ?? 'Unknown',
                              style: GoogleFonts.michroma(
                                fontSize: 13,
                                letterSpacing: 1.5,
                                color: isLocked
                                    ? Colors.white.withOpacity(0.35)
                                    : DreadmoorColors.textPrimary,
                              ),
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
                          BoxShadow(
                              color: DreadmoorColors.glowCyan, blurRadius: 6),
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
    return DateFormat('HH:mm').format(timestamp);
  }
}

class _Avatar extends StatelessWidget {
  final bool isLocked;
  const _Avatar({required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Image.asset(
                  'assets/ui/locked_episode_overlay.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: const SizedBox.expand(),
                ),
                Icon(Icons.lock_outline,
                    size: 24,
                    color: DreadmoorColors.accentRed.withOpacity(0.6)),
              ],
            )
          : Image.asset(
              'assets/ui/neon_group_square.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.person, color: DreadmoorColors.textSecondary),
            ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DreadmoorColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.6),
      ),
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.inter(color: DreadmoorColors.textPrimary),
        decoration: InputDecoration(
          icon: const Icon(Icons.search_rounded, color: Colors.white54),
          hintText: 'Search messages...',
          hintStyle:
              GoogleFonts.inter(color: DreadmoorColors.textMeta),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
