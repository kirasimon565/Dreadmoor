import 'dart:async';
import 'dart:ui';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/navigation/routes.dart';
import 'package:dreadmoor/ui/theme/colors.dart';

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

    final threadsStream =
        (db.select(db.threads)..orderBy([
          (t) => OrderingTerm(
                expression: t.lastMessageId,
                mode: OrderingMode.desc,
              )
        ]))
            .join([
      leftOuterJoin(
        db.messages,
        db.messages.id.equalsExp(db.threads.lastMessageId),
      ),
    ]).watch();

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const _PhoneStatusBar(),

                const SizedBox(height: 6),

                _MessengerHeader(
                  onAddContact: _showAddContactDialog,
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: StreamBuilder(
                    stream: threadsStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final rows = snapshot.data!;

                      if (rows.isEmpty) {
                        return const Center(
                          child: Text(
                            "No conversations yet",
                            style: TextStyle(color: Colors.white54),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final thread = rows[index].readTable(db.threads);

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

            if (_showNotificationCenter) const _NotificationCenter(),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();

        return Dialog(
          backgroundColor: DreadmoorColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Add Contact Number",
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter phone number",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.black,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Number saved (future episode feature)"),
                          ),
                        );
                      },
                      child: const Text("Save"),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
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
          Text(time,
              style: const TextStyle(color: Colors.white, fontSize: 12)),

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
  final VoidCallback onAddContact;

  const _MessengerHeader({required this.onAddContact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [

          /// SETTINGS ICON RESTORED
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push(Routes.settings);
            },
          ),

          const Spacer(),

          Column(
            children: [
              Text(
                "Messenger",
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                "Your chats and stories",
                style:
                    GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),

          const Spacer(),

          /// ADD CONTACT ICON
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: onAddContact,
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
                      fontSize: 15),
                ),

                const SizedBox(height: 4),

                Text(
                  message?.content ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          Column(
            children: [
              Text(
                time,
                style:
                    const TextStyle(fontSize: 11, color: Colors.white54),
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
                        color: Colors.white, fontSize: 10),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  const _BottomNavigationBar();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white54,
      showSelectedLabels: true,
      showUnselectedLabels: true,

      onTap: (index) {
        switch (index) {
          case 0:
            context.go(Routes.messenger);
            break;
          case 1:
            context.go('/puzzle');
            break;
          case 2:
            context.go(Routes.playerProfile);
            break;
          case 3:
            context.go('/apps');
            break;
          case 4:
            context.go('/store');
            break;
        }
      },

      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline), label: "Chat"),
        BottomNavigationBarItem(
            icon: Icon(Icons.extension_outlined), label: "Puzzle"),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: "Profile"),
        BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined), label: "Apps"),
        BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined), label: "Store"),
      ],
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
