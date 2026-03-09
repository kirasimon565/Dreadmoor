import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import '../scripting/script_loader.dart';
import '../scheduler/global_scheduler.dart';

/// ---------------------------
/// DATABASE
/// ---------------------------

/// Singleton DB — always returns the same instance
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

/// ---------------------------
/// PLAYER STATE
/// ---------------------------

/// Loads player from DB on cold start
final playerProvider = FutureProvider<Player?>((ref) async {
  final db = ref.read(databaseProvider);
  return (db.select(db.players)..limit(1)).getSingleOrNull();
});

/// In-memory player state (router watches this)
final playerStateProvider = StateProvider<Player?>((ref) => null);

/// ---------------------------
/// SCRIPT SYSTEM
/// ---------------------------

final scriptLoaderProvider = Provider<ScriptLoader>((ref) {
  return ScriptLoader();
});

/// ---------------------------
/// EPISODE STATE
/// ---------------------------

/// Current episode being played
final currentEpisodeIdProvider = StateProvider<String?>((ref) => null);

/// Current scene index
final currentSceneIndexProvider = StateProvider<int>((ref) => 0);

/// Current event index inside scene
final currentEventIndexProvider = StateProvider<int>((ref) => 0);

/// ---------------------------
/// THREAD / CHAT STATE
/// ---------------------------

/// Active thread (chat screen)
final activeThreadIdProvider = StateProvider<String?>((ref) => null);

/// Per-thread last read marker
final lastReadMessageIdProvider = StateProvider.family<int?, String>(
  (ref, threadId) => null,
);

/// Fake cooldown per thread (anti-spam illusion)
final threadCooldownProvider = StateProvider.family<DateTime?, String>(
  (ref, threadId) => null,
);

/// ---------------------------
/// STORY FLAGS
/// ---------------------------

/// Global story flags (mirrors DB story_state)
final gameFlagsProvider = StreamProvider<Map<String, bool>>((ref) {
  final db = ref.read(databaseProvider);
  return db.select(db.storyState).watch().map((rows) {
    return {for (var row in rows) row.key: row.value};
  });
});

/// ---------------------------
/// SCHEDULER STATE
/// ---------------------------

/// Scheduler paused
final isSchedulerPausedProvider = StateProvider<bool>((ref) => false);

/// Waiting for player choice
final waitingForChoiceProvider = StateProvider<bool>((ref) => false);

/// Waiting for puzzle completion
final waitingForPuzzleProvider = StateProvider<bool>((ref) => false);

/// ---------------------------
/// GLOBAL SCHEDULER
/// ---------------------------

final globalSchedulerProvider = Provider<GlobalScheduler>((ref) {
  final scheduler = GlobalScheduler(ref);

  ref.onDispose(() {
    scheduler.dispose();
  });

  return scheduler;
});
