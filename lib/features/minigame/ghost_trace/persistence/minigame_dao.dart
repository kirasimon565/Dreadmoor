// lib/features/minigame/ghost_trace/persistence/minigame_dao.dart

import 'package:drift/drift.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';

class MinigameDao {
  final AppDatabase _db;
  MinigameDao(this._db);

  Future<MinigameResult?> getResult(String minigameId) {
    return (_db.select(_db.minigameResults)
          ..where((t) => t.minigameId.equals(minigameId)))
        .getSingleOrNull();
  }

  Future<void> upsertResult(MinigameResultsCompanion entry) {
    return _db.into(_db.minigameResults).insertOnConflictUpdate(entry);
  }

  Future<bool> isCoolingDown(String minigameId) async {
    final row = await getResult(minigameId);
    if (row == null || row.cooldownUntil == null) return false;
    return DateTime.now().isBefore(row.cooldownUntil!);
  }

  Future<Duration?> cooldownRemaining(String minigameId) async {
    final row = await getResult(minigameId);
    if (row?.cooldownUntil == null) return null;
    final remaining = row!.cooldownUntil!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> recordAttempt({
    required String minigameId,
    required bool won,
    required int heartsRemaining,
  }) async {
    final existing = await getResult(minigameId);
    final attempts = (existing?.attemptsCount ?? 0) + 1;
    DateTime? cooldown;

    if (!won && heartsRemaining <= 0) {
      cooldown = DateTime.now().add(
        const Duration(minutes: 10),
      );
    }

    await upsertResult(
      MinigameResultsCompanion(
        id:              Value(minigameId),
        minigameId:      Value(minigameId),
        completed:       Value(won),
        attemptsCount:   Value(attempts),
        heartsRemaining: Value(heartsRemaining),
        cooldownUntil:   Value(cooldown),
        completedAt:     won ? Value(DateTime.now()) : const Value(null),
      ),
    );
  }
}
