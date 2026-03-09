import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'drift_database.g.dart';

@DriftDatabase(tables: [Players, Characters, Threads, Messages, Notifications, StoryState, Episodes])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  // ---------------------------
  // SINGLETON
  // ---------------------------

  static AppDatabase? _instance;

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  // ---------------------------
  // SCHEMA VERSION
  // ---------------------------

  @override
  int get schemaVersion => 6;

  // ---------------------------
  // MIGRATIONS
  // ---------------------------

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 6) {
        await m.createTable(notifications);
      }
    },
  );

  // ---------------------------
  // INIT
  // ---------------------------

  /// Warm-up database connection
  static Future<void> init() async {
    await instance.customSelect('SELECT 1').get();
  }

  // ---------------------------
  // RESET FUNCTIONS
  // ---------------------------

  Future<void> resetAllProgress() async {
    await batch((b) {
      b.deleteAll(players);
      b.deleteAll(messages);
      b.deleteAll(threads);
      b.deleteAll(storyState);
      b.deleteAll(episodes);
    });
  }

  Future<void> resetEpisode(String episodeId) async {
    await (delete(messages)..where((m) => m.threadId.like('$episodeId%'))).go();
    await (delete(threads)..where((t) => t.id.like('$episodeId%'))).go();
    await (delete(storyState)..where((s) => s.key.like('$episodeId%'))).go();
  }
}

// ---------------------------
// DATABASE CONNECTION
// ---------------------------

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();

    final file = File(p.join(dbFolder.path, 'dreadmoor.sqlite'));

    return NativeDatabase(file, logStatements: false);
  });
}
