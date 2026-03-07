import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';

class ThreadWithLastMessage {
  final Thread thread;
  final Message? lastMessage;

  ThreadWithLastMessage(this.thread, this.lastMessage);
}

/// Messenger thread list (non-secret chats)
final threadsStreamProvider = StreamProvider<List<ThreadWithLastMessage>>((
  ref,
) {
  final db = ref.watch(databaseProvider);

  final query =
      (db.select(db.threads)
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
          ]);

  return query.watch().map((rows) {
    return rows.map((row) {
      return ThreadWithLastMessage(
        row.readTable(db.threads),
        row.readTableOrNull(db.messages),
      );
    }).toList();
  });
});

/// Messages inside a specific thread
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((
  ref,
  threadId,
) {
  final db = ref.watch(databaseProvider);

  return (db.select(db.messages)
        ..where((tbl) => tbl.threadId.equals(threadId))
        ..orderBy([
          (t) => OrderingTerm(expression: t.sequence, mode: OrderingMode.asc),
        ]))
      .watch();
});

/// Single thread stream (used by chat screen)
final threadProvider = StreamProvider.family<Thread?, String>((ref, threadId) {
  final db = ref.watch(databaseProvider);

  return (db.select(
    db.threads,
  )..where((t) => t.id.equals(threadId))).watchSingleOrNull();
});

/// Typing indicator state
final threadTypingProvider = StreamProvider.family<bool, String>((
  ref,
  threadId,
) {
  final db = ref.watch(databaseProvider);

  return (db.select(db.threads)..where((t) => t.id.equals(threadId)))
      .watchSingleOrNull()
      .map((thread) => thread?.isTyping ?? false);
});
