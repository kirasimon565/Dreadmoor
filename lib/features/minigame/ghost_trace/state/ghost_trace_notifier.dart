// lib/features/minigame/ghost_trace/state/ghost_trace_notifier.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import '../data/difficulty_config.dart';
import '../data/target_generator.dart';
import '../persistence/minigame_dao.dart';
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

    final hearts     = saved?.heartsRemaining ?? 5;
    final target     = TargetGenerator.generate(
      allNodeIds: nodeIds,
      relayHops:  config.relayHops,
    );
    final scrambledIp  = _scramble(target.ip.split('.'));
    final scrambledTag = _scramble(target.tag.split(''));

    state = GhostTraceState(
      phase:             GhostTracePhase.scan,
      config:            config,
      target:            target,
      hearts:            hearts,
      secondsLeft:       config.timerSeconds,
      scrambledIpTiles:  scrambledIp,
      scrambledTagTiles: scrambledTag,
      ipSlots:           List.filled(target.ip.split('.').length, null),
      tagSlots:          List.filled(target.tag.length, null),
    );

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
  }

  void placeTagTile(int slotIndex, String tile) {
    if (state.phase != GhostTracePhase.reconstruct) return;
    final slots = List<String?>.from(state.tagSlots);
    slots[slotIndex] = tile;
    state = state.copyWith(tagSlots: slots);
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
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.secondsLeft <= 1) {
        _timer?.cancel();
        _loseHeart('timeout');
      } else {
        state = state.copyWith(secondsLeft: state.secondsLeft - 1);
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
      _persist(won: false, hearts: 0);
    } else {
      state = state.copyWith(hearts: newHearts);
      _persist(won: false, hearts: newHearts);
    }
  }

  void _win() {
    _timer?.cancel();
    state = state.copyWith(
      phase: GhostTracePhase.result,
      won:   true,
    );
    _persist(won: true, hearts: state.hearts);
    ref.read(globalSchedulerProvider).completePuzzle();
  }

  void _persist({required bool won, required int hearts}) {
    final db  = ref.read(databaseProvider);
    final dao = MinigameDao(db);
    dao.recordAttempt(
      minigameId:      minigameId,
      won:             won,
      heartsRemaining: hearts,
    );
  }

  List<String> _scramble(List<String> items) {
    final list = List<String>.from(items);
    list.shuffle(_rng);
    return list;
  }
}
