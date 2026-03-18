import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/features/minigame/ghost_trace/persistence/minigame_dao.dart';
import 'package:dreadmoor/core/scheduler/global_scheduler.dart';
import 'ghost_trace_state.dart';

class GhostTraceNotifier extends Notifier<GhostTraceState> {
  Timer? _timer;
  late MinigameDao _dao;
  String _currentMinigameId = 'ghost_trace_ep01'; // Default, update via init

  @override
  GhostTraceState build() {
    _dao = ref.watch(minigameDaoProvider);
    return const GhostTraceState();
  }

  Future<void> init(String minigameId) async {
    _currentMinigameId = minigameId;
    final result = await _dao.getResult(minigameId);

    if (result != null) {
      if (result.completed) {
        state = state.copyWith(isCompleted: true);
        return;
      }

      if (result.cooldownUntil != null &&
          DateTime.now().isBefore(result.cooldownUntil!)) {
        state = state.copyWith(cooldownUntil: result.cooldownUntil);
        return;
      }
    }

    _generateTarget();
    _startTimer();
  }

  void _generateTarget() {
    final ip = '192.168.0.${Random().nextInt(255)}';
    final chars = '0123456789ABCDEF';
    final tag = List.generate(8, (index) => chars[Random().nextInt(chars.length)]).join();

    final allChars = (ip.replaceAll('.', '') + tag).split('')..shuffle();
    final scrambled = allChars.take(8).join(' ');

    state = state.copyWith(
      targetIp: ip,
      targetTag: tag,
      scrambledString: scrambled,
      timeRemaining: 60,
      hearts: 5,
      traceConfidence: 0.0,
      isExposePhase: false,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemaining > 0) {
        state = state.copyWith(timeRemaining: state.timeRemaining - 1);
      } else {
        _timer?.cancel();
        loseHeart();
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  void increaseConfidence(double amount) {
    final newConf = (state.traceConfidence + amount).clamp(0.0, 1.0);
    state = state.copyWith(traceConfidence: newConf);
    if (newConf >= 1.0) {
      state = state.copyWith(isExposePhase: true);
      _timer?.cancel();
    }
  }

  void loseHeart() async {
    final newHearts = state.hearts - 1;
    if (newHearts <= 0) {
      // Cooldown
      final cooldownTime = DateTime.now().add(const Duration(minutes: 10));
      state = state.copyWith(hearts: 0, cooldownUntil: cooldownTime);
      await _dao.saveResult(
        MinigameResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          minigameId: _currentMinigameId,
          completed: false,
          attemptsCount: 0,
          heartsRemaining: 0,
          cooldownUntil: cooldownTime,
        ),
      );
      stopTimer();
    } else {
      state = state.copyWith(hearts: newHearts, timeRemaining: 60);
      _startTimer();
    }
  }

  void winGame() async {
    state = state.copyWith(isCompleted: true);
    stopTimer();
    await _dao.saveResult(
      MinigameResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        minigameId: _currentMinigameId,
        completed: true,
        attemptsCount: 1,
        heartsRemaining: state.hearts,
        completedAt: DateTime.now(),
      ),
    );
    // Puzzle completion will be handled by the screen navigating back
  }

  // Notifier lifecycle does not have a dispose method we can easily override like this.
  // Instead, the timer should ideally be canceled when the state changes to inactive,
  // or by a provider onDispose block. For simplicity, stopTimer handles the timer.
}

final ghostTraceProvider = NotifierProvider<GhostTraceNotifier, GhostTraceState>(
  GhostTraceNotifier.new,
);
