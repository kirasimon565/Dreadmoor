import 'dart:ui';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // --- ADD CONTACT DIALOG (Updated with Redesign Colors) ---
  void _showAddContactDialog(BuildContext context) {
    String phoneNumber = "";
    final brightness = Theme.of(context).brightness;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DreadmoorColors.surface(Theme.of(context).brightness),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Sharper
        title: Text(
          "NEW CONNECTION",
          style: DreadmoorTheme.headingStyle(brightness).copyWith(fontSize: 18),
        ),
        content: TextField(
          style: TextStyle(color: DreadmoorColors.text(brightness)),
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: "Enter frequency/number",
            hintStyle: TextStyle(color: DreadmoorColors.text(brightness).withOpacity(0.4)),
          ),
          onChanged: (value) => phoneNumber = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: TextStyle(color: DreadmoorColors.text(brightness).withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () async {
              if (phoneNumber.isNotEmpty) {
                final db = ref.read(databaseProvider);
                final character = await (db.select(db.characters)..where((c) => c.phoneNumber.equals(phoneNumber))).getSingleOrNull();

                if (!context.mounted) return;
                if (character == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Frequency not found.')));
                  return;
                }

                final threadId = character.id;
                final existingThread = await (db.select(db.threads)..where((t) => t.id.equals(threadId))).getSingleOrNull();

                if (existingThread == null) {
                  await db.into(db.threads).insert(ThreadsCompanion.insert(
                    id: threadId,
                    title: character.name,
                    participants: character.id,
                  ));
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed(MessengerRoutes.chat, arguments: threadId);
                }
              }
            },
            child: Text("ESTABLISH", style: TextStyle(color: DreadmoorColors.investigatorCyan)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final brightness = Theme.of(context).brightness;

    final threadsStream = (db.select(db.threads)..orderBy([
      (t) => OrderingTerm(expression: t.lastMessageId, mode: OrderingMode.desc)
    ])).join([
      leftOuterJoin(db.messages, db.messages.id.equalsExp(db.threads.lastMessageId)),
      leftOuterJoin(db.characters, db.characters.id.equalsExp(db.threads.id)),
    ]).watch();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          OSHeader(
            title: "INBOX",
            subtitle: "SECURE ARCHIVE",
            leading: IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).pushNamed(MessengerRoutes.settings),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () => _showAddContactDialog(context),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: threadsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final rows = snapshot.data!;

                if (rows.isEmpty) {
                  return Center(
                    child: Text("No connections found.", style: DreadmoorTheme.bodyStyle(brightness)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final thread = rows[index].readTable(db.threads);
                    final message = rows[index].readTableOrNull(db.messages);
                    final character = rows[index].readTableOrNull(db.characters);

                    return _ThreadTile(
                      thread: thread,
                      message: message,
                      character: character,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadTile extends ConsumerWidget {
  final Thread thread;
  final Message? message;
  final Character? character;

  const _ThreadTile({required this.thread, this.message, this.character});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final hasUnread = thread.unreadCount > 0;
    final accent = brightness == Brightness.light ? DreadmoorColors.evidenceRed : DreadmoorColors.investigatorCyan;

    return GestureDetector(
      onTap: () {
        ref.read(activeThreadIdProvider.notifier).state = thread.id;
        Navigator.of(context).pushNamed(
          thread.isSecret ? MessengerRoutes.secret : MessengerRoutes.chat, 
          arguments: thread.id
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(4), // Sharp corners like Case File
          border: Border.all(
            color: hasUnread ? accent : DreadmoorColors.divider(brightness),
            width: hasUnread ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // Avatar with Sharp Border
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                border: Border.all(color: hasUnread ? accent : Colors.black12),
              ),
              child: thread.isSecret 
                ? Icon(Icons.security, color: DreadmoorColors.evidenceRed)
                : (character?.avatarPath != null 
                    ? Image.asset(character!.avatarPath!, fit: BoxFit.cover)
                    : const Icon(Icons.person)),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.title.toUpperCase(),
                    style: DreadmoorTheme.headingStyle(brightness).copyWith(
                      fontSize: 14,
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message?.content ?? "No messages yet.",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DreadmoorTheme.bodyStyle(brightness).copyWith(
                      fontSize: 13,
                      color: DreadmoorColors.text(brightness).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (hasUnread)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
              ),
          ],
        ),
      ),
    );
  }
}
