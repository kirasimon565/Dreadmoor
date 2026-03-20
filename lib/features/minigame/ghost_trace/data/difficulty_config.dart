// lib/features/minigame/ghost_trace/data/difficulty_config.dart

class DifficultyConfig {
  final int    level;
  final int    nodeCount;
  final int    relayHops;
  final int    timerSeconds;
  final int    scrambleLength;
  final double packetSpeedMultiplier;

  const DifficultyConfig({
    required this.level,
    required this.nodeCount,
    required this.relayHops,
    required this.timerSeconds,
    required this.scrambleLength,
    this.packetSpeedMultiplier = 1.0,
  });

  static const List<DifficultyConfig> levels = [
    DifficultyConfig(
      level: 1,
      nodeCount: 6,
      relayHops: 3,
      timerSeconds: 60,
      scrambleLength: 8,
      packetSpeedMultiplier: 1.0,
    ),
    DifficultyConfig(
      level: 2,
      nodeCount: 8,
      relayHops: 4,
      timerSeconds: 45,
      scrambleLength: 10,
      packetSpeedMultiplier: 1.3,
    ),
    DifficultyConfig(
      level: 3,
      nodeCount: 10,
      relayHops: 5,
      timerSeconds: 30,
      scrambleLength: 12,
      packetSpeedMultiplier: 1.7,
    ),
  ];

  static DifficultyConfig forLevel(int level) {
    final idx = (level - 1).clamp(0, levels.length - 1);
    return levels[idx];
  }
}
