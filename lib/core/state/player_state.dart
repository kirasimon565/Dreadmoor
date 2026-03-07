import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persistence/drift_database.dart';
import 'game_state.dart';

/// Live player stream (updates if DB changes)
final playerStreamProvider = StreamProvider<Player?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.players).watchSingleOrNull();
});

/// Used on startup to check if a player exists
final playerExistsProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final player = await (db.select(db.players)..limit(1)).getSingleOrNull();
  return player != null;
});

class PlayerController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  PlayerController(this.ref) : super(const AsyncValue.data(null));

  Future<void> createPlayer(String name, String gender) async {
    state = const AsyncValue.loading();

    try {
      final db = ref.read(databaseProvider);

      final existing =
          await (db.select(db.players)..limit(1)).getSingleOrNull();

      if (existing != null) {
        state = const AsyncValue.data(null);
        return;
      }

      final id = await db.into(db.players).insert(
            PlayersCompanion.insert(
              name: name,
              gender: gender,
            ),
          );

      final created =
          await (db.select(db.players)..where((p) => p.id.equals(id)))
              .getSingle();

      /// Update in-memory state instantly
      ref.read(playerStateProvider.notifier).state = created;

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final playerControllerProvider =
    StateNotifierProvider<PlayerController, AsyncValue<void>>((ref) {
  return PlayerController(ref);
});
