import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/persistence/drift_database.dart';
import '../scripting/script_loader.dart';
import '../scheduler/global_scheduler.dart';

// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// Script Loader Provider
final scriptLoaderProvider = Provider<ScriptLoader>((ref) => ScriptLoader());

// Game State Providers
final currentEpisodeIdProvider = StateProvider<String?>((ref) => null);
final activeThreadIdProvider = StateProvider<String?>((ref) => null);
final isSchedulerPausedProvider = StateProvider<bool>((ref) => false);
final waitingForChoiceProvider = StateProvider<bool>((ref) => false);

// Scheduler Provider
final globalSchedulerProvider = Provider<GlobalScheduler>((ref) {
  return GlobalScheduler(ref);
});
