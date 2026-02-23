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

  final _searchController = TextEditingController();
  final _queryController = StreamController<String>.broadcast();
  Stream<List<ThreadWithLastMessage>>? _threadStream;

  @override
  void initState() {
    super.initState();
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

  Stream<List<ThreadWithLastMessage>> _buildThreadStream(AppDatabase db) {
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

    final queryStream = _queryController.stream.startWith('');

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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      // ✅ extendBody so the list scrolls behind the translucent bottom nav
      extendBody: true,
      bottomNavigationBar: _BottomNav(
        onSearch: _toggleSearch,
        isSearching: _searching,
      ),
      body: Stack(
        children: [
          // ── Background texture ────────────────────────────────────────
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

          // ── Grain overlay ─────────────────────────────────────────────
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

          // ── Content ───────────────────────────────────────────────────
          Column(
            children: [
              // Header: logo only — nav moved to bottom bar
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
                                  _searching ? "NO RESULTS" : "NO MESSAGES",
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
                              // ✅ Extra bottom padding so last tile isn't
                              // hidden behind the bottom nav bar
                              padding: EdgeInsets.only(
                                top: 8,
                                bottom: 90 + bottomPadding,
                              ),
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

// ── Bottom navigation bar ─────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final VoidCallback onSearch;
  final bool isSearching;

  const _BottomNav({
    required this.onSearch,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: 10,
            bottom: 10 + bottomPadding,
            left: 8,
            right: 8,
          ),
          decoration: BoxDecoration(
            color: DreadmoorColors.surface.withOpacity(0.72),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.07),
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Profile
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: "PROFILE",
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push(Routes.playerProfile);
                },
              ),

              // Search
              _NavItem(
                icon: isSearching
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
                label: "SEARCH",
                isActive: isSearching,
                onTap: onSearch,
              ),

              // Detective Board — center, highlighted
              _NavItem(
                icon: Icons.push_pin_outlined,
                label: "BOARD",
                isCenter: true,
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push(Routes.board);
                },
              ),

              // Map
              _NavItem(
                icon: Icons.map_outlined,
                label: "MAP",
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push(Routes.map);
                },
              ),

              // Settings
              _NavItem(
                icon: Icons.settings_outlined,
                label: "SETTINGS",
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push(Routes.settings);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final bool isCenter;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isCenter = false,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isCenter
        ? DreadmoorColors.accentCyan
        : DreadmoorColors.accentCyan;
    final inactiveColor = Colors.white.withOpacity(0.35);
    final color =
        (widget.isActive || widget.isCenter) ? activeColor : inactiveColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.isCenter
            // ── Center item: raised glowing pill ───────────────────
            ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: DreadmoorColors.accentCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: DreadmoorColors.accentCyan.withOpacity(0.35),
                    width: 0.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DreadmoorColors.glowCyan.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: activeColor, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      widget.label,
                      style: GoogleFonts.michroma(
                        fontSize: 8,
                        color: activeColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              )
            // ── Regular nav items ───────────────────────────────────
            : SizedBox(
                width: 56,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: widget.isActive ? 36 : 0,
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: DreadmoorColors.accentCyan,
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: [
                          BoxShadow(
                            color: DreadmoorColors.glowCyan.withOpacity(0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Icon(widget.icon, color: color, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      widget.label,
                      style: GoogleFonts.michroma(
                        fontSize: 8,
                        color: color,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
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
    final isUnread = thread.unreadCount > 0;
    final isTyping = thread.isTyping;
    final isLocked = thread.isLocked;

    return GestureDetector(
      onTapDown:
          isLocked ? null : (_) => setState(() => _pressed = true),
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
          padding:
              const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: DreadmoorColors.surface
                      .withOpacity(isUnread ? 0.52 : 0.32),
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
                    _Avatar(isLocked: isLocked),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                        : DreadmoorColors.textPrimary
                                            .withOpacity(
                                                isUnread ? 1.0 : 0.85),
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
                          if (isLocked)
                            Text(
                              "LOCKED",
                              style: GoogleFonts.michroma(
                                fontSize: 10,
                                letterSpacing: 2.0,
                                color: DreadmoorColors.accentRed
                                    .withOpacity(0.5),
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
                  ColoredBox(color: Colors.white.withOpacity(0.06)),
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
