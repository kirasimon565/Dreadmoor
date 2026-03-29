// lib/features/minigame/ghost_trace/state/ghost_trace_state.dart

import '../data/target_generator.dart';
import '../data/difficulty_config.dart';

enum GhostTracePhase {
  scan,       // observing network traffic
  trace,      // tapping relay hops
  reconstruct,// IP/tag scramble puzzle
  result,     // win or lose shown
}

class GhostTraceState {
  final GhostTracePhase phase;
  final DifficultyConfig config;
  final NetworkTarget? target;

  // Scanning
  final String? suspectNodeId;
  final bool    attackerIdentified;

  // Tracing
  final List<String> correctHops;   // completed correct hops
  final int          currentHopIdx;
  final double       confidence;    // 0.0 → 1.0

  // Reconstruct
  final List<String> scrambledIpTiles;
  final List<String> scrambledTagTiles;
  final List<String?> ipSlots;
  final List<String?> tagSlots;

  // Hearts / timer
  final int   hearts;
  final DateTime? timerEndTimestamp;
  final bool  isLocked;
  final DateTime? cooldownUntil;

  // Outcome
  final bool? won; // null = in progress

  const GhostTraceState({
    required this.phase,
    required this.config,
    this.target,
    this.suspectNodeId,
    this.attackerIdentified = false,
    this.correctHops        = const [],
    this.currentHopIdx      = 0,
    this.confidence         = 0.0,
    this.scrambledIpTiles   = const [],
    this.scrambledTagTiles  = const [],
    this.ipSlots            = const [],
    this.tagSlots           = const [],
    this.hearts             = 5,
    this.timerEndTimestamp,
    this.isLocked           = false,
    this.cooldownUntil,
    this.won,
  });

  int get secondsLeft {
    if (timerEndTimestamp == null) return 0;
    final remaining = timerEndTimestamp!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  GhostTraceState copyWith({
    GhostTracePhase?   phase,
    DifficultyConfig?  config,
    NetworkTarget?     target,
    String?            suspectNodeId,
    bool?              attackerIdentified,
    List<String>?      correctHops,
    int?               currentHopIdx,
    double?            confidence,
    List<String>?      scrambledIpTiles,
    List<String>?      scrambledTagTiles,
    List<String?>?     ipSlots,
    List<String?>?     tagSlots,
    int?               hearts,
    DateTime?          timerEndTimestamp,
    bool?              isLocked,
    DateTime?          cooldownUntil,
    bool?              won,
  }) {
    return GhostTraceState(
      phase:               phase              ?? this.phase,
      config:              config             ?? this.config,
      target:              target             ?? this.target,
      suspectNodeId:       suspectNodeId      ?? this.suspectNodeId,
      attackerIdentified:  attackerIdentified ?? this.attackerIdentified,
      correctHops:         correctHops        ?? this.correctHops,
      currentHopIdx:       currentHopIdx      ?? this.currentHopIdx,
      confidence:          confidence         ?? this.confidence,
      scrambledIpTiles:    scrambledIpTiles   ?? this.scrambledIpTiles,
      scrambledTagTiles:   scrambledTagTiles  ?? this.scrambledTagTiles,
      ipSlots:             ipSlots            ?? this.ipSlots,
      tagSlots:            tagSlots           ?? this.tagSlots,
      hearts:              hearts             ?? this.hearts,
      timerEndTimestamp:   timerEndTimestamp  ?? this.timerEndTimestamp,
      isLocked:            isLocked           ?? this.isLocked,
      cooldownUntil:       cooldownUntil      ?? this.cooldownUntil,
      won:                 won                ?? this.won,
    );
  }

  bool get isInProgress => phase != GhostTracePhase.result;
  double get hopProgress =>
      config.relayHops > 0 ? currentHopIdx / config.relayHops : 0;
}
