import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';

/// The game clock states. Starts at 23:42 Sunday, March 8
/// Stored internally as minutes since 00:00 Sunday, March 8
/// (23 * 60) + 42 = 1422
final _initialGameTimeMinutes = 1422;
const _gameClockKey = 'game_clock_minutes';

class GameClockNotifier extends StateNotifier<int> {
  final Ref _ref;

  GameClockNotifier(this._ref) : super(_initialGameTimeMinutes) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final db = _ref.read(databaseProvider);
    final row = await (db.select(db.storyState)..where((t) => t.key.equals(_gameClockKey))).getSingleOrNull();

    if (row != null && row.stringValue != null) {
      final savedTime = int.tryParse(row.stringValue!);
      if (savedTime != null) {
        state = savedTime;
      }
    } else {
      // First boot: create the row automatically with the default value
      await _saveToDb(_initialGameTimeMinutes);
    }
  }

  Future<void> _saveToDb(int time) async {
    final db = _ref.read(databaseProvider);
    await db.into(db.storyState).insertOnConflictUpdate(
      StoryStateCompanion(
        key: Value(_gameClockKey),
        value: Value(true),
        stringValue: Value(time.toString()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Advances the game clock by [minutes]
  /// IMPORTANT: This should ONLY be called by story events or the scheduler.
  void advanceTime(int minutes) {
    if (minutes <= 0) return;
    state = state + minutes;
    _saveToDb(state);
  }

  /// Sets the game clock to a specific time (minutes from Sunday 00:00)
  void setTime(int totalMinutes) {
    state = totalMinutes;
    _saveToDb(state);
  }
}

/// The global provider for the game clock.
final gameClockProvider = StateNotifierProvider<GameClockNotifier, int>((ref) {
  return GameClockNotifier(ref);
});

/// A helper provider to format the current game time as a string.
final gameClockStringProvider = Provider<String>((ref) {
  final totalMinutes = ref.watch(gameClockProvider);
  return formatGameTime(totalMinutes);
});

/// Helper to format minutes into HH:MM
String formatGameTime(int totalMinutes) {
  final dayMinutes = totalMinutes % (24 * 60);
  final hours = dayMinutes ~/ 60;
  final minutes = dayMinutes % 60;

  final hStr = hours.toString().padLeft(2, '0');
  final mStr = minutes.toString().padLeft(2, '0');
  return '$hStr:$mStr';
}

/// Helper to get the day of the week
String getGameDay(int totalMinutes) {
  final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  final dayIndex = (totalMinutes ~/ (24 * 60)) % 7;
  return days[dayIndex];
}

/// Helper to format full date string
String formatGameDateFull(int totalMinutes) {
  final timeStr = formatGameTime(totalMinutes);
  final dayStr = getGameDay(totalMinutes);
  // We hardcode March 8 as the start day (Sunday).
  // We can calculate the exact date if needed, but for Episode 1 this is sufficient.
  final dayOffset = (totalMinutes ~/ (24 * 60));
  final dateNum = 8 + dayOffset;
  return '$timeStr $dayStr, March $dateNum';
}
