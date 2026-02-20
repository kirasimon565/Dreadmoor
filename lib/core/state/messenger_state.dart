import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../core/persistence/drift_database.dart';
import '../../core/persistence/tables.dart';
import 'game_state.dart';

class ThreadWithLastMessage {
  final Thread thread;
  final Message? lastMessage;

  ThreadWithLastMessage(this.thread, this.lastMessage);
}

final threadsStreamProvider = StreamProvider<List<ThreadWithLastMessage>>((ref) {
  final db = ref.watch(databaseProvider);

  return db.select(db.threads).watch().asyncMap((threads) async {
    List<ThreadWithLastMessage> result = [];
    for (var t in threads) {
      Message? msg;
      if (t.lastMessageId != null) {
        msg = await (db.select(db.messages)..where((tbl) => tbl.id.equals(t.lastMessageId!))).getSingleOrNull();
      } else {
        msg = await (db.select(db.messages)
          ..where((tbl) => tbl.threadId.equals(t.id))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.timestamp, mode: OrderingMode.desc)])
          ..limit(1)
        ).getSingleOrNull();
      }
      result.add(ThreadWithLastMessage(t, msg));
    }
    return result;
  });
});

final messagesStreamProvider = StreamProvider.family<List<Message>, String>((ref, threadId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.messages)..where((tbl) => tbl.threadId.equals(threadId))..orderBy([(t) => OrderingTerm(expression: t.timestamp)])).watch();
});

final threadProvider = StreamProvider.family<Thread?, String>((ref, threadId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.threads)..where((tbl) => tbl.id.equals(threadId))).watchSingleOrNull();
});
