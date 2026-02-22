import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'drift_database.g.dart';

@DriftDatabase(tables: [Players, Messages, Threads, StoryState, Episodes])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  // ✅ Singleton instance — one connection shared across entire app
  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from == 1) {
            // Future migrations here
          }
        },
      );

  /// Warm up the singleton connection (safe to call multiple times).
  /// Call this once in main() before runApp.
  static Future<void> init() async {
    await instance.customSelect('SELECT 1').get();
  }

  Future<void> resetAllProgress() async {
    await batch((b) {
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

// --------------------
// SINGLETON CONNECTION
// --------------------

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'dreadmore.sqlite'));

    return NativeDatabase(
      file,
      logStatements: false,
    );
  });
}
