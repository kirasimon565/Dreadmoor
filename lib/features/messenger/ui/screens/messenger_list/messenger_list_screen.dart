import 'dart:ui';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/features/messenger/ui/messenger_navigator.dart';
import 'package:dreadmoor/ui/os/components/os_header.dart';

class MessengerListScreen extends ConsumerStatefulWidget {
  const MessengerListScreen({super.key});

  @override
  ConsumerState<MessengerListScreen> createState() => _MessengerListScreenState();
}

class _MessengerListScreenState extends ConsumerState<MessengerListScreen> {

  void _showAddContactDialog(BuildContext context) {
    String phoneNumber = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DreadmoorColors.surfaceAlt,
        title: Text(
          "Add Contact",
          style: DreadmoorTheme.headingStyle.copyWith(color: Colors.white, fontSize: 18),
        ),
        content: TextField(
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: "Enter phone number",
            hintStyle: const TextStyle(color: Colors.white54),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: DreadmoorColors.accentCyan),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
          ),
          onChanged: (value) => phoneNumber = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              if (phoneNumber.isNotEmpty) {
                final db = ref.read(databaseProvider);

                // Validate if number exists in Characters table
                final character = await (db.select(db.characters)..where((c) => c.phoneNumber.equals(phoneNumber))).getSingleOrNull();

                if (!context.mounted) return;

                if (character == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Number not recognized.', style: DreadmoorTheme.bodyStyle.copyWith(color: Colors.white)),
                      backgroundColor: DreadmoorColors.accentRed.withOpacity(0.8),
                    )
                  );
                  return;
                }

                // Valid character found, check if thread exists
                final threadId = character.id; // Usually threadId matches characterId or a specific format

                final existingThread = await (db.select(db.threads)..where((t) => t.id.equals(threadId))).getSingleOrNull();

                if (existingThread == null) {
                  await db.into(db.threads).insert(
                    ThreadsCompanion.insert(
                      id: threadId,
                      title: character.name,
                      participants: character.id,
                      unreadCount: const Value(0),
                      isTyping: const Value(false),
                      isLocked: const Value(false),
                      isSecret: const Value(false),
                    ),
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context); // Close the dialog
                  // Automatically open the chat thread for the added contact
                  ref.read(activeThreadIdProvider.notifier).state = threadId;
                  Navigator.of(context).pushNamed(MessengerRoutes.chat, arguments: threadId);
                }
              }
            },
            child: const Text("Add", style: TextStyle(color: DreadmoorColors.accentCyan)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    final threadsStream = (db.select(db.threads)..orderBy([
      (t) => OrderingTerm(expression: t.lastMessageId, mode: OrderingMode.desc)
    ])).join([
      leftOuterJoin(db.messages, db.messages.id.equalsExp(db.threads.lastMessageId)),
      leftOuterJoin(db.characters, db.characters.id.equalsExp(db.threads.id)),
    ]).watch();

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Column(
        children: [
          OSHeader(
            title: "MESSENGER",
            subtitle: "SECURE CONNECTION",
            leading: GestureDetector(
                onTap: () {
                    Navigator.of(context).pushNamed(MessengerRoutes.settings);
                },
                child: const Icon(Icons.settings, color: DreadmoorColors.textSecondary, size: 20)
            ),
            trailing: GestureDetector(
                onTap: () {
                    _showAddContactDialog(context);
                },
                child: const Icon(Icons.person_add_alt_1, color: DreadmoorColors.textSecondary, size: 20)
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // Subtle background gradient for depth
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          DreadmoorColors.surfaceAlt.withOpacity(0.3),
                          DreadmoorColors.background,
                        ],
                      ),
                    ),
                  ),
                ),
                StreamBuilder(
                  stream: threadsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: DreadmoorColors.accentCyan));
                    }

                    final rows = snapshot.data!;

                    if (rows.isEmpty) {
                      return Center(
                        child: Text(
                          "No secure connections established.",
                          style: DreadmoorTheme.bodyStyle.copyWith(color: DreadmoorColors.textSecondary),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12), // Using spacing instead of dividers for a cleaner look
                      itemBuilder: (context, index) {
                        final thread = rows[index].readTable(db.threads);
                        final message = rows[index].readTableOrNull(db.messages);
                        final character = rows[index].readTableOrNull(db.characters);

                        String time = '';
                        if (message?.timestamp != null) {
                          time = '${message!.timestamp!.hour.toString().padLeft(2, '0')}:${message!.timestamp!.minute.toString().padLeft(2, '0')}';
                        }

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            ref.read(activeThreadIdProvider.notifier).state = thread.id;
                            if (thread.isSecret) {
                                Navigator.of(context).pushNamed(MessengerRoutes.secret, arguments: thread.id);
                            } else {
                                Navigator.of(context).pushNamed(MessengerRoutes.chat, arguments: thread.id);
                            }
                          },
                          child: _ThreadTile(
                            thread: thread,
                            message: message,
                            time: time,
                            avatarPath: character?.avatarPath,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
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
  final String? avatarPath;

  const _ThreadTile({
    required this.thread,
    required this.message,
    required this.time,
    this.avatarPath,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = thread.unreadCount > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DreadmoorColors.surface.withOpacity(hasUnread ? 0.9 : 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasUnread ? DreadmoorColors.accentCyan.withOpacity(0.3) : DreadmoorColors.borderSubtle,
          width: hasUnread ? 1.0 : 0.5,
        ),
        boxShadow: hasUnread ? [
          BoxShadow(
            color: DreadmoorColors.glowCyan.withOpacity(0.1),
            blurRadius: 8,
          )
        ] : null,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: DreadmoorColors.surfaceGlass,
              shape: BoxShape.circle,
              border: Border.all(
                  color: hasUnread ? DreadmoorColors.accentCyan.withOpacity(0.5) : DreadmoorColors.borderGlass,
                  width: hasUnread ? 1.5 : 1.0,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: thread.isSecret
              ? Icon(Icons.security, color: hasUnread ? DreadmoorColors.accentCyan : DreadmoorColors.accentRed)
              : avatarPath != null
                  ? Image.asset(avatarPath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.person, color: hasUnread ? DreadmoorColors.accentCyan : DreadmoorColors.textSecondary))
                  : Icon(Icons.person, color: hasUnread ? DreadmoorColors.accentCyan : DreadmoorColors.textSecondary),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.title,
                  style: DreadmoorTheme.headingStyle.copyWith(
                    color: DreadmoorColors.textPrimary,
                    fontSize: 16,
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  message?.content ?? "",
                  style: DreadmoorTheme.bodyStyle.copyWith(
                    color: hasUnread ? DreadmoorColors.textPrimary : DreadmoorColors.textSecondary,
                    fontSize: 14,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Meta
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                time,
                style: DreadmoorTheme.bodyStyle.copyWith(
                  color: hasUnread ? DreadmoorColors.accentCyan : DreadmoorColors.textMeta,
                  fontSize: 11,
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DreadmoorColors.accentCyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DreadmoorColors.accentCyan.withOpacity(0.5)),
                  ),
                  child: Text(
                    thread.unreadCount.toString(),
                    style: DreadmoorTheme.bodyStyle.copyWith(
                      color: DreadmoorColors.accentCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
