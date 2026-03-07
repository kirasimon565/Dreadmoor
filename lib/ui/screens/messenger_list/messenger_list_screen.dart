import 'dart:async';
import 'dart:ui';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/state/game_state.dart';
import '../../navigation/routes.dart';
import '../../theme/colors.dart';

class MessengerListScreen extends ConsumerStatefulWidget {
  const MessengerListScreen({super.key});

  @override
  ConsumerState<MessengerListScreen> createState() =>
      _MessengerListScreenState();
}

class _MessengerListScreenState extends ConsumerState<MessengerListScreen> {

  bool _showNotificationCenter = false;

  @override
  Widget build(BuildContext context) {

    final db = ref.watch(databaseProvider);

    final threadsStream = (db.select(db.threads)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.lastMessageId,
                  mode: OrderingMode.desc,
                )
          ]))
        .join([
          leftOuterJoin(
            db.messages,
            db.messages.id.equalsExp(db.threads.lastMessageId),
          )
        ])
        .watch();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [

            Column(
              children: [

                const _PhoneStatusBar(),

                const SizedBox(height: 6),

                _MessengerHeader(
                  onOpenNotifications: () {
                    setState(() {
                      _showNotificationCenter = !_showNotificationCenter;
                    });
                  },
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: StreamBuilder(
                    stream: threadsStream,
                    builder: (context, snapshot) {

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final rows = snapshot.data!;

                      if (rows.isEmpty) {
                        return const Center(
                          child: Text("No conversations yet"),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: rows.length,
                        itemBuilder: (context, index) {

                          final thread =
                              rows[index].readTable(db.threads);

                          final message =
                              rows[index].readTableOrNull(db.messages);

                          final time = message?.timestamp != null
                              ? DateFormat.Hm().format(message!.timestamp!)
                              : '';

                          return GestureDetector(
                            onTap: () {

                              ref
                                  .read(activeThreadIdProvider.notifier)
                                  .state = thread.id;

                              context.push(Routes.chat(thread.id));
                            },
                            child: _ThreadTile(
                              thread: thread,
                              message: message,
                              time: time,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const _BottomNavigationBar(),
              ],
            ),

            if (_showNotificationCenter)
              const _NotificationCenter(),
          ],
        ),
      ),
    );
  }
}

class _PhoneStatusBar extends StatelessWidget {
  const _PhoneStatusBar();

  @override
  Widget build(BuildContext context) {

    final time = DateFormat.Hm().format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [

          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),

          const Spacer(),

          const Icon(Icons.signal_cellular_4_bar,
              size: 16, color: Colors.white),

          const SizedBox(width: 6),

          const Icon(Icons.wifi, size: 16, color: Colors.white),

          const SizedBox(width: 6),

          const Icon(Icons.battery_full, size: 16, color: Colors.white),
        ],
      ),
    );
  }
}

class _MessengerHeader extends StatelessWidget {

  final VoidCallback onOpenNotifications;

  const _MessengerHeader({
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [

          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: onOpenNotifications,
          ),

          const Spacer(),

          Text(
            "Messenger",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push(Routes.settings);
            },
          ),
        ],
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {

  final Thread thread;
  final Message? message;
  final String time;

  const _ThreadTile({
    required this.thread,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [

          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.grey.shade800,
            child: const Icon(Icons.person),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  thread.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  message?.content ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Column(
            children: [

              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),

              if (thread.unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    thread.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  const _BottomNavigationBar();

  @override
  Widget build(BuildContext context) {

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [

          Icon(Icons.chat_bubble_outline, color: Colors.white),
          Icon(Icons.extension_outlined, color: Colors.white54),
          Icon(Icons.person_outline, color: Colors.white54),
          Icon(Icons.grid_view_outlined, color: Colors.white54),
          Icon(Icons.store_outlined, color: Colors.white54),
        ],
      ),
    );
  }
}

class _NotificationCenter extends StatelessWidget {
  const _NotificationCenter();

  @override
  Widget build(BuildContext context) {

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: Colors.black.withOpacity(0.8),
          child: const Center(
            child: Text(
              "Notification Center",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
