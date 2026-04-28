import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';

/// Dreadmoor Episode 1 Timeline:
/// Sunday, June 12th, 2016.
/// Start: 23:42 (11:42 PM)
/// (23 * 60) + 42 = 1422 minutes from start of Sunday.
const int _initialGameTimeMinutes = 1422;
const String _gameClockKey = 'game_clock_minutes';

class GameClockNotifier extends Notifier<int> {
  @override
  int build() {
    _loadFromDb();
    return _initialGameTimeMinutes;
  }

  /// Syncs the clock with the Drift database on boot
  Future<void> _loadFromDb() async {
    final db = ref.read(databaseProvider);
    
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
    final db = ref.read(databaseProvider);
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

final gameClockProvider = NotifierProvider<GameClockNotifier, int>(GameClockNotifier.new);

final gameClockStringProvider = Provider<String>((ref) {
  final totalMinutes = ref.watch(gameClockProvider);
  return formatGameTime(totalMinutes);
});

// --------------------------------------------------
// DATE/TIME LOGIC & FORMATTING
// --------------------------------------------------

final DateTime _baseDate = DateTime(2016, 6, 12, 23, 42);

DateTime getGameDateTime(int totalMinutes) {
  return _baseDate.add(
    Duration(minutes: totalMinutes - 1422),
  );
}

String formatGameTimeFromDate(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String formatGameDateFullFromDate(DateTime dt) {
  final weekday = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][dt.weekday - 1];
  final month = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ][dt.month - 1];

  return '$weekday, ${dt.day} $month ${dt.year}';
}

/// Returns HH:MM format (legacy wrapper)
String formatGameTime(int totalMinutes) {
  return formatGameTimeFromDate(getGameDateTime(totalMinutes));
}

/// Returns the day (legacy wrapper)
String getGameDay(int totalMinutes) {
  final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return days[getGameDateTime(totalMinutes).weekday - 1];
}

/// Formats the date seen in the Messenger top bar or OS header (legacy wrapper)
String formatGameDateFull(int totalMinutes) {
  final dt = getGameDateTime(totalMinutes);
  final timeStr = formatGameTimeFromDate(dt);
  final dayStr = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][dt.weekday - 1];
  
  final monthStr = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ][dt.month - 1];
  
  return '$timeStr $dayStr, $monthStr ${dt.day}';
}

// --------------------------------------------------
// REAL-TIME CLOCK PROVIDER
//
// Emits DateTime.now() every second.
// Used by DreadmoorStatusBar and AppsScreen for live display.
// Separate from gameClockProvider which tracks fictional in-game time.
// --------------------------------------------------

final clockProvider = StreamProvider<DateTime>((ref) async* {
  while (true) {
    yield DateTime.now();
    await Future.delayed(const Duration(seconds: 1));
  }
});
