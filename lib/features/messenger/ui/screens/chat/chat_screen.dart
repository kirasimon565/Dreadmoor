import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/ui/widgets/chat_bubble.dart';
import 'package:dreadmoor/ui/widgets/choice_overlay.dart';
import 'package:dreadmoor/ui/widgets/gun_typing_indicator.dart';
import 'package:dreadmoor/ui/screens/profiles/character_profile_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String threadId;
  const ChatScreen({super.key, required this.threadId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  late final Stream<Thread?>            _threadStream;
  late final Stream<List<TypedResult>>  _messagesStream;
  late final Stream<List<TypedResult>>  _membersWithNamesStream;
  late final Stream<List<ThreadMember>> _membersStream;

  int _lastMessageCount = 0;

  // ── LIFECYCLE ─────────────────────────────────────────────────────────────

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
        .join([
          leftOuterJoin(db.characters,
              db.characters.id.equalsExp(db.messages.senderId)),
        ]).watch();

    _membersStream = (db.select(db.threadMembers)
          ..where((m) => m.threadId.equals(widget.threadId)))
        .watch();

    _membersWithNamesStream = (db.select(db.threadMembers)
          ..where((m) => m.threadId.equals(widget.threadId)))
        .join([
          innerJoin(db.characters,
              db.characters.id.equalsExp(db.threadMembers.characterId)),
        ]).watch();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(activeThreadIdProvider.notifier).setId(widget.threadId);
      ref.read(globalSchedulerProvider).resumeIfThreadActive(widget.threadId);

      final db = ref.read(databaseProvider);
      final activeChoiceRow = await (db.select(db.storyState)
            ..where((t) => t.key.equals('active_choice_id')))
          .getSingleOrNull();
      if (activeChoiceRow?.stringValue != null) {
        ref.read(activeNodeIdProvider.notifier)
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
      _scrollController.animateTo(max,
          duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    } else {
      _scrollController.jumpTo(max);
    }
  }

  Map<String, VoidCallback> _buildMemberTapMap(List<ThreadMember> members) {
    return {
      for (final m in members.where((m) => m.characterId != 'player'))
        m.characterId: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                CharacterProfileScreen(characterId: m.characterId),
          ));
        },
    };
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Panel starts at 42% from the top — image dominates upper portion.
    final panelTop = size.height * 0.42;

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<List<ThreadMember>>(
        stream: _membersStream,
        builder: (context, membersSnap) {
          final members   = membersSnap.data ?? [];
          final isGroup   = members.length > 1;
          final nonPlayer = members
              .where((m) => m.characterId != 'player')
              .toList();
          final avatarPaths =
              nonPlayer.map((m) => 'assets/characters/${m.characterId}.png')
                  .toList();
          final memberIds =
              nonPlayer.map((m) => m.characterId).toList();
          final memberTapMap = _buildMemberTapMap(members);
          final singleProfileId =
              nonPlayer.isNotEmpty ? nonPlayer.first.characterId : null;

          return Stack(
            children: [

              // ── LAYER 0: FULL-SCREEN BACKGROUND ───────────────────────
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: Image.asset(
                    isGroup
                        ? 'assets/images/group_chat_bg.png'
                        : 'assets/images/forest_bg.png',
                    key:   ValueKey(isGroup),
                    fit:   BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF0A1520)),
                  ),
                ),
              ),

              // ── LAYER 1: TOP GRADIENT (header legibility) ─────────────
              Positioned(
                top: 0, left: 0, right: 0,
                height: 160,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end:   Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── LAYER 2: WHITE PANEL ───────────────────────────────────
              Positioned(
                top:    panelTop,
                left:   0,
                right:  0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(44),
                    ),
                  ),
                  child: Column(
                    children: [

                      // Messages
                      Expanded(
                        child: StreamBuilder<List<TypedResult>>(
                          stream: _messagesStream,
                          builder: (context, snapshot) {
                            final messages = snapshot.data ?? [];

                            if (messages.length != _lastMessageCount) {
                              _lastMessageCount = messages.length;
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _scrollToBottom(
                                    animated: _lastMessageCount > 1),
                              );
                            }

                            return ListView.builder(
                              controller: _scrollController,
                              physics:    const BouncingScrollPhysics(),
                              padding:    const EdgeInsets.only(
                                left:   0,
                                right:  0,
                                top:    20,
                                bottom: 16,
                              ),
                              itemCount:   messages.length + 1,
                              itemBuilder: (context, index) {
                                if (index == messages.length) {
                                  return _buildTypingIndicator();
                                }
                                final db        = ref.read(databaseProvider);
                                final row       = messages[index];
                                final msg       = row.readTable(db.messages);
                                final character =
                                    row.readTableOrNull(db.characters);

                                return ChatBubble(
                                  text:       msg.content ?? '',
                                  isMe:       msg.isPlayerMessage,
                                  senderId:   msg.senderId,
                                  senderName: character?.name,
                                  timestamp:  msg.timestamp,
                                  isSecret:   msg.isSecret,
                                  mediaType:  msg.type,
                                  mediaPath:  msg.mediaPath,
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // Decorative input bar (narrative game — choices come
                      // from ChoiceOverlay, not from typing)
                      _InputBar(),
                    ],
                  ),
                ),
              ),

              // ── LAYER 3: FLOATING HEADER ───────────────────────────────
              SafeArea(
                bottom: false,
                child: StreamBuilder<Thread?>(
                  stream: _threadStream,
                  builder: (context, snap) {
                    final title = snap.data?.title ?? 'Unknown';
                    return _ChatHeader(
                      title:     title,
                      isGroup:   isGroup,
                      avatarPaths: avatarPaths,
                      memberIds: memberIds,
                      onBack: () {
                        ref.read(activeThreadIdProvider.notifier).setId(null);
                        ref.read(activeAppProvider.notifier)
                            .setApp(PhoneApp.messenger);
                        Navigator.pop(context);
                      },
                      onAvatarTap: isGroup
                          ? null
                          : singleProfileId != null
                              ? () {
                                  HapticFeedback.selectionClick();
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => CharacterProfileScreen(
                                      characterId: singleProfileId,
                                    ),
                                  ));
                                }
                              : null,
                      memberTapMap: isGroup ? memberTapMap : null,
                    );
                  },
                ),
              ),

              // ── LAYER 4: CHOICE OVERLAY ────────────────────────────────
              const ChoiceOverlay(),
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
          return const SizedBox(height: 12);
        }
        return StreamBuilder<List<TypedResult>>(
          stream: _membersWithNamesStream,
          builder: (context, membersSnap) {
            final db = ref.read(databaseProvider);
            String? senderName;
            if (membersSnap.hasData) {
              for (final row in membersSnap.data!) {
                final char = row.readTableOrNull(db.characters);
                if (char != null && char.id != 'player') {
                  senderName = char.name;
                  break;
                }
              }
            }
            return FeatherTypingIndicator(
              senderName: senderName,
              isSecret:   false,
            );
          },
        );
      },
    );
  }
}

// ── FLOATING HEADER ───────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final String                   title;
  final bool                     isGroup;
  final List<String>             avatarPaths;
  final List<String>             memberIds;
  final VoidCallback             onBack;
  final VoidCallback?            onAvatarTap;
  final Map<String, VoidCallback>? memberTapMap;

  const _ChatHeader({
    required this.title,
    required this.isGroup,
    required this.avatarPaths,
    required this.memberIds,
    required this.onBack,
    this.onAvatarTap,
    this.memberTapMap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [

          // Back button — left
          Positioned(
            left: 0,
            child: GestureDetector(
              onTap:     onBack,
              behavior:  HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size:  32,
                ),
              ),
            ),
          ),

          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.spectral(
                  color:      Colors.white,
                  fontSize:   20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              if (!isGroup)
                Text(
                  'Online',
                  style: GoogleFonts.spaceGrotesk(
                    color:      Colors.white.withOpacity(0.85),
                    fontSize:   13,
                    fontWeight: FontWeight.w400,
                  ),
                )
              else
                // Overlapping avatars for group
                _OverlappingAvatars(paths: avatarPaths),
            ],
          ),

          // Single-user profile shortcut — right
          // Icon only (NOT an avatar image) per design spec.
          // Tapping opens the character profile screen.
          if (!isGroup)
            Positioned(
              right: 4,
              child: GestureDetector(
                onTap:    onAvatarTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width:  44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size:  30,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── OVERLAPPING AVATARS (GROUP) ───────────────────────────────────────────────

class _OverlappingAvatars extends StatelessWidget {
  final List<String> paths;
  const _OverlappingAvatars({required this.paths});

  @override
  Widget build(BuildContext context) {
    const size     = 30.0;
    const overlap  = 14.0;
    final count    = paths.length.clamp(0, 5);
    final width    = size + (count - 1) * (size - overlap);

    return SizedBox(
      height: size,
      width:  width > 0 ? width : size,
      child: Stack(
        children: List.generate(count, (i) {
          return Positioned(
            left: i * (size - overlap),
            child: Container(
              width:  size,
              height: size,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                color:  Colors.white,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  paths[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF2A4A6E),
                    child: const Icon(Icons.person,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── DECORATIVE INPUT BAR ──────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad > 0 ? bottomPad : 16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color:        const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Write message...',
                style: GoogleFonts.spaceGrotesk(
                  color:    const Color(0xFFBBBBBB),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Container(
              width:  42,
              height: 42,
              margin: const EdgeInsets.only(right: 7),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size:  18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
