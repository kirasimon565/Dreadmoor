// lib/features/tracecore/tracecore_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'models/tracecore_clue.dart';
import 'models/tracecore_session.dart';
import 'data/tracecore_difficulty.dart';
import 'data/tracecore_generator.dart';
import 'persistence/tracecore_dao.dart';
import 'tracecore_state.dart';

final tracecoreProvider =
    NotifierProvider<TracecoreController, TracecoreState>(
  TracecoreController.new,
);

class TracecoreController extends Notifier<TracecoreState> {
  Timer? _timer;

  String minigameId = 'tracecore_ep01';
  int    difficulty  = 1;

  @override
  TracecoreState build() {
    ref.onDispose(() => _timer?.cancel());
    return TracecoreState(
      phase:        TracecorePhase.active,
      difficulty:   TraceCoreDifficulty.forLevel(1),
      clues:        const [],
      secondsLeft:  60,
      hearts:       3,
      activePanel:  CluePanel.chat,
      tutorialSeen: false,
    );
  }

  // ── INITIALISE ────────────────────────────────────────────────────────────

  Future<void> initialise() async {
    _timer?.cancel();
    final db           = ref.read(databaseProvider);
    final dao          = TracecoreDao(db);
    final cfg          = TraceCoreDifficulty.forLevel(difficulty);
    final tutorialSeen = await dao.isTutorialSeen();

    if (!tutorialSeen) {
      state = TracecoreState(
        phase:        TracecorePhase.tutorial,
        difficulty:   cfg,
        clues:        const [],
        secondsLeft:  cfg.durationSeconds,
        hearts:       cfg.hearts,
        activePanel:  CluePanel.chat,
        tutorialSeen: false,
      );
      return;
    }

    await _startSession(cfg, dao);
  }

  Future<void> _startSession(
      TraceCoreDifficulty cfg, TracecoreDao dao) async {

    final saved = await dao.loadSession(minigameId);

    if (saved != null) {
      // FIX 2: Handle previously-failed sessions — show failure screen
      // instead of silently restarting (which looked like a win).
      if (saved.phase == 'failed') {
        state = TracecoreState(
          phase:        TracecorePhase.result,
          difficulty:   cfg,
          clues:        const [],
          secondsLeft:  0,
          hearts:       0,
          activePanel:  CluePanel.chat,
          tutorialSeen: true,
          won:          false,
          isLocked:     true,
        );
        return;
      }

      // FIX 2: Previously-completed session — show win screen.
      // Prevents the story from re-triggering completePuzzle if the
      // scheduler hasn't advanced yet.
      if (saved.phase == 'complete') {
        state = TracecoreState(
          phase:        TracecorePhase.result,
          difficulty:   cfg,
          clues:        const [],
          secondsLeft:  0,
          hearts:       saved.hearts,
          activePanel:  CluePanel.chat,
          tutorialSeen: true,
          won:          true,
        );
        return;
      }

      // FIX 3: Use real-world elapsed time to compute remaining seconds.
      // Previously used saved.secondsLeft directly, which allowed players
      // to reset the timer by restarting the app.
      if (saved.phase == 'active') {
        final elapsed =
            (DateTime.now().millisecondsSinceEpoch - saved.startTimestamp) ~/
                1000;
        final remaining = saved.durationSeconds - elapsed;

        if (remaining <= 0) {
          // Timer expired while app was closed — treat as timeout failure
          final newHearts = saved.hearts - 1;
          if (newHearts <= 0) {
            final cooldown =
                DateTime.now().add(const Duration(minutes: 10));
            await dao.saveSession(
              minigameId,
              TracecoreSession(
                target:          saved.target,
                startTimestamp:  saved.startTimestamp,
                durationSeconds: saved.durationSeconds,
                hearts:          0,
                phase:           'failed',
              ),
            );
            state = TracecoreState(
              phase:         TracecorePhase.result,
              difficulty:    cfg,
              clues:         const [],
              secondsLeft:   0,
              hearts:        0,
              activePanel:   CluePanel.chat,
              tutorialSeen:  true,
              won:           false,
              isLocked:      true,
              cooldownUntil: cooldown,
            );
          } else {
            // Hearts remain — restart with fresh timer, same puzzle
            final puzzle = TracecoreGenerator.generate(difficulty: cfg);
            final newSession = TracecoreSession(
              target:          saved.target,
              startTimestamp:  DateTime.now().millisecondsSinceEpoch,
              durationSeconds: cfg.durationSeconds,
              hearts:          newHearts,
              phase:           'active',
            );
            await dao.saveSession(minigameId, newSession);
            state = TracecoreState(
              phase:        TracecorePhase.active,
              difficulty:   cfg,
              target:       saved.target,
              clues:        puzzle.clues,
              secondsLeft:  cfg.durationSeconds,
              hearts:       newHearts,
              activePanel:  CluePanel.chat,
              tutorialSeen: true,
            );
            _startTimer();
          }
          return;
        }

        // Session still valid — restore with real remaining time
        final puzzle = TracecoreGenerator.generate(difficulty: cfg);
        state = TracecoreState(
          phase:        TracecorePhase.active,
          difficulty:   cfg,
          target:       saved.target,
          clues:        puzzle.clues,
          selectedIp:   saved.selectedIp,
          selectedName: saved.selectedName,
          secondsLeft:  remaining,
          hearts:       saved.hearts,
          activePanel:  CluePanel.chat,
          tutorialSeen: true,
        );
        _startTimer();
        return;
      }
    }

    // No saved session — generate fresh puzzle
    final puzzle  = TracecoreGenerator.generate(difficulty: cfg);
    final session = TracecoreSession(
      target:          puzzle.target,
      startTimestamp:  DateTime.now().millisecondsSinceEpoch,
      durationSeconds: cfg.durationSeconds,
      hearts:          cfg.hearts,
      phase:           'active',
    );
    await dao.saveSession(minigameId, session);

    state = TracecoreState(
      phase:        TracecorePhase.active,
      difficulty:   cfg,
      target:       puzzle.target,
      clues:        puzzle.clues,
      secondsLeft:  cfg.durationSeconds,
      hearts:       cfg.hearts,
      activePanel:  CluePanel.chat,
      tutorialSeen: true,
    );
    _startTimer();
  }

  // ── PUBLIC ACTIONS ────────────────────────────────────────────────────────

  Future<void> dismissTutorial() async {
    final db  = ref.read(databaseProvider);
    final dao = TracecoreDao(db);
    await dao.markTutorialSeen();
    final cfg = TraceCoreDifficulty.forLevel(difficulty);
    await _startSession(cfg, dao);
  }

  void switchPanel(CluePanel panel) {
    state = state.copyWith(activePanel: panel);
  }

  void selectIp(String ip) {
    state = state.copyWith(selectedIp: ip);
    _persist();
  }

  void selectName(String name) {
    state = state.copyWith(selectedName: name);
    _persist();
  }

  void submit() {
    if (!state.canSubmit) return;
    final target = state.target;
    if (target == null) return;

    final correct = state.selectedIp   == target.ip &&
                    state.selectedName == target.name;
    if (correct) {
      _win();
    } else {
      _loseHeart();
    }
  }

  void retry() {
    final db  = ref.read(databaseProvider);
    final dao = TracecoreDao(db);
    dao.clearSession(minigameId);
    initialise();
  }

  // ── INTERNAL ──────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.secondsLeft <= 1) {
        _timer?.cancel();
        _loseHeart();
      } else {
        state = state.copyWith(secondsLeft: state.secondsLeft - 1);
      }
    });
  }

  void _loseHeart() {
    _timer?.cancel();
    final newHearts = state.hearts - 1;
    if (newHearts <= 0) {
      final cooldown = DateTime.now().add(const Duration(minutes: 10));
      state = state.copyWith(
        hearts:        0,
        isLocked:      true,
        cooldownUntil: cooldown,
        phase:         TracecorePhase.result,
        won:           false,
      );
      _persistResult(won: false, hearts: 0);
    } else {
      state = state.copyWith(
        hearts:      newHearts,
        selectedIp:   null,
        selectedName: null,
        secondsLeft:  state.difficulty.durationSeconds,
      );
      _persist();
      _startTimer();
    }
  }

  void _win() {
    _timer?.cancel();
    state = state.copyWith(
      phase: TracecorePhase.result,
      won:   true,
    );
    _persistResult(won: true, hearts: state.hearts);
    // completePuzzle() now also clears waitingForPuzzleProvider
    ref.read(globalSchedulerProvider).completePuzzle();
  }

  void _persist() {
    final target = state.target;
    if (target == null) return;
    final session = TracecoreSession(
      target:          target,
      startTimestamp:  DateTime.now().millisecondsSinceEpoch,
      durationSeconds: state.difficulty.durationSeconds,
      selectedIp:      state.selectedIp,
      selectedName:    state.selectedName,
      hearts:          state.hearts,
      phase:           'active',
    );
    final db = ref.read(databaseProvider);
    TracecoreDao(db).saveSession(minigameId, session);
  }

  void _persistResult({required bool won, required int hearts}) {
    final target = state.target;
    if (target == null) return;
    final session = TracecoreSession(
      target:          target,
      startTimestamp:  DateTime.now().millisecondsSinceEpoch,
      durationSeconds: state.difficulty.durationSeconds,
      hearts:          hearts,
      phase:           won ? 'complete' : 'failed',
    );
    final db = ref.read(databaseProvider);
    TracecoreDao(db).saveSession(minigameId, session);
  }
}
