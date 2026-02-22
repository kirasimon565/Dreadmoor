import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/persistence/drift_database.dart';
import '../scripting/script_loader.dart';
import '../scheduler/global_scheduler.dart';

// Singleton DB — always returns the same instance, never closes it
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

// Script Loader Provider
final scriptLoaderProvider = Provider<ScriptLoader>((ref) => ScriptLoader());

// Core Game State
final currentEpisodeIdProvider = StateProvider<String?>((ref) => null);
final activeThreadIdProvider = StateProvider<String?>((ref) => null);
final isSchedulerPausedProvider = StateProvider<bool>((ref) => false);
final waitingForChoiceProvider = StateProvider<bool>((ref) => false);

// Per-thread read markers
final lastReadMessageIdProvider = StateProvider.family<int?, String>((ref, threadId) => null);

// Cooldowns per thread (anti-spam illusion)
final threadCooldownProvider = StateProvider.family<DateTime?, String>((ref, threadId) => null);

// Global flags (mirrors DB story_state)
final gameFlagsProvider = StateProvider<Map<String, bool>>((ref) => {});

// Scheduler (singleton instance)
final globalSchedulerProvider = Provider<GlobalScheduler>((ref) {
  final scheduler = GlobalScheduler(ref);
  ref.onDispose(scheduler.dispose);
  return scheduler;
});
