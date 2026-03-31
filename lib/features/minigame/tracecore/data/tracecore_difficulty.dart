// lib/features/minigame/tracecore/data/tracecore_difficulty.dart

class TraceCoreDifficulty {
  final int level;
  final int durationSeconds;
  final int distractorCount;
  final int hearts;
  final double clueClarity; // 1.0 = very clear, 0.0 = very ambiguous

  const TraceCoreDifficulty({
    required this.level,
    required this.durationSeconds,
    required this.distractorCount,
    required this.hearts,
    required this.clueClarity,
  });

  static const List<TraceCoreDifficulty> levels = [
    TraceCoreDifficulty(
      level:           1,
      durationSeconds: 60,
      distractorCount: 2,
      hearts:          3,
      clueClarity:     1.0,
    ),
    TraceCoreDifficulty(
      level:           2,
      durationSeconds: 50,
      distractorCount: 3,
      hearts:          3,
      clueClarity:     0.7,
    ),
    TraceCoreDifficulty(
      level:           3,
      durationSeconds: 40,
      distractorCount: 5,
      hearts:          2,
      clueClarity:     0.4,
    ),
  ];

  static TraceCoreDifficulty forLevel(int level) {
    final idx = (level - 1).clamp(0, levels.length - 1);
    return levels[idx];
  }
}
