import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/persistence/drift_database.dart';
import 'game_state.dart';

class EpisodeWithProgress {
  final Episode episode;
  final double progress; // 0.0 → 1.0

  EpisodeWithProgress({
    required this.episode,
    required this.progress,
  });
}

final episodesProvider = StreamProvider<List<EpisodeWithProgress>>((ref) {
  final db = ref.watch(databaseProvider);

  return db.select(db.episodes).watch().map((rows) {
    return rows.map((ep) {
      final progress = (ep.progress ?? 0) / 100.0;
      return EpisodeWithProgress(episode: ep, progress: progress);
    }).toList()
      ..sort((a, b) => a.episode.id.compareTo(b.episode.id));
  });
});
