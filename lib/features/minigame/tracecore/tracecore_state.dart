// lib/minigame/features/tracecore/tracecore_state.dart

import 'models/tracecore_target.dart';
import 'models/tracecore_clue.dart';
import 'data/tracecore_difficulty.dart';

enum TracecorePhase { tutorial, active, result }

class TracecoreState {
  final TracecorePhase      phase;
  final TraceCoreDifficulty difficulty;
  final TracecoreTarget?    target;
  final List<TracecoreClue> clues;

  final String? selectedIp;
  final String? selectedName;

  final int secondsLeft;
  final int hearts;

  final bool?     won;
  final bool      isLocked;
  final DateTime? cooldownUntil;

  final CluePanel activePanel;
  final bool      tutorialSeen;

  const TracecoreState({
    required this.phase,
    required this.difficulty,
    required this.clues,
    required this.secondsLeft,
    required this.hearts,
    required this.activePanel,
    required this.tutorialSeen,
    this.target,
    this.selectedIp,
    this.selectedName,
    this.won,
    this.isLocked    = false,
    this.cooldownUntil,
  });

  TracecoreState copyWith({
    TracecorePhase?      phase,
    TraceCoreDifficulty? difficulty,
    TracecoreTarget?     target,
    List<TracecoreClue>? clues,
    String?              selectedIp,
    String?              selectedName,
    int?                 secondsLeft,
    int?                 hearts,
    bool?                won,
    bool?                isLocked,
    DateTime?            cooldownUntil,
    CluePanel?           activePanel,
    bool?                tutorialSeen,
  }) {
    return TracecoreState(
      phase:         phase         ?? this.phase,
      difficulty:    difficulty    ?? this.difficulty,
      target:        target        ?? this.target,
      clues:         clues         ?? this.clues,
      selectedIp:    selectedIp    ?? this.selectedIp,
      selectedName:  selectedName  ?? this.selectedName,
      secondsLeft:   secondsLeft   ?? this.secondsLeft,
      hearts:        hearts        ?? this.hearts,
      won:           won           ?? this.won,
      isLocked:      isLocked      ?? this.isLocked,
      cooldownUntil: cooldownUntil ?? this.cooldownUntil,
      activePanel:   activePanel   ?? this.activePanel,
      tutorialSeen:  tutorialSeen  ?? this.tutorialSeen,
    );
  }

  List<TracecoreClue> get chatClues =>
      clues.where((c) => c.panel == CluePanel.chat).toList();
  List<TracecoreClue> get networkClues =>
      clues.where((c) => c.panel == CluePanel.network).toList();
  List<TracecoreClue> get databaseClues =>
      clues.where((c) => c.panel == CluePanel.database).toList();

  bool get canSubmit => selectedIp != null && selectedName != null;
}
