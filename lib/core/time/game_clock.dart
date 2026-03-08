import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The game clock states. Starts at 23:42 Sunday, March 8
/// Stored internally as minutes since 00:00 Sunday, March 8
/// (23 * 60) + 42 = 1422
final _initialGameTimeMinutes = 1422;

class GameClockNotifier extends StateNotifier<int> {
  GameClockNotifier() : super(_initialGameTimeMinutes);

  /// Advances the game clock by [minutes]
  /// IMPORTANT: This should ONLY be called by story events or the scheduler.
  void advanceTime(int minutes) {
    if (minutes <= 0) return;
    state = state + minutes;
  }

  /// Sets the game clock to a specific time (minutes from Sunday 00:00)
  void setTime(int totalMinutes) {
    state = totalMinutes;
  }
}

/// The global provider for the game clock.
final gameClockProvider = StateNotifierProvider<GameClockNotifier, int>((ref) {
  return GameClockNotifier();
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
