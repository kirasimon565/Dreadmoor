import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'game_state.dart';

class EpisodeWithProgress {
  final Episode episode;
  final double progress; // 0.0 → 1.0

  EpisodeWithProgress({required this.episode, required this.progress});
}

/// Stream of all episodes with progress tracked via the Node System
final episodesProvider = StreamProvider<List<EpisodeWithProgress>>((ref) {
  final db = ref.watch(databaseProvider);

  return db.select(db.episodes).watch().map((rows) {
    final episodes = rows.map((ep) {
      // Logic: Progress is now based on version/complexity of nodes completed
      final progress = (ep.progress / 100).clamp(0.0, 1.0);
      return EpisodeWithProgress(episode: ep, progress: progress);
    }).toList();

    // Sort: ep01, ep02, ep03...
    episodes.sort((a, b) => a.episode.id.compareTo(b.episode.id));
    return episodes;
  });
});
