import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';

class MinigameDao {
  final AppDatabase _db;

  MinigameDao(this._db);

  Future<MinigameResult?> getResult(String minigameId) async {
    return (_db.select(_db.minigameResults)
          ..where((t) => t.minigameId.equals(minigameId)))
        .getSingleOrNull();
  }

  Future<void> saveResult(MinigameResult result) async {
    await _db.into(_db.minigameResults).insertOnConflictUpdate(result);
  }
}

final minigameDaoProvider = Provider<MinigameDao>((ref) {
  return MinigameDao(ref.watch(databaseProvider));
});
