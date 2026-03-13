import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'drift_database.g.dart';

@DriftDatabase(tables: [
  Players, 
  Characters, 
  Threads, 
  Messages, 
  Notifications, 
  StoryState, 
  Episodes, 
  StoryNodes
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 7) {
        // Drop and recreate to ensure Node-Based architecture is clean
        await m.createTable(storyNodes);
        try {
          await m.addColumn(storyState, storyState.intValue);
        } catch (e) {
          // Column might already exist in some dev versions
        }
      }
    },
  );

  static Future<void> init() async {
    await instance.customSelect('SELECT 1').get();
  }

  // ---------------------------
  // NARRATIVE DAOs (Data Access)
  // ---------------------------

  Future<StoryNode?> getNextNode(String? nodeId) async {
    if (nodeId == null) return null;
    return (select(storyNodes)..where((t) => t.id.equals(nodeId))).getSingleOrNull();
  }

  Stream<List<Message>> watchChatMessages(String threadId) {
    return (select(messages)
          ..where((t) => t.threadId.equals(threadId))
          ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
        .watch();
  }

  Future<void> updateStoryFlag(String key, {bool? bVal, int? iVal, String? sVal}) async {
    await into(storyState).insertOnConflictUpdate(
      StoryStateCompanion(
        key: Value(key),
        value: Value(bVal ?? false),
        intValue: Value(iVal ?? 0),
        stringValue: Value(sVal),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------------------------
  // RESET LOGIC
  // ---------------------------

  Future<void> resetAllProgress() async {
    await batch((b) {
      b.deleteAll(players);
      b.deleteAll(messages);
      b.deleteAll(threads);
      b.deleteAll(storyState);
      b.deleteAll(episodes);
      b.deleteAll(storyNodes);
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'dreadmoor_v7.sqlite'));
    return NativeDatabase(file, logStatements: false);
  });
}
