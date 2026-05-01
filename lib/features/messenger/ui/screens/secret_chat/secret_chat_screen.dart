import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' hide Column;

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/ui/widgets/chat_bubble.dart';
import 'package:dreadmoor/ui/widgets/gun_typing_indicator.dart';

class SecretChatScreen extends ConsumerStatefulWidget {
  final String threadId;

  const SecretChatScreen({super.key, required this.threadId});

  @override
  ConsumerState<SecretChatScreen> createState() => _SecretChatScreenState();
}

class _SecretChatScreenState extends ConsumerState<SecretChatScreen> {
  final ScrollController _scrollController = ScrollController();
  late Stream<Thread?> _threadStream;
  late Stream<List<Message>> _messagesStream;
  late Stream<List<TypedResult>> _membersWithNamesStream;

  int _lastCount = 0;

  // VPN Status Simulation
  Timer? _vpnTimer;
  final _rng = Random();
  String _vpnStatus = 'VPN ACTIVE';
  String _encStatus = 'AES-256 LOCKED';
  String _idStatus = 'ANON-ROUTING';
  double _vpnOpacity = 1.0;

  static const double _kVpnBarHeight = 40.0;

  final _vpnVariants = [
    'VPN ACTIVE',
    'VPN REROUTING',
    'PROXY SECURE',
    'ONION LIVE',
  ];
  final _encVariants = [
    'AES-256 LOCKED',
    'RSA-4096 VALID',
    'ENC: ENFORCED',
    'HANDSHAKE OK',
  ];
  final _idVariants = [
    'ANON-ROUTING',
    'ID MASKED',
    'GHOST MODE',
    'IP OBFUSCATED',
  ];

  @override
  void initState() {
    super.initState();
    final db = ref.read(databaseProvider);

    _threadStream = (db.select(
      db.threads,
    )..where((t) => t.id.equals(widget.threadId))).watchSingleOrNull();

    _messagesStream =
        (db.select(db.messages)
              ..where((m) => m.threadId.equals(widget.threadId))
              ..orderBy([(m) => OrderingTerm(expression: m.timestamp)]))
            .watch();

    _membersWithNamesStream =
        (db.select(
          db.threadMembers,
        )..where((m) => m.threadId.equals(widget.threadId))).join([
          innerJoin(
            db.characters,
            db.characters.id.equalsExp(db.threadMembers.characterId),
          ),
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
    final delay = Duration(milliseconds: 2000 + _rng.nextInt(2000));
    _vpnTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _vpnOpacity = 0.5;
        final field = _rng.nextInt(3);
        if (field == 0)
          _vpnStatus = _vpnVariants[_rng.nextInt(_vpnVariants.length)];
        if (field == 1)
          _encStatus = _encVariants[_rng.nextInt(_encVariants.length)];
        if (field == 2)
          _idStatus = _idVariants[_rng.nextInt(_idVariants.length)];
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _vpnOpacity = 1.0);
      });
      _startVpnCycle();
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
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(max);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image Edge-to-Edge
          Positioned.fill(
            child: Image.asset(
              'assets/media/images/skull_noir_bg.png', // Dark skull noir background
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF000000)),
            ),
          ),

          // Main content area
          Column(
            children: [
              // Header
              SafeArea(
                bottom: false,
                child: StreamBuilder<Thread?>(
                  stream: _threadStream,
                  builder: (context, snap) {
                    final title = snap.data?.title ?? 'Unknown';
                    return _SecretChatHeader(
                      title: title,
                      onBackPressed: () {
                        ref.read(activeThreadIdProvider.notifier).setId(null);
                        ref
                            .read(activeAppProvider.notifier)
                            .setApp(PhoneApp.messenger);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),

              // Messages
              Expanded(
                child: StreamBuilder<List<TypedResult>>(
                  stream: _membersWithNamesStream,
                  builder: (context, membersSnap) {
                    final db = ref.read(databaseProvider);

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
                            (_) => _scrollToBottom(animated: _lastCount > 1),
                          );
                        }

                        if (messages.isEmpty) {
                          return const SizedBox.shrink();
                        }

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
                            : (senderIds.isNotEmpty ? senderIds[0] : null);

                        return ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 24,
                            bottom: _kVpnBarHeight + 16, // Space for VPN bar
                          ),
                          itemCount: messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              return _buildTypingIndicator();
                            }

                            final msg = messages[index];
                            final isMe = msg.senderId == rightSenderId;

                            return ChatBubble(
                              text: msg.content ?? '',
                              isMe: isMe,
                              senderId: msg.senderId,
                              senderName: nameMap[msg.senderId],
                              timestamp: msg.timestamp,
                              isSecret: true, // Always secret for this screen
                              mediaType: msg.type,
                              mediaPath: msg.mediaPath,
                              isGroup: false,
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

          // VPN Status Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _vpnOpacity,
              duration: const Duration(milliseconds: 100),
              child: SafeArea(
                top: false,
                child: Container(
                  height: _kVpnBarHeight,
                  color: Colors.black.withOpacity(
                    0.8,
                  ), // Dark background for VPN bar
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatusText(text: _vpnStatus),
                      _StatusText(text: _encStatus),
                      _StatusText(text: _idStatus),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<Thread?>(
      stream: _threadStream,
      builder: (context, threadSnap) {
        if (threadSnap.data?.isTyping != true) {
          return const SizedBox(height: 20);
        }

        final typingUserId = threadSnap.data?.typingUserId;

        return StreamBuilder<List<TypedResult>>(
          stream: _membersWithNamesStream,
          builder: (context, membersSnap) {
            final db = ref.read(databaseProvider);

            String? senderName;

            if (membersSnap.hasData && typingUserId != null) {
              for (final row in membersSnap.data!) {
                final char = row.readTableOrNull(db.characters);
                if (char != null && char.id == typingUserId) {
                  senderName = char.name;
                  break;
                }
              }
            }

            return GunTypingIndicator(senderName: senderName ?? 'Someone', isSecret: true);
          },
        );
      },
    );
  }
}

// Custom Secret Chat Header Widget
class _SecretChatHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;

  const _SecretChatHeader({required this.title, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 24,
            ),
            onPressed: onBackPressed,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spectral(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Live',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48), // Placeholder for alignment
        ],
      ),
    );
  }
}

// VPN Status Text Widget
class _StatusText extends StatelessWidget {
  final String text;
  const _StatusText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.white.withOpacity(0.7),
        letterSpacing: 0.8,
      ),
    );
  }
}
