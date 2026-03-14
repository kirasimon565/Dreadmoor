import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:dreadmoor/core/scripting/script_loader.dart';
import 'tables.dart';

part 'drift_database.g.dart';

@DriftDatabase(tables: [
  Players, 
  Characters, 
  CharacterPhotos, 
  Threads, 
  ThreadMembers,
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
  int get schemaVersion => 9; 

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 8) {
        await m.createTable(characterPhotos);
      }
      if (from < 9) {
        await m.createTable(threadMembers);
      }
    },
  );

  static Future<void> init() async {
    await instance.customSelect('SELECT 1').get();
  }

  /// ── DATA INITIALIZATION ──────────────────────────────────────────────
  /// This is the "Fuel Tank" for the app. It populates the player and
  /// the story nodes from JSON.
  Future<void> initializeDefaultData() async {
    final db = this;

    final existingPlayer = await (select(players)..limit(1)).getSingleOrNull();
    if (existingPlayer == null) {
      // 1. Insert into Players table (for system state)
      await into(players).insert(
        PlayersCompanion.insert(
          name: 'Investigator',
          gender: 'Unknown',
          phoneNumber: const Value('+1 (555) 000-0000'),
        ),
      );

      // 2. Insert into Characters table (Fixes "File Not Found" on Profile Screen)
      // JULES: Added phoneNumber parameter below to fix the build error.
      await db.into(db.characters).insertOnConflictUpdate(
        CharactersCompanion.insert(
          id: 'player',
          name: 'Investigator',
          bio: const Value('Active Case Lead'),
          avatarPath: const Value('assets/characters/player_default.png'),
          phoneNumber: '+1 (555) 000-0000', // Matches schema requirement
        ),
      );

      // 3. Load Episode 1 JSON scenes (Fixes "No Connections Found" in Messenger)
      try {
        final loader = ScriptLoader(db);
        await loader.importEpisode('ep01');
      } catch (e) {
        print("Dreadmoor Engine Error: Failed to import JSON scenes: $e");
      }
    }
  }

  // ---------------------------
  // NARRATIVE & GALLERY DAOs
  // ---------------------------

  Future<List<CharacterPhoto>> getCharacterGallery(String charId) {
    return (select(characterPhotos)..where((t) => t.characterId.equals(charId))).get();
  }

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
      b.deleteAll(characterPhotos);
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
