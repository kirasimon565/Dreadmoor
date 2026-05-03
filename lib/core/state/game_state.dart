import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:dreadmoor/core/persistence/drift_database.dart';
import '../scripting/script_loader.dart';
import '../scheduler/global_scheduler.dart';
import 'scheduler_state.dart';

// ---------------------------
// DATABASE
// ---------------------------
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

// ---------------------------
// PLAYER STATE
// ---------------------------
final playerProvider = FutureProvider<Player?>((ref) async {
  final db = ref.read(databaseProvider);
  return (db.select(db.players)..limit(1)).getSingleOrNull();
});

class PlayerStateNotifier extends Notifier<Player?> {
  @override
  Player? build() => null;
  void setPlayer(Player? player) => state = player;
}

final playerStateProvider =
    NotifierProvider<PlayerStateNotifier, Player?>(
        PlayerStateNotifier.new);

// ---------------------------
// SCRIPT SYSTEM
// ---------------------------
final scriptLoaderProvider = Provider<ScriptLoader>((ref) {
  final db = ref.watch(databaseProvider);
  return ScriptLoader(db);
});

// ---------------------------
// NARRATIVE STATE
// ---------------------------

class CurrentEpisodeIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setId(String? id) => state = id;
}

final currentEpisodeIdProvider =
    NotifierProvider<CurrentEpisodeIdNotifier, String?>(
        CurrentEpisodeIdNotifier.new);

// ---------------------------
// THREAD / CHAT STATE
// ---------------------------

class IsChoiceOverlayExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setExpanded(bool expanded) => state = expanded;
}

final isChoiceOverlayExpandedProvider =
    NotifierProvider<IsChoiceOverlayExpandedNotifier, bool>(
        IsChoiceOverlayExpandedNotifier.new);

// ---------------------------
// STORY FLAGS
// ---------------------------
final gameFlagsProvider = StreamProvider<Map<String, bool>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.storyState).watch().map((rows) {
    return {for (var row in rows) row.key: row.value};
  });
});

// ---------------------------
// SCHEDULER & NAVIGATION STATE
// ---------------------------
// NOTE: activeNodeIdProvider, activeThreadIdProvider, isSchedulerPausedProvider,
// waitingForChoiceProvider, and waitingForPuzzleProvider are now defined in
// scheduler_state.dart as derived selectors from the consolidated SchedulerState.
// They maintain the same interface — existing widget code works unchanged.

// ---------------------------
// NAVIGATION
// ---------------------------
class DreadmoorNavNotifier extends Notifier<String> {
  @override
  String build() => '/messenger';

  void navigateToNews(String nodeId) => state = '/browser';
  void navigateToChat() => state = '/messenger';
  void navigateToPhone() => state = '/phone';
}

final navigationProvider =
    NotifierProvider<DreadmoorNavNotifier, String>(
        DreadmoorNavNotifier.new);

// ---------------------------
// THEME PREFERENCES
// ---------------------------
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.dark;
  }

  Future<void> _loadTheme() async {
    final db = ref.read(databaseProvider);
    final row = await (db.select(db.storyState)
          ..where((t) => t.key.equals('theme_mode')))
        .getSingleOrNull();
    if (row?.stringValue != null) {
      state =
          row!.stringValue == 'light' ? ThemeMode.light : ThemeMode.dark;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final db = ref.read(databaseProvider);
    await db.into(db.storyState).insertOnConflictUpdate(
      StoryStateCompanion(
        key: const drift.Value('theme_mode'),
        stringValue:
            drift.Value(mode == ThemeMode.light ? 'light' : 'dark'),
      ),
    );
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(
        ThemeModeNotifier.new);

// ---------------------------
// GLOBAL SCHEDULER
// ---------------------------
final globalSchedulerProvider = Provider<GlobalScheduler>((ref) {
  final scheduler = GlobalScheduler(ref);
  ref.onDispose(() => scheduler.dispose());
  return scheduler;
});
