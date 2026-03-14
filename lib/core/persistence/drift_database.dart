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
          if (from < 8) await m.createTable(characterPhotos);
          if (from < 9) await m.createTable(threadMembers);
        },
      );

  // ── INIT ─────────────────────────────────────────────────────────────────
  // Called once from main.dart before runApp().
  // Always ensures the 'player' character row exists so the Profile screen
  // never hits "File not found" regardless of game-start state.
  static Future<void> init() async {
    await instance.customSelect('SELECT 1').get();
    await instance._ensurePlayerCharacter(); // ← FIX: always seed on cold start
  }

  /// Guarantees a 'player' Character row exists. Safe to call on every launch
  /// because insertOnConflictUpdate is a no-op when the row already exists.
  Future<void> _ensurePlayerCharacter() async {
    await into(characters).insertOnConflictUpdate(
      CharactersCompanion.insert(
        id: 'player',
        name: 'Investigator',
        bio: const Value('Active Case Lead'),
        avatarPath: const Value('assets/characters/player_default.png'),
        phoneNumber: '+1 (555) 000-0000',
      ),
    );
  }

  // ── DATA INITIALIZATION ───────────────────────────────────────────────────
  // Called from WelcomeScreen when the player taps "Start Game".
  // Guards on storyNodes count (not player existence) so that a
  // resetAllProgress() → restart correctly re-imports the JSON scenes.
  Future<void> initializeDefaultData() async {
    // 1. Player row (system state)
    final existingPlayer = await (select(players)..limit(1)).getSingleOrNull();
    if (existingPlayer == null) {
      await into(players).insert(
        PlayersCompanion.insert(
          name: 'Investigator',
          gender: 'Unknown',
          phoneNumber: const Value('+1 (555) 000-0000'),
        ),
      );
    }

    // 2. Player character row — also handled by _ensurePlayerCharacter() on
    //    init(), but repeated here with insertOnConflictUpdate so it is a
    //    guaranteed no-op when already present.
    await _ensurePlayerCharacter();

    // 3. Import JSON scenes.
    //    ← FIX: guard on storyNodes count, NOT on player existence.
    //    This means resetAllProgress() + Start Game always re-imports.
    final nodeCount =
        await (select(storyNodes)..limit(1)).getSingleOrNull();
    if (nodeCount == null) {
      try {
        final loader = ScriptLoader(this);
        await loader.importEpisode('ep01');
      } catch (e) {
        print('Dreadmoor Engine Error: Failed to import JSON scenes: $e');
      }
    }
  }

  // ── NARRATIVE & GALLERY DAOs ──────────────────────────────────────────────

  Future<List<CharacterPhoto>> getCharacterGallery(String charId) {
    return (select(characterPhotos)
          ..where((t) => t.characterId.equals(charId)))
        .get();
  }

  Future<StoryNode?> getNextNode(String? nodeId) async {
    if (nodeId == null || nodeId.isEmpty) return null;
    return (select(storyNodes)..where((t) => t.id.equals(nodeId)))
        .getSingleOrNull();
  }

  Stream<List<Message>> watchChatMessages(String threadId) {
    return (select(messages)
          ..where((t) => t.threadId.equals(threadId))
          ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
        .watch();
  }

  Future<void> updateStoryFlag(String key,
      {bool? bVal, int? iVal, String? sVal}) async {
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

  // ── RESET ─────────────────────────────────────────────────────────────────

  Future<void> resetAllProgress() async {
    await batch((b) {
      b.deleteAll(players);
      b.deleteAll(messages);
      b.deleteAll(threads);
      b.deleteAll(threadMembers);
      b.deleteAll(storyState);
      b.deleteAll(episodes);
      b.deleteAll(storyNodes);   // ← cleared here, re-imported on next Start Game
      b.deleteAll(characterPhotos);
      // Note: characters table is NOT wiped so the player profile survives reset.
      // _ensurePlayerCharacter() also re-seeds it on the next cold start.
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
