import 'dart:async';
import 'dart:math';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/ui/widgets/chat_bubble.dart';
import 'package:dreadmoor/ui/widgets/gun_typing_indicator.dart';
import 'package:google_fonts/google_fonts.dart';

const double _kVpnBarHeight = 44.0;

// ── VPN label variant pools ───────────────────────────────────────────────────
const _vpnVariants = ['VPN: ACTIVE', 'VPN: STABLE', 'VPN: SECURED'];
const _encVariants = [
  'ENCRYPTION: HIGH',
  'ENCRYPTION: LOCKED',
  'ENCRYPTION: AES-256'
];
const _idVariants = ['IDENTITY: HIDDEN', 'IDENTITY: MASKED', 'IDENTITY: ANON'];

class SecretChatScreen extends ConsumerStatefulWidget {
  final String threadId;
  const SecretChatScreen({super.key, required this.threadId});

  @override
  ConsumerState<SecretChatScreen> createState() => _SecretChatScreenState();
}

class _SecretChatScreenState extends ConsumerState<SecretChatScreen> {
  final _scrollController = ScrollController();
  final _rng = Random();

  late final Stream<Thread?> _threadStream;
  late final Stream<List<Message>> _messagesStream;
  late final Stream<List<TypedResult>> _membersWithNamesStream;

  int _lastCount = 0;

  // ── VPN bar animation state ───────────────────────────────────────────────
  Timer? _vpnTimer;
  double _vpnOpacity = 1.0;
  String _vpnStatus = _vpnVariants[0];
  String _encStatus = _encVariants[0];
  String _idStatus = _idVariants[0];

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

    _membersWithNamesStream = (db.select(db.threadMembers)
          ..where((m) => m.threadId.equals(widget.threadId)))
        .join([
      innerJoin(db.characters,
          db.characters.id.equalsExp(db.threadMembers.characterId)),
    ]).watch();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(activeThreadIdProvider.notifier).setId(widget.threadId);
        ref.read(globalSchedulerProvider).resumeIfThreadActive(widget.threadId);
      }
    });

    _startVpnCycle();
  }

  void _startVpnCycle() {
    // Pick a random interval between 2–4 seconds, then cycle one label
    // and schedule the next tick. Subtle opacity flicker accompanies each change.
    final delay = Duration(milliseconds: 2000 + _rng.nextInt(2000));
    _vpnTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _vpnOpacity = 0.5; // brief dim
        // Randomly pick which field to update
        final field = _rng.nextInt(3);
        if (field == 0)
          _vpnStatus = _vpnVariants[_rng.nextInt(_vpnVariants.length)];
        if (field == 1)
          _encStatus = _encVariants[_rng.nextInt(_encVariants.length)];
        if (field == 2)
          _idStatus = _idVariants[_rng.nextInt(_idVariants.length)];
      });
      // Restore opacity after 200ms
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _vpnOpacity = 1.0);
      });
      _startVpnCycle(); // reschedule
    });
  }

  @override
  void dispose() {
    _vpnTimer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF000000), Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Top gradient behind header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 180,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: StreamBuilder<Thread?>(
                      stream: _threadStream,
                      builder: (context, snap) {
                        final title = snap.data?.title ?? 'Unknown';
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(title,
                                    style: GoogleFonts.spectral(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    )),
                                const SizedBox(height: 4),
                                Text('Live',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    )),
                              ],
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  behavior: HitTestBehavior.opaque,
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(Icons.chevron_left,
                                        color: Colors.white, size: 32),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Messages
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        child: StreamBuilder<List<TypedResult>>(
                          stream: _membersWithNamesStream,
                          builder: (context, membersSnap) {
                            final db = ref.read(databaseProvider);

                            // Build nameMap once from the members snapshot
                            final nameMap = <String, String>{};
                            if (membersSnap.hasData) {
                              for (final row in membersSnap.data!) {
                                final char = row.readTableOrNull(db.characters);
                                if (char != null) {
                                  nameMap[char.id] = char.name;
                                }
                              }
                            }

                            return StreamBuilder<List<Message>>(
                              stream: _messagesStream,
                              builder: (context, snap) {
                                final messages = snap.data ?? [];

                                if (messages.length != _lastCount) {
                                  _lastCount = messages.length;
                                  WidgetsBinding.instance.addPostFrameCallback(
                                      (_) => _scrollToBottom(
                                          animated: _lastCount > 1));
                                }

                                if (messages.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                // Collect unique non-system senderIds, sort
                                // alphabetically for deterministic alignment.
                                final seenIds = <String>{};
                                final senderIds = <String>[];
                                for (final m in messages) {
                                  if (m.senderId != 'system' &&
                                      seenIds.add(m.senderId)) {
                                    senderIds.add(m.senderId);
                                  }
                                }
                                senderIds.sort();
                                final rightSenderId = senderIds.length > 1
                                    ? senderIds[1]
                                    : (senderIds.isNotEmpty
                                        ? senderIds.first
                                        : null);

                                return ListView.builder(
                                  controller: _scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 24,
                                    bottom: _kVpnBarHeight + 100,
                                  ),
                                  itemCount: messages.length + 1,
                                  itemBuilder: (context, i) {
                                    if (i == messages.length) {
                                      return _buildTypingIndicator();
                                    }
                                    final msg = messages[i];
                                    final isRight =
                                        msg.senderId == rightSenderId;
                                    final isSystem = msg.senderId == 'system';

                                    // Sender name rendered above the bubble,
                                    // not injected into message text.
                                    final senderName = isSystem
                                        ? null
                                        : (nameMap[msg.senderId] ??
                                                msg.senderId)
                                            .toUpperCase();

                                    return Column(
                                      crossAxisAlignment: isRight
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        if (senderName != null)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: isRight ? 0 : 28,
                                              right: isRight ? 28 : 0,
                                              bottom: 2,
                                            ),
                                            child: Text(
                                              senderName,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF8FA8B8),
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ),
                                        ChatBubble(
                                          text: msg.content ?? '',
                                          isMe: isRight,
                                          senderId: null,
                                          timestamp: msg.timestamp,
                                          isSecret: true,
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ChoiceOverlay REMOVED — secret chat is read-only.
              // The player cannot send messages here.

              // VPN status bar — animated labels, subtle opacity flicker
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _vpnOpacity,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    height: _kVpnBarHeight,
                    color: Colors.black.withOpacity(0.35),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatusText(label: _vpnStatus),
                        _StatusText(label: _encStatus),
                        _StatusText(label: _idStatus),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<Thread?>(
      stream: _threadStream,
      builder: (context, threadSnap) {
        if (threadSnap.data?.isTyping != true) {
          return const SizedBox(height: 8);
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
              isSecret: true,
            );
          },
        );
      },
    );
  }
}

class _StatusText extends StatelessWidget {
  final String label;
  const _StatusText({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.5,
      ),
    );
  }
}
