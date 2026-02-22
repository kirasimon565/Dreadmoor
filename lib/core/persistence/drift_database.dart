import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'drift_database.g.dart';

@DriftDatabase(tables: [Players, Messages, Threads, StoryState, Episodes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

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
            // Example:
            // await m.addColumn(messages, messages.isSecret);
          }
        },
      );

  static Future<void> init() async {
    final db = AppDatabase();
    await db.customSelect('SELECT 1').get();
    await db.close();
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

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'dreadmore.sqlite'));

    return NativeDatabase.createInBackground(
      file,
      logStatements: false,
    );
  });
}
