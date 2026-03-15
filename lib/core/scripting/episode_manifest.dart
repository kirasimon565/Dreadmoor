/// Defines every episode and its scene files.
/// To add a new episode, add one entry here — nothing else needs to change.
///
/// Usage:
///   EpisodeManifest.all          → all episodes
///   EpisodeManifest.get('ep02')  → single episode
class EpisodeManifest {
  final String id;
  final String title;
  final List<String> scenePaths;

  const EpisodeManifest._({
    required this.id,
    required this.title,
    required this.scenePaths,
  });

  // ── EPISODE REGISTRY ────────────────────────────────────────────────────
  // Add new episodes here. That's the only change required for ep02, ep03...

  static const List<EpisodeManifest> all = [
    EpisodeManifest._(
      id: 'ep01',
      title: 'Episode 1: The Disappearance',
      scenePaths: [
        'assets/story/ep01/scene_01.json',
        'assets/story/ep01/scene_02.json',
        'assets/story/ep01/scene_03.json',
        'assets/story/ep01/scene_04.json',
        'assets/story/ep01/scene_05.json',
        'assets/story/ep01/scene_06.json',
      ],
    ),

    // ── ADD FUTURE EPISODES BELOW ──────────────────────────────────────
    // EpisodeManifest._(
    //   id: 'ep02',
    //   title: 'Episode 2: The Confession',
    //   scenePaths: [
    //     'assets/story/ep02/scene_01.json',
    //     'assets/story/ep02/scene_02.json',
    //     ... etc
    //   ],
    // ),
  ];

  static EpisodeManifest? get(String episodeId) {
    try {
      return all.firstWhere((e) => e.id == episodeId);
    } catch (_) {
      return null;
    }
  }
}
