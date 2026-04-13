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
import 'package:dreadmoor/ui/widgets/gun_typing_indicator.dart'; // Renamed from feather_typing_indicator.dart
import 'package:dreadmoor/ui/screens/profiles/character_profile_screen.dart';

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
  late final Stream<List<TypedResult>> _membersWithNamesStream;
  late final Stream<List<ThreadMember>> _membersStream;

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
        .join([
      leftOuterJoin(
          db.characters, db.characters.id.equalsExp(db.messages.senderId)),
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

      final activeChoiceRow = await (db.select(db.storyState)
            ..where((t) => t.key.equals('active_choice_id')))
          .getSingleOrNull();

      if (activeChoiceRow?.stringValue != null) {
        ref
            .read(activeNodeIdProvider.notifier)
            .setId(activeChoiceRow!.stringValue!); // Use ! for non-null assertion
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
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(max);
    }
  }

  Map<String, VoidCallback> _buildMemberTapMap(List<ThreadMember> members) {
    return {
      for (final m in members.where((m) => m.characterId != 'player'))
        m.characterId: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CharacterProfileScreen(characterId: m.characterId),
            ),
          );
        },
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ThreadMember>>(
      stream: _membersStream,
      builder: (context, membersSnap) {
        final members = membersSnap.data ?? [];
        final isGroup = members.length > 1;

        final nonPlayer =
            members.where((m) => m.characterId != 'player').toList();

        final avatarPaths = nonPlayer
            .map((m) => 'assets/characters/${m.characterId}.png')
            .toList();

        final memberIds = nonPlayer.map((m) => m.characterId).toList();

        final memberTapMap = _buildMemberTapMap(members);

        final singleProfileId =
            nonPlayer.isNotEmpty ? nonPlayer.first.characterId : null;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: Image.asset(
                  isGroup
                      ? 'assets/images/group_chat_bg.png'
                      : 'assets/images/forest_bg.png',
                  key: ValueKey(isGroup),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFF0B1520)),
                ),
              ),
            ),

            // Transparent Floating Header Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: StreamBuilder<Thread?>(
                  stream: _threadStream,
                  builder: (context, snap) {
                    final threadTitle = snap.data?.title ?? 'UNKNOWN';
                    return _ChatHeader(
                      title: threadTitle,
                      isGroup: isGroup,
                      avatarPaths: avatarPaths,
                      onBackPressed: () {
                        ref.read(activeThreadIdProvider.notifier).setId(null);
                        ref
                            .read(activeAppProvider.notifier)
                            .setApp(PhoneApp.messenger);
                        Navigator.pop(context);
                      },
                      onProfileTap: isGroup
                          ? null
                          : singleProfileId != null
                              ? () {
                                  HapticFeedback.selectionClick();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CharacterProfileScreen(
                                        characterId: singleProfileId,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                    );
                  },
                ),
              ),
            ),

            // Lower Section: White Rounded Sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: MediaQuery.of(context).size.height * 0.4, // Starts from lower half
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40), // Large smooth rounded top corners
                    topRight: Radius.circular(40),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  child: StreamBuilder<List<TypedResult>>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      final messages = snapshot.data ?? [];

                      if (messages.length != _lastMessageCount) {
                        _lastMessageCount = messages.length;
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToBottom(
                            animated: _lastMessageCount > 1,
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 24,
                          bottom: 100, // Space for the input bar
                        ),
                        itemCount: messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return _buildTypingIndicator();
                          }

                          final db = ref.read(databaseProvider);
                          final row = messages[index];
                          final msg = row.readTable(db.messages);
                          final character =
                              row.readTableOrNull(db.characters);

                          return ChatBubble(
                            text: msg.content ?? '',
                            isMe: msg.isPlayerMessage,
                            senderId: msg.senderId,
                            senderName: isGroup ? character?.name : null, // Show sender name only in group chat
                            timestamp: msg.timestamp,
                            isSecret: msg.isSecret,
                            mediaType: msg.type,
                            mediaPath: msg.mediaPath,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

            // Choice Overlay (includes input bar when not waiting for choice)
            const ChoiceOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<Thread?>(
      stream: _threadStream,
      builder: (context, threadSnap) {
        if (threadSnap.data?.isTyping != true) {
          return const SizedBox(height: 20);
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
              isSecret: false,
            );
          },
        );
      },
    );
  }
}

// Custom Chat Header Widget
class _ChatHeader extends StatelessWidget {
  final String title;
  final bool isGroup;
  final List<String> avatarPaths;
  final VoidCallback onBackPressed;
  final VoidCallback? onProfileTap;

  const _ChatHeader({
    required this.title,
    required this.isGroup,
    required this.avatarPaths,
    required this.onBackPressed,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
            onPressed: onBackPressed,
          ),
          const SizedBox(width: 8),
          // Title and Subtitle/Avatars
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                if (!isGroup) // Single Chat Subtitle
                  Text(
                    'Online',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ) // Group Chat Avatars
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: avatarPaths.take(3).map((path) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundImage: AssetImage(path),
                          backgroundColor: Colors.grey.shade800,
                        ),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Profile Icon Button (Single Chat Only)
          if (!isGroup)
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white, size: 24), // Person silhouette icon
              onPressed: onProfileTap,
            )
          else
            const SizedBox(width: 48), // Placeholder for alignment in group chat
        ],
      ),
    );
  }
}
