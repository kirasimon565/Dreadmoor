// lib/features/minigame/tracecore/persistence/tracecore_dao.dart

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import '../models/tracecore_session.dart';

class TracecoreDao {
  final AppDatabase _db;
  TracecoreDao(this._db);

  static const _keyPrefix = 'tracecore_session_';

  String _key(String minigameId) => '$_keyPrefix$minigameId';

  Future<TracecoreSession?> loadSession(String minigameId) async {
    final row = await (_db.select(_db.storyState)
          ..where((t) => t.key.equals(_key(minigameId))))
        .getSingleOrNull();
    if (row?.stringValue == null) return null;
    try {
      return TracecoreSession.fromJson(
          jsonDecode(row!.stringValue!) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(String minigameId, TracecoreSession session) async {
    await _db.into(_db.storyState).insertOnConflictUpdate(
      StoryStateCompanion(
        key:         Value(_key(minigameId)),
        value:       const Value(true),
        stringValue: Value(jsonEncode(session.toJson())),
        updatedAt:   Value(DateTime.now()),
      ),
    );
  }

  Future<void> clearSession(String minigameId) async {
    await (_db.delete(_db.storyState)
          ..where((t) => t.key.equals(_key(minigameId))))
        .go();
  }

  Future<bool> isTutorialSeen() async {
    final row = await (_db.select(_db.storyState)
          ..where((t) => t.key.equals('tracecore_tutorial_seen')))
        .getSingleOrNull();
    return row?.value ?? false;
  }

  Future<void> markTutorialSeen() async {
    await _db.into(_db.storyState).insertOnConflictUpdate(
      StoryStateCompanion(
        key:       const Value('tracecore_tutorial_seen'),
        value:     const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
