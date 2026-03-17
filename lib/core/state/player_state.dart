import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:drift/drift.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'game_state.dart';

/// Live player stream: Rebuilds UI automatically if the player updates their name/profile
final playerStreamProvider = StreamProvider<Player?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.players).watchSingleOrNull();
});

/// Used by the Splash/Login screen to determine if we need to show the "Create Character" sequence
final playerExistsProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final player = await (db.select(db.players)..limit(1)).getSingleOrNull();
  return player != null;
});

class PlayerController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createPlayer(String name, String gender) async {
    state = const AsyncValue.loading();

    try {
      final db = ref.read(databaseProvider);

      // Prevent duplicate player creation
      final existing = await (db.select(db.players)..limit(1)).getSingleOrNull();
      if (existing != null) {
        ref.read(playerStateProvider.notifier).state = existing;
        state = const AsyncValue.data(null);
        return;
      }

      // Insert new player into Drift
      final id = await db.into(db.players).insert(
        PlayersCompanion.insert(
          name: name, 
          gender: gender,
          createdAt: Value(DateTime.now()),
        ),
      );

      final created = await (db.select(db.players)..where((p) => p.id.equals(id))).getSingle();

      // Sync with in-memory state for immediate use in GlobalScheduler
      ref.read(playerStateProvider.notifier).state = created;

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final playerControllerProvider = AsyncNotifierProvider<PlayerController, void>(PlayerController.new);
