// lib/features/minigame/ghost_trace/state/ghost_trace_notifier.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import '../data/difficulty_config.dart';
import '../data/target_generator.dart';
import '../persistence/minigame_dao.dart';
import '../data/ghost_trace_session.dart';
import 'ghost_trace_state.dart';

final ghostTraceProvider =
    NotifierProvider<GhostTraceNotifier, GhostTraceState>(
  GhostTraceNotifier.new,
);

class GhostTraceNotifier extends Notifier<GhostTraceState> {
  static final _rng = Random();
  Timer? _timer;

  String minigameId = 'ghost_trace_ep01';
  int    difficulty  = 1;

  @override
  GhostTraceState build() {
    // FIX: wrap in a lambda so the type is void Function(), not void Function()?
    // _timer?.cancel is nullable because _timer is Timer? — ref.onDispose
    // requires a non-null callback.
    ref.onDispose(() => _timer?.cancel());
    return GhostTraceState(
      phase:  GhostTracePhase.scan,
      config: DifficultyConfig.forLevel(1),
    );
  }

  Future<void> initialise(List<String> nodeIds) async {
    _timer?.cancel();

    final db     = ref.read(databaseProvider);
    final dao    = MinigameDao(db);
    final config = DifficultyConfig.forLevel(difficulty);

    final saved     = await dao.getResult(minigameId);
    final isCooling = await dao.isCoolingDown(minigameId);
    if (isCooling) {
      state = state.copyWith(
        config:        config,
        isLocked:      true,
        cooldownUntil: saved?.cooldownUntil,
      );
      return;
    }

    final hearts = saved?.heartsRemaining ?? 5;

    if (saved?.sessionData != null && saved!.sessionData!.isNotEmpty) {
      try {
        final session = GhostTraceSession.fromJsonString(saved.sessionData!);
        state = GhostTraceState(
          phase: session.phase,
          config: config,
          target: session.target,
          hearts: hearts,
          timerEndTimestamp: session.timerEndTimestamp,
          currentHopIdx: session.currentHopIdx,
          correctHops: session.correctHops,
          scrambledIpTiles: session.scrambledIpTiles,
          scrambledTagTiles: session.scrambledTagTiles,
          ipSlots: session.ipSlots,
          tagSlots: session.tagSlots,
          suspectNodeId: session.phase != GhostTracePhase.scan ? session.target.nodeId : null,
          attackerIdentified: session.phase != GhostTracePhase.scan,
          confidence: session.phase == GhostTracePhase.trace
              ? (session.currentHopIdx / session.target.relayChain.length)
              : (session.phase == GhostTracePhase.reconstruct ? 1.0 : 0.0),
        );
        _startTimer();
        return;
      } catch (e) {
        // If session parse fails, generate a new one
      }
    }

    final target = TargetGenerator.generate(
      allNodeIds: nodeIds,
      relayHops: config.relayHops,
    );
    final scrambledIp = _scramble(target.ip.split('.'));
    final scrambledTag = _scramble(target.tag.split(''));

    final timerEndTimestamp = DateTime.now().add(Duration(seconds: config.timerSeconds));

    state = GhostTraceState(
      phase: GhostTracePhase.scan,
      config: config,
      target: target,
      hearts: hearts,
      timerEndTimestamp: timerEndTimestamp,
      scrambledIpTiles: scrambledIp,
      scrambledTagTiles: scrambledTag,
      ipSlots: List.filled(target.ip.split('.').length, null),
      tagSlots: List.filled(target.tag.length, null),
    );

    _persistSession();
    _startTimer();
  }

  void tapNode(String nodeId) {
    if (state.phase != GhostTracePhase.scan) return;
    final isAttacker = nodeId == state.target?.nodeId;

    if (isAttacker) {
      state = state.copyWith(
        suspectNodeId:      nodeId,
        attackerIdentified: true,
        phase:              GhostTracePhase.trace,
        currentHopIdx:      0,
        correctHops:        [],
        confidence:         0.0,
      );
      _persistSession();
    } else {
      _loseHeart('wrong_node');
    }
  }

  void tapHop(String nodeId) {
    if (state.phase != GhostTracePhase.trace) return;
    final chain = state.target?.relayChain ?? [];
    if (state.currentHopIdx >= chain.length) return;

    final expected = chain[state.currentHopIdx];
    if (nodeId == expected) {
      final nextIdx    = state.currentHopIdx + 1;
      final newHops    = [...state.correctHops, nodeId];
      final confidence = nextIdx / chain.length;

      if (nextIdx >= chain.length) {
        state = state.copyWith(
          correctHops:   newHops,
          currentHopIdx: nextIdx,
          confidence:    1.0,
          phase:         GhostTracePhase.reconstruct,
        );
      } else {
        state = state.copyWith(
          correctHops:   newHops,
          currentHopIdx: nextIdx,
          confidence:    confidence,
        );
      }
      _persistSession();
    } else {
      state = state.copyWith(
        currentHopIdx: 0,
        correctHops:   [],
        confidence:    0.0,
      );
      _loseHeart('wrong_hop');
    }
  }

  void placeIpTile(int slotIndex, String tile) {
    if (state.phase != GhostTracePhase.reconstruct) return;
    final slots = List<String?>.from(state.ipSlots);
    slots[slotIndex] = tile;
    state = state.copyWith(ipSlots: slots);
    _persistSession();
  }

  void placeTagTile(int slotIndex, String tile) {
    if (state.phase != GhostTracePhase.reconstruct) return;
    final slots = List<String?>.from(state.tagSlots);
    slots[slotIndex] = tile;
    state = state.copyWith(tagSlots: slots);
    _persistSession();
  }

  void submitReconstruction() {
    if (state.phase != GhostTracePhase.reconstruct) return;
    final target = state.target;
    if (target == null) return;

    final ipCorrect  = state.ipSlots.join('.')  == target.ip;
    final tagCorrect = state.tagSlots.join()     == target.tag;

    if (ipCorrect && tagCorrect) {
      _win();
    } else {
      _loseHeart('wrong_submission');
      state = state.copyWith(
        ipSlots:  List.filled(state.ipSlots.length,  null),
        tagSlots: List.filled(state.tagSlots.length, null),
      );
      if (state.hearts > 0) {
          _persistSession();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();

    // Check immediately in case timer is already expired on resume
    if (state.secondsLeft <= 0) {
        _loseHeart('timeout');
        return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Force a state update to rebuild UI with new secondsLeft getter
      state = state.copyWith();
      if (state.secondsLeft <= 0) {
        _timer?.cancel();
        _loseHeart('timeout');
      }
    });
  }

  void _loseHeart(String reason) {
    final newHearts = state.hearts - 1;
    if (newHearts <= 0) {
      _timer?.cancel();
      final cooldown = DateTime.now().add(const Duration(minutes: 10));
      state = state.copyWith(
        hearts:        0,
        isLocked:      true,
        cooldownUntil: cooldown,
        phase:         GhostTracePhase.result,
        won:           false,
      );
      _persist(won: false, hearts: 0, sessionData: null);
    } else {
      if (reason == 'timeout') {
          // Reset the timer since we are not fully dead yet.
          final newEndTimestamp = DateTime.now().add(Duration(seconds: state.config.timerSeconds));
          state = state.copyWith(hearts: newHearts, timerEndTimestamp: newEndTimestamp);
          _startTimer();
      } else {
          state = state.copyWith(hearts: newHearts);
      }

      _persist(won: false, hearts: newHearts, sessionData: _createSessionJsonString());
    }
  }

  void _win() {
    _timer?.cancel();
    state = state.copyWith(
      phase: GhostTracePhase.result,
      won:   true,
    );
    _persist(won: true, hearts: state.hearts, sessionData: null);
    ref.read(globalSchedulerProvider).completePuzzle();
  }

  void _persist({required bool won, required int hearts, required String? sessionData}) {
    final db  = ref.read(databaseProvider);
    final dao = MinigameDao(db);
    dao.recordAttempt(
      minigameId:      minigameId,
      won:             won,
      heartsRemaining: hearts,
      sessionData:     sessionData,
    );
  }

  void _persistSession() {
      if (state.target == null || state.timerEndTimestamp == null) return;

      final sessionDataStr = _createSessionJsonString();
      final db  = ref.read(databaseProvider);
      final dao = MinigameDao(db);
      dao.updateSessionData(
          minigameId: minigameId,
          sessionData: sessionDataStr,
      );
  }

  String? _createSessionJsonString() {
      if (state.target == null || state.timerEndTimestamp == null) return null;
      final session = GhostTraceSession(
          target: state.target!,
          phase: state.phase,
          currentHopIdx: state.currentHopIdx,
          correctHops: state.correctHops,
          scrambledIpTiles: state.scrambledIpTiles,
          scrambledTagTiles: state.scrambledTagTiles,
          ipSlots: state.ipSlots,
          tagSlots: state.tagSlots,
          timerEndTimestamp: state.timerEndTimestamp!,
      );
      return session.toJsonString();
  }

  List<String> _scramble(List<String> items) {
    final list = List<String>.from(items);
    list.shuffle(_rng);
    return list;
  }
}
