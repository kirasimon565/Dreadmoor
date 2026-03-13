import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';

/// Dreadmoor Episode 1 Timeline:
/// Sunday, March 8th.
/// Start: 23:42 (11:42 PM)
/// (23 * 60) + 42 = 1422 minutes from start of Sunday.
const int _initialGameTimeMinutes = 1422;
const String _gameClockKey = 'game_clock_minutes';

class GameClockNotifier extends StateNotifier<int> {
  final Ref _ref;

  GameClockNotifier(this._ref) : super(_initialGameTimeMinutes) {
    _loadFromDb();
  }

  /// Syncs the clock with the Drift database on boot
  Future<void> _loadFromDb() async {
    final db = _ref.read(databaseProvider);
    
    // Using the refactored intValue column for better performance
    final row = await (db.select(db.storyState)
          ..where((t) => t.key.equals(_gameClockKey)))
        .getSingleOrNull();

    if (row != null) {
      state = row.intValue;
    } else {
      // First boot: Initialize with the disappearance night start time
      await _saveToDb(_initialGameTimeMinutes);
    }
  }

  /// Persists time to the StoryState table
  Future<void> _saveToDb(int time) async {
    final db = _ref.read(databaseProvider);
    await db.into(db.storyState).insertOnConflictUpdate(
      StoryStateCompanion(
        key: const Value(_gameClockKey),
        value: const Value(true), // active flag
        intValue: Value(time),    // actual time data
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Advances the clock.
  /// The GlobalScheduler calls this for every message sent.
  void advanceTime(int minutes) {
    if (minutes <= 0) return;
    state = state + minutes;
    _saveToDb(state);
  }

  /// Jump to a specific time (useful for time-skipping scenes)
  void setTime(int totalMinutes) {
    state = totalMinutes;
    _saveToDb(state);
  }
}

// --------------------------------------------------
// PROVIDERS
// --------------------------------------------------

final gameClockProvider = StateNotifierProvider<GameClockNotifier, int>((ref) {
  return GameClockNotifier(ref);
});

final gameClockStringProvider = Provider<String>((ref) {
  final totalMinutes = ref.watch(gameClockProvider);
  return formatGameTime(totalMinutes);
});

// --------------------------------------------------
// FORMATTING HELPERS (FIXES MIDNIGHT LOGIC)
// --------------------------------------------------

/// Returns HH:MM format
String formatGameTime(int totalMinutes) {
  final dayMinutes = totalMinutes % (24 * 60);
  final hours = dayMinutes ~/ 60;
  final minutes = dayMinutes % 60;

  final hStr = hours.toString().padLeft(2, '0');
  final mStr = minutes.toString().padLeft(2, '0');
  return '$hStr:$mStr';
}

/// Returns the day. Since Episode 1 starts at 23:42 Sunday,
/// the clock will roll over to Monday fairly quickly.
String getGameDay(int totalMinutes) {
  final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  final dayIndex = (totalMinutes ~/ (24 * 60)) % 7;
  return days[dayIndex];
}

/// Formats the date seen in the Messenger top bar or OS header
String formatGameDateFull(int totalMinutes) {
  final timeStr = formatGameTime(totalMinutes);
  final dayStr = getGameDay(totalMinutes);
  
  // Start date is March 8 (Sunday)
  final dayOffset = (totalMinutes ~/ (24 * 60));
  final dateNum = 8 + dayOffset;
  
  return '$timeStr $dayStr, March $dateNum';
}
