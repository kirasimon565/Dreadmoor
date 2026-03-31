// lib/features/minigame/tracecore/tracecore_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'models/tracecore_clue.dart';
import 'models/tracecore_session.dart';
import 'data/tracecore_difficulty.dart';
import 'data/tracecore_demo_data.dart';
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
      mode:         TracecoreMode.normal,
      difficulty:   TraceCoreDifficulty.forLevel(1),
      clues:        const [],
      secondsLeft:  60,
      hearts:       3,
      activePanel:  CluePanel.chat,
      tutorialSeen: false,
      demoStep:     DemoStep.intro,
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
      // First time → show guided demo
      _startDemo();
      return;
    }

    // Try to restore an in-progress session
    final saved = await dao.loadSession(minigameId);
    if (saved != null && saved.phase == 'active' && saved.secondsLeft > 0) {
      final puzzle = TracecoreGenerator.generate(difficulty: cfg);
      state = TracecoreState(
        phase:        TracecorePhase.active,
        mode:         TracecoreMode.normal,
        difficulty:   cfg,
        target:       saved.target,
        clues:        puzzle.clues,
        selectedIp:   saved.selectedIp,
        selectedName: saved.selectedName,
        secondsLeft:  saved.secondsLeft,
        hearts:       saved.hearts,
        activePanel:  CluePanel.chat,
        tutorialSeen: true,
        demoStep:     DemoStep.intro,
      );
      _startTimer();
      return;
    }

    _startNormalSession(cfg, dao);
  }

  void _startDemo() {
    state = TracecoreState(
      phase:        TracecorePhase.active,
      mode:         TracecoreMode.demo,
      difficulty:   TraceCoreDifficulty.forLevel(1),
      target:       TraceCoreDemoData.target,
      clues:        TraceCoreDemoData.clues,
      secondsLeft:  999, // no timer in demo
      hearts:       3,
      activePanel:  CluePanel.chat,
      tutorialSeen: false,
      demoStep:     DemoStep.intro,
    );
  }

  Future<void> _startNormalSession(
      TraceCoreDifficulty cfg, TracecoreDao dao) async {
    final puzzle = TracecoreGenerator.generate(difficulty: cfg);
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
      mode:         TracecoreMode.normal,
      difficulty:   cfg,
      target:       puzzle.target,
      clues:        puzzle.clues,
      secondsLeft:  cfg.durationSeconds,
      hearts:       cfg.hearts,
      activePanel:  CluePanel.chat,
      tutorialSeen: true,
      demoStep:     DemoStep.intro,
    );
    _startTimer();
  }

  // ── DEMO STEP PROGRESSION ─────────────────────────────────────────────────
  //
  // Each method is called by the UI when the correct action fires.
  // In demo mode, incorrect actions are ignored by the UI (locked inputs).

  /// Called when player taps the CHAT tab (step: intro → chatPanel)
  void demoTapChat() {
    if (!state.isDemo || state.demoStep != DemoStep.intro) return;
    state = state.copyWith(
      activePanel: CluePanel.chat,
      demoStep:    DemoStep.chatPanel,
    );
    // Auto-advance after brief read delay
    Timer(const Duration(seconds: 2), () {
      if (mounted && state.demoStep == DemoStep.chatPanel) {
        state = state.copyWith(demoStep: DemoStep.networkTab);
      }
    });
  }

  /// Called when player taps the NETWORK tab (step: networkTab → networkPanel)
  void demoTapNetwork() {
    if (!state.isDemo || state.demoStep != DemoStep.networkTab) return;
    state = state.copyWith(
      activePanel: CluePanel.network,
      demoStep:    DemoStep.networkPanel,
    );
    Timer(const Duration(seconds: 2), () {
      if (mounted && state.demoStep == DemoStep.networkPanel) {
        state = state.copyWith(demoStep: DemoStep.databaseTab);
      }
    });
  }

  /// Called when player taps the DATABASE tab (step: databaseTab → databasePanel)
  void demoTapDatabase() {
    if (!state.isDemo || state.demoStep != DemoStep.databaseTab) return;
    state = state.copyWith(
      activePanel: CluePanel.database,
      demoStep:    DemoStep.databasePanel,
    );
    Timer(const Duration(seconds: 2), () {
      if (mounted && state.demoStep == DemoStep.databasePanel) {
        state = state.copyWith(demoStep: DemoStep.selection);
      }
    });
  }

  bool get mounted {
    try {
      // ignore: unused_result
      ref.read(tracecoreProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── COMMON ACTIONS ────────────────────────────────────────────────────────

  void switchPanel(CluePanel panel) {
    if (state.isDemo) {
      // In demo mode, route to the appropriate demo handler
      switch (panel) {
        case CluePanel.chat:
          demoTapChat();
          break;
        case CluePanel.network:
          demoTapNetwork();
          break;
        case CluePanel.database:
          demoTapDatabase();
          break;
      }
      return;
    }
    state = state.copyWith(activePanel: panel);
  }

  void selectIp(String ip) {
    if (state.isDemo) {
      // Only allow correct IP
      if (ip != TraceCoreDemoData.target.ip) return;
      state = state.copyWith(selectedIp: ip);
      _checkDemoSelectionComplete();
      return;
    }
    state = state.copyWith(selectedIp: ip);
    _persist();
  }

  void selectName(String name) {
    if (state.isDemo) {
      // Only allow correct name
      if (name != TraceCoreDemoData.target.name) return;
      state = state.copyWith(selectedName: name);
      _checkDemoSelectionComplete();
      return;
    }
    state = state.copyWith(selectedName: name);
    _persist();
  }

  void _checkDemoSelectionComplete() {
    if (state.selectedIp   == TraceCoreDemoData.target.ip &&
        state.selectedName == TraceCoreDemoData.target.name) {
      state = state.copyWith(demoStep: DemoStep.submit);
    }
  }

  void submit() {
    if (!state.canSubmit) return;
    final target = state.target;
    if (target == null) return;

    if (state.isDemo) {
      // Demo always succeeds — advance to complete
      _demoComplete();
      return;
    }

    final correct = state.selectedIp   == target.ip &&
                    state.selectedName == target.name;
    if (correct) {
      _win();
    } else {
      _loseHeart();
    }
  }

  void _demoComplete() {
    state = state.copyWith(
      demoStep: DemoStep.complete,
      phase:    TracecorePhase.result,
      won:      true,
    );
    // Mark tutorial as seen then launch real session
    final db  = ref.read(databaseProvider);
    final dao = TracecoreDao(db);
    dao.markTutorialSeen().then((_) async {
      await Future.delayed(const Duration(seconds: 2));
      final cfg = TraceCoreDifficulty.forLevel(difficulty);
      await _startNormalSession(cfg, dao);
    });
  }

  void replayDemo() {
    _timer?.cancel();
    _startDemo();
  }

  void retry() {
    final db  = ref.read(databaseProvider);
    final dao = TracecoreDao(db);
    dao.clearSession(minigameId);
    initialise();
  }

  // ── NORMAL MODE INTERNALS ─────────────────────────────────────────────────

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
    ref.read(globalSchedulerProvider).completePuzzle();
  }

  void _persist() {
    final target = state.target;
    if (target == null || state.isDemo) return;
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
    if (target == null || state.isDemo) return;
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
