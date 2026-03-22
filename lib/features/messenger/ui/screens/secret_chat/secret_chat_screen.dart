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

const double _kVpnBarHeight = 44.0;

// ── VPN label variant pools ───────────────────────────────────────────────────
const _vpnVariants  = ['VPN: ACTIVE',       'VPN: STABLE',      'VPN: SECURED'];
const _encVariants  = ['ENCRYPTION: HIGH',  'ENCRYPTION: LOCKED','ENCRYPTION: AES-256'];
const _idVariants   = ['IDENTITY: HIDDEN',  'IDENTITY: MASKED',  'IDENTITY: ANON'];

class SecretChatScreen extends ConsumerStatefulWidget {
  final String threadId;
  const SecretChatScreen({super.key, required this.threadId});

  @override
  ConsumerState<SecretChatScreen> createState() => _SecretChatScreenState();
}

class _SecretChatScreenState extends ConsumerState<SecretChatScreen> {
  final _scrollController = ScrollController();
  final _rng = Random();

  late final Stream<Thread?>           _threadStream;
  late final Stream<List<Message>>     _messagesStream;
  late final Stream<List<TypedResult>> _membersWithNamesStream;

  int _lastCount = 0;

  // ── VPN bar animation state ───────────────────────────────────────────────
  Timer?  _vpnTimer;
  double  _vpnOpacity  = 1.0;
  String  _vpnStatus   = _vpnVariants[0];
  String  _encStatus   = _encVariants[0];
  String  _idStatus    = _idVariants[0];

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
        if (field == 0) _vpnStatus = _vpnVariants[_rng.nextInt(_vpnVariants.length)];
        if (field == 1) _encStatus = _encVariants[_rng.nextInt(_encVariants.length)];
        if (field == 2) _idStatus  = _idVariants[_rng.nextInt(_idVariants.length)];
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
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut);
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

              Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: StreamBuilder<Thread?>(
                      stream: _threadStream,
                      builder: (context, snap) {
                        final title = snap.data?.title ?? 'Unknown';
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  color: Colors.white, size: 24),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 1.5,
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft:  Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(title,
                                      style: const TextStyle(
                                        color:      Colors.white,
                                        fontSize:   18,
                                        fontWeight: FontWeight.w400,
                                      )),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Online',
                                          style: TextStyle(
                                            color:      Colors.white,
                                            fontSize:   12,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      const SizedBox(width: 4),
                                      Container(
                                        width: 8, height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.live_tv,
                                color: Colors.white, size: 24),
                          ],
                        );
                      },
                    ),
                  ),

                  // Messages
                  Expanded(
                    // Outer builder: resolves senderId → displayName map ONCE.
                    // Built here so it is not recomputed inside ListView.builder.
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
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) => _scrollToBottom(
                                      animated: _lastCount > 1));
                            }

                            if (messages.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            // Collect unique non-system senderIds, sort
                            // alphabetically for deterministic alignment.
                            final seenIds   = <String>{};
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
                                left:   16,
                                right:  16,
                                top:    8,
                                bottom: _kVpnBarHeight + 16,
                              ),
                              itemCount: messages.length + 1,
                              itemBuilder: (context, i) {
                                if (i == messages.length) {
                                  return _buildTypingIndicator();
                                }
                                final msg = messages[i];

                                // Build display text with sender name prefix.
                                // nameMap built once in outer StreamBuilder —
                                // not recomputed per item.
                                final senderName =
                                    nameMap[msg.senderId] ?? msg.senderId;
                                final displayText = msg.senderId != 'system'
                                    ? '${senderName.toUpperCase()}\n${msg.content ?? ''}'
                                    : msg.content ?? '';

                                return ChatBubble(
                                  text:      displayText,
                                  isMe:      msg.senderId == rightSenderId,
                                  senderId:  null, // suppress ChatBubble name — displayText already contains it
                                  timestamp: msg.timestamp,
                                  isSecret:  true,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),

              // ChoiceOverlay REMOVED — secret chat is read-only.
              // The player cannot send messages here.

              // VPN status bar — animated labels, subtle opacity flicker
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: AnimatedOpacity(
                  opacity:  _vpnOpacity,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    height: _kVpnBarHeight,
                    color:  Colors.black.withOpacity(0.35),
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
              isSecret:   true,
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
        color:        Colors.white,
        fontSize:     11,
        fontWeight:   FontWeight.w300,
        letterSpacing: 0.5,
      ),
    );
  }
}
