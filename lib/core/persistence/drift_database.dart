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
  CharacterGallery, // Added table
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
  int get schemaVersion => 8; // Incremented for Gallery table

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 8) {
        await m.createTable(characterGallery);
      }
    },
  );

  static Future<void> init() async {
    await instance.customSelect('SELECT 1').get();
  }

  // --- GALLERY ACCESSOR ---
  
  /// Fetches all gallery photos for a specific character ordered by priority
  Stream<List<CharacterGalleryData>> watchCharacterGallery(String characterId) {
    return (select(characterGallery)
      ..where((t) => t.characterId.equals(characterId))
      ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
      .watch();
  }

  // --- STORY LOGIC ---

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

  Future<void> resetAllProgress() async {
    await batch((b) {
      b.deleteAll(players);
      b.deleteAll(messages);
      b.deleteAll(threads);
      b.deleteAll(storyState);
      b.deleteAll(episodes);
      b.deleteAll(storyNodes);
      b.deleteAll(characterGallery);
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'dreadmoor_v8.sqlite'));
    return NativeDatabase(file, logStatements: false);
  });
}
