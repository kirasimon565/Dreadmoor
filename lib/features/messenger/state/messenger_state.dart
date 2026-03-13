import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';

/// Data model combining thread and message for the Inbox List
class ThreadWithLastMessage {
  final Thread thread;
  final Message? lastMessage;
  final Character? character; // Added to pull avatars into the list

  ThreadWithLastMessage(this.thread, this.lastMessage, this.character);
}

/// Messenger thread list (Standard Inbox)
/// Filters out secret chats unless specifically requested
final threadsStreamProvider = StreamProvider<List<ThreadWithLastMessage>>((ref) {
  final db = ref.watch(databaseProvider);

  final query = (db.select(db.threads)
        ..where((t) => t.isSecret.equals(false))
        ..orderBy([
          (t) => OrderingTerm(
            expression: t.lastMessageId,
            mode: OrderingMode.desc,
          ),
        ]))
      .join([
        leftOuterJoin(
          db.messages,
          db.messages.id.equalsExp(db.threads.lastMessageId),
        ),
        leftOuterJoin(
          db.characters,
          db.characters.id.equalsExp(db.threads.id),
        ),
      ]);

  return query.watch().map((rows) {
    return rows.map((row) {
      return ThreadWithLastMessage(
        row.readTable(db.threads),
        row.readTableOrNull(db.messages),
        row.readTableOrNull(db.characters),
      );
    }).toList();
  });
});

/// Secret / Intercepted Threads only
final secretThreadsStreamProvider = StreamProvider<List<ThreadWithLastMessage>>((ref) {
  final db = ref.watch(databaseProvider);

  final query = (db.select(db.threads)
        ..where((t) => t.isSecret.equals(true))
        ..orderBy([
          (t) => OrderingTerm(expression: t.lastMessageId, mode: OrderingMode.desc),
        ]))
      .join([
        leftOuterJoin(db.messages, db.messages.id.equalsExp(db.threads.lastMessageId)),
        leftOuterJoin(db.characters, db.characters.id.equalsExp(db.threads.id)),
      ]);

  return query.watch().map((rows) {
    return rows.map((row) {
      return ThreadWithLastMessage(
        row.readTable(db.threads),
        row.readTableOrNull(db.messages),
        row.readTableOrNull(db.characters),
      );
    }).toList();
  });
});

/// Messages inside a specific thread
/// Uses 'timestamp' for the visual sort to match the Game Clock
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((ref, threadId) {
  final db = ref.watch(databaseProvider);

  return (db.select(db.messages)
        ..where((tbl) => tbl.threadId.equals(threadId))
        ..orderBy([
          (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
        ]))
      .watch();
});

/// Single thread state for the Chat Header (Pill Design)
final threadProvider = StreamProvider.family<Thread?, String>((ref, threadId) {
  final db = ref.watch(databaseProvider);

  return (db.select(db.threads)..where((t) => t.id.equals(threadId)))
      .watchSingleOrNull();
});

/// Typing indicator state - Triggers the GunTypingIndicator
final threadTypingProvider = StreamProvider.family<bool, String>((ref, threadId) {
  final db = ref.watch(databaseProvider);

  return (db.select(db.threads)..where((t) => t.id.equals(threadId)))
      .watchSingleOrNull()
      .map((thread) => thread?.isTyping ?? false);
});
