import 'dart:async';
import 'dart:ui';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

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

  // ✅ Single TextEditingController so we can clear and autofocus properly
  final _searchController = TextEditingController();

  // ✅ StreamController lets us update the query filter without
  // recreating the entire DB stream on every keystroke
  final _queryController = StreamController<String>.broadcast();
  Stream<List<ThreadWithLastMessage>>? _threadStream;

  @override
  void initState() {
    super.initState();
    // Build the stream once — never recreated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final db = ref.read(databaseProvider);
        setState(() {
          _threadStream = _buildThreadStream(db);
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _queryController.close();
    super.dispose();
  }

  // ── Stream ────────────────────────────────────────────────────────────────

  Stream<List<ThreadWithLastMessage>> _buildThreadStream(AppDatabase db) {
    // Raw DB stream: all non-secret threads with their last message
    final rawStream = (db.select(db.threads)
          ..where((t) => t.isSecret.equals(false))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.lastMessageId, mode: OrderingMode.desc),
          ]))
        .join([
          leftOuterJoin(
            db.messages,
            db.messages.id.equalsExp(db.threads.lastMessageId),
          ),
        ])
        .watch()
        .map((rows) => rows
            .map((row) => ThreadWithLastMessage(
                  thread: row.readTable(db.threads),
                  lastMessage: row.readTableOrNull(db.messages),
                ))
            .toList());

    // ✅ Combine DB stream with query stream so filtering is reactive
    // but never recreates the DB subscription
    final queryStream =
        _queryController.stream.startWith('');

    return rawStream.switchMap((threads) {
      return queryStream.map((query) {
        if (query.isEmpty) return threads;
        final q = query.toLowerCase();
        return threads
            .where((e) =>
                e.thread.title.toLowerCase().contains(q) ||
                (e.lastMessage?.content ?? '').toLowerCase().contains(q))
            .toList();
      });
    });
  }

  void _toggleSearch() {
    HapticFeedback.selectionClick();
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        _queryController.add('');
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          // ── Background texture ──────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/messenger_bg_texture.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.75),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF0F0F0F)),
            ),
          ),

          // ── Grain overlay ───────────────────────────────────────────
          IgnorePointer(
            child: Opacity(
              opacity: 0.035,
              child: Image.asset(
                'assets/ui/glitch_overlay.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────
          // ✅ No SafeArea wrapper here — MessengerHeader handles its own
          // top padding via MediaQuery.padding.top internally
          Column(
            children: [
              MessengerHeader(
                isSearching: _searching,
                onSearchTap: _toggleSearch,
                onProfileTap: () => context.push(Routes.playerProfile),
              ),

              if (_searching)
                _SearchBar(
                  controller: _searchController,
                  onChanged: (q) => _queryController.add(q),
                ),

              Expanded(
                child: RefreshIndicator(
                  color: DreadmoorColors.accentCyan,
                  backgroundColor: DreadmoorColors.surface,
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    // Fake refresh delay — visual polish only
                    await Future.delayed(const Duration(milliseconds: 700));
                  },
                  child: _threadStream == null
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: DreadmoorColors.accentCyan),
                        )
                      : StreamBuilder<List<ThreadWithLastMessage>>(
                          stream: _threadStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Something went wrong.',
                                  style: GoogleFonts.inter(
                                      color: DreadmoorColors.textMeta),
                                ),
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
                                child: Text(
                                  _searching
                                      ? "NO RESULTS"
                                      : "NO MESSAGES",
                                  style: GoogleFonts.michroma(
                                    fontSize: 11,
                                    letterSpacing: 2.5,
                                    color: DreadmoorColors.textMeta,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                  top: 8, bottom: 32),
                              itemCount: threads.length,
                              itemBuilder: (context, index) {
                                return _ThreadTile(
                                    threadData: threads[index]);
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────

class ThreadWithLastMessage {
  final Thread thread;
  final Message? lastMessage;
  const ThreadWithLastMessage({required this.thread, this.lastMessage});
}

// ── Thread tile ───────────────────────────────────────────────────────────

class _ThreadTile extends StatefulWidget {
  final ThreadWithLastMessage threadData;
  const _ThreadTile({required this.threadData});

  @override
  State<_ThreadTile> createState() => _ThreadTileState();
}

class _ThreadTileState extends State<_ThreadTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final thread = widget.threadData.thread;
    final message = widget.threadData.lastMessage;

    // ✅ These are non-nullable in the schema (all have withDefault)
    final isUnread = thread.unreadCount > 0;
    final isTyping = thread.isTyping;
    final isLocked = thread.isLocked;

    return GestureDetector(
      onTapDown: isLocked
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: isLocked
          ? null
          : (_) {
              setState(() => _pressed = false);
              HapticFeedback.selectionClick();
              context.push(Routes.chat(thread.id));
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.75 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: DreadmoorColors.surface.withOpacity(
                      isUnread ? 0.52 : 0.32),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUnread
                        ? DreadmoorColors.accentCyan.withOpacity(0.22)
                        : Colors.white.withOpacity(0.055),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    _Avatar(isLocked: isLocked),
                    const SizedBox(width: 14),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title row
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  thread.title,
                                  style: GoogleFonts.michroma(
                                    fontSize: 13,
                                    letterSpacing: 1.2,
                                    color: isLocked
                                        ? Colors.white.withOpacity(0.3)
                                        : isUnread
                                            ? DreadmoorColors.textPrimary
                                            : DreadmoorColors.textPrimary
                                                .withOpacity(0.85),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (message != null && !isLocked)
                                Text(
                                  _formatTimestamp(message.timestamp),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    letterSpacing: 1.0,
                                    color: DreadmoorColors.textMeta,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 5),

                          // Preview row
                          if (isLocked)
                            Text(
                              "LOCKED",
                              style: GoogleFonts.michroma(
                                fontSize: 10,
                                letterSpacing: 2.0,
                                color:
                                    DreadmoorColors.accentRed.withOpacity(0.5),
                              ),
                            )
                          else if (isTyping)
                            const CompactGunTypingIndicator()
                          else if (message != null)
                            Text(
                              message.content,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isUnread
                                    ? DreadmoorColors.textSecondary
                                    : DreadmoorColors.textMeta,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          else
                            Text(
                              "No messages yet",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: DreadmoorColors.textMeta
                                    .withOpacity(0.6),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Unread dot
                    if (isUnread && !isLocked)
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: DreadmoorColors.accentCyan,
                          boxShadow: [
                            BoxShadow(
                              color: DreadmoorColors.glowCyan,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? ts) {
    if (ts == null) return '';
    final now = DateTime.now();
    if (ts.year == now.year &&
        ts.month == now.month &&
        ts.day == now.day) {
      return DateFormat('HH:mm').format(ts);
    }
    return DateFormat('d MMM').format(ts);
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final bool isLocked;
  const _Avatar({required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 50,
        height: 50,
        child: isLocked
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                      color: Colors.white.withOpacity(0.06)),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: const SizedBox.expand(),
                  ),
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 22,
                    color: DreadmoorColors.accentRed.withOpacity(0.55),
                  ),
                ],
              )
            : Image.asset(
                'assets/ui/neon_group_square.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: DreadmoorColors.surface,
                  child: const Icon(
                    Icons.person_rounded,
                    color: DreadmoorColors.textSecondary,
                    size: 24,
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DreadmoorColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 0.6,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        // ✅ Keyboard opens automatically when search bar appears
        autofocus: true,
        style: GoogleFonts.inter(
          color: DreadmoorColors.textPrimary,
          fontSize: 13,
        ),
        cursorColor: DreadmoorColors.accentCyan,
        decoration: InputDecoration(
          icon: Icon(
            Icons.search_rounded,
            color: Colors.white.withOpacity(0.35),
            size: 18,
          ),
          hintText: 'Search conversations...',
          hintStyle: GoogleFonts.inter(
            color: DreadmoorColors.textMeta,
            fontSize: 13,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
