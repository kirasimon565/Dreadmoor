import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:dreadmoor/core/persistence/drift_database.dart';
import '../scripting/script_loader.dart';
import '../scheduler/global_scheduler.dart';

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

final playerStateProvider = StateProvider<Player?>((ref) => null);

// ---------------------------
// SCRIPT SYSTEM (Refactored for Obsidian)
// ---------------------------
final scriptLoaderProvider = Provider<ScriptLoader>((ref) {
  final db = ref.watch(databaseProvider);
  return ScriptLoader(db); // Now accepts DB for Obsidian ingestion
});

// ---------------------------
// NARRATIVE STATE (Node-Based)
// ---------------------------

/// Current Node ID being executed (e.g., 'SCENE_2_START')
/// This replaces SceneIndex and EventIndex entirely.
final activeNodeIdProvider = StateProvider<String?>((ref) => null);

/// Current episode ID
final currentEpisodeIdProvider = StateProvider<String?>((ref) => null);

// ---------------------------
// THREAD / CHAT STATE
// ---------------------------
final activeThreadIdProvider = StateProvider<String?>((ref) => null);

// ---------------------------
// STORY FLAGS (Refactored for Relational State)
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
final isSchedulerPausedProvider = StateProvider<bool>((ref) => false);
final waitingForChoiceProvider = StateProvider<bool>((ref) => false);
final waitingForPuzzleProvider = StateProvider<bool>((ref) => false);

/// Controls navigation between OS Apps (Messenger, Browser, Phone)
final navigationProvider = StateNotifierProvider<DreadmoorNavNotifier, String>((ref) {
  return DreadmoorNavNotifier();
});

class DreadmoorNavNotifier extends StateNotifier<String> {
  DreadmoorNavNotifier() : super('/messenger');

  void navigateToNews(String nodeId) => state = '/browser';
  void navigateToChat() => state = '/messenger';
  void navigateToPhone() => state = '/phone';
}

// ---------------------------
// THEME PREFERENCES
// ---------------------------

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;

  ThemeModeNotifier(this._ref) : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final db = _ref.read(databaseProvider);
    final row = await (db.select(db.storyState)..where((t) => t.key.equals('theme_mode'))).getSingleOrNull();
    if (row != null && row.stringValue != null) {
      state = row.stringValue == 'light' ? ThemeMode.light : ThemeMode.dark;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final db = _ref.read(databaseProvider);
    await db.into(db.storyState).insertOnConflictUpdate(
      StoryStateCompanion(
        key: const drift.Value('theme_mode'),
        stringValue: drift.Value(mode == ThemeMode.light ? 'light' : 'dark'),
      ),
    );
  }
}

// ---------------------------
// GLOBAL SCHEDULER
// ---------------------------
final globalSchedulerProvider = Provider<GlobalScheduler>((ref) {
  final scheduler = GlobalScheduler(ref);
  // ref.onDispose(() => scheduler.dispose());
  return scheduler;
});
