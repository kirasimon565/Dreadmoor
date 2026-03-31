// lib/features/minigame/tracecore/tracecore_state.dart

import 'models/tracecore_target.dart';
import 'models/tracecore_clue.dart';
import 'data/tracecore_difficulty.dart';

// ── Mode ──────────────────────────────────────────────────────────────────────

enum TracecoreMode { demo, normal }

// ── Demo steps (linear, locked progression) ───────────────────────────────────
//
// Each step corresponds to one required player action.
// The controller advances the step when the correct action fires.

enum DemoStep {
  intro,        // overlay: "Start by reading the chat logs" → tap CHAT tab
  chatPanel,    // chat panel is shown, player reads clue → auto-advance
  networkTab,   // overlay: "Now check network activity" → tap NETWORK tab
  networkPanel, // network panel shown, player reads clue → auto-advance
  databaseTab,  // overlay: "Check the database" → tap DATABASE tab
  databasePanel,// database panel shown → auto-advance
  selection,    // overlay: "Select the correct identity" → select IP + name
  submit,       // overlay: "Submit" → tap SUBMIT
  complete,     // success shown → demo ends
}

// ── Phase ─────────────────────────────────────────────────────────────────────

enum TracecorePhase { tutorial, active, result }

// ── State ─────────────────────────────────────────────────────────────────────

class TracecoreState {
  final TracecorePhase      phase;
  final TracecoreMode       mode;
  final TraceCoreDifficulty difficulty;
  final TracecoreTarget?    target;
  final List<TracecoreClue> clues;

  // Selections
  final String? selectedIp;
  final String? selectedName;

  // Timer
  final int secondsLeft;

  // Hearts
  final int hearts;

  // Outcome
  final bool?     won;
  final bool      isLocked;
  final DateTime? cooldownUntil;

  // Active panel
  final CluePanel activePanel;

  // Tutorial
  final bool tutorialSeen;

  // Demo-only step counter (ignored in normal mode)
  final DemoStep demoStep;

  const TracecoreState({
    required this.phase,
    required this.mode,
    required this.difficulty,
    required this.clues,
    required this.secondsLeft,
    required this.hearts,
    required this.activePanel,
    required this.tutorialSeen,
    required this.demoStep,
    this.target,
    this.selectedIp,
    this.selectedName,
    this.won,
    this.isLocked    = false,
    this.cooldownUntil,
  });

  TracecoreState copyWith({
    TracecorePhase?      phase,
    TracecoreMode?       mode,
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
    DemoStep?            demoStep,
  }) {
    return TracecoreState(
      phase:         phase         ?? this.phase,
      mode:          mode          ?? this.mode,
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
      demoStep:      demoStep      ?? this.demoStep,
    );
  }

  bool get isDemo => mode == TracecoreMode.demo;

  List<TracecoreClue> get chatClues =>
      clues.where((c) => c.panel == CluePanel.chat).toList();
  List<TracecoreClue> get networkClues =>
      clues.where((c) => c.panel == CluePanel.network).toList();
  List<TracecoreClue> get databaseClues =>
      clues.where((c) => c.panel == CluePanel.database).toList();

  bool get canSubmit =>
      selectedIp != null && selectedName != null;
}
