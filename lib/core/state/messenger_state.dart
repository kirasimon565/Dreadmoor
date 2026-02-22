import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../core/persistence/drift_database.dart';
import 'game_state.dart';

class ThreadWithLastMessage {
  final Thread thread;
  final Message? lastMessage;

  ThreadWithLastMessage(this.thread, this.lastMessage);
}

final threadsStreamProvider = StreamProvider<List<ThreadWithLastMessage>>((ref) {
  final db = ref.watch(databaseProvider);

  return (db.select(db.threads)
        ..where((t) => t.isSecret.equals(false))
        ..orderBy([(t) => OrderingTerm(expression: t.lastMessageId, mode: OrderingMode.desc)]))
      .join([
        leftOuterJoin(db.messages, db.messages.id.equalsExp(db.threads.lastMessageId)),
      ])
      .watch()
      .map((rows) {
        return rows.map((row) {
          return ThreadWithLastMessage(
            row.readTable(db.threads),
            row.readTableOrNull(db.messages),
          );
        }).toList();
      });
});

final messagesStreamProvider = StreamProvider.family<List<Message>, String>((ref, threadId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.messages)
        ..where((tbl) => tbl.threadId.equals(threadId))
        ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]))
      .watch();
});

final threadProvider = StreamProvider.family<Thread?, String>((ref, threadId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.threads)..where((tbl) => tbl.id.equals(threadId))).watchSingleOrNull();
});
