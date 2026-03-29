// lib/features/minigame/ghost_trace/ghost_trace_screen.dart

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/core/scheduler/global_scheduler.dart';
import 'package:dreadmoor/core/state/game_state.dart'; // provides globalSchedulerProvider
import 'state/ghost_trace_notifier.dart';
import 'state/ghost_trace_state.dart';
import 'ghost_trace_game.dart';
import 'overlays/hud_overlay.dart';
import 'overlays/scramble_panel.dart';
import 'overlays/result_overlay.dart';
import 'overlays/tutorial_overlay.dart';
import 'data/ghost_trace_constants.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:drift/drift.dart' as drift;
import 'package:dreadmoor/core/persistence/drift_database.dart';

class GhostTraceScreen extends ConsumerStatefulWidget {
  final String minigameId;
  final int    difficulty;

  const GhostTraceScreen({
    super.key,
    required this.minigameId,
    this.difficulty = 1,
  });

  @override
  ConsumerState<GhostTraceScreen> createState() =>
      _GhostTraceScreenState();
}

class _GhostTraceScreenState extends ConsumerState<GhostTraceScreen> {
  GhostTraceGame? _game;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();

    ref.listen<GhostTraceState>(ghostTraceProvider, (prev, next) {
      if (prev?.phase != GhostTracePhase.result &&
          next.phase == GhostTracePhase.result) {

        final scheduler = ref.read(globalSchedulerProvider);

        if (next.won == true) {
          scheduler.completePuzzle();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(ghostTraceProvider.notifier);
      notifier.minigameId = widget.minigameId;
      notifier.difficulty  = widget.difficulty;

      final game = GhostTraceGame(
        config: notifier.state.config,
        onNodeTapped: _handleNodeTap,
      );
      setState(() => _game = game);

      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.initialise(game.nodeIds);

      final hasSeenTutorial = ref.read(gameFlagsProvider).value?['ghost_trace_tutorial_seen'] == true;
      if (!hasSeenTutorial) {
          setState(() {
              _showTutorial = true;
          });
          final db = ref.read(databaseProvider);
          db.into(db.storyState).insertOnConflictUpdate(
              StoryStateCompanion(
                  key: const drift.Value('ghost_trace_tutorial_seen'),
                  value: const drift.Value(true),
              )
          );
      }
    });
  }

  void _openTutorial() {
      setState(() {
          _showTutorial = true;
      });
  }

  void _closeTutorial() {
      setState(() {
          _showTutorial = false;
      });
  }

  void _handleNodeTap(String nodeId) {
    final state    = ref.read(ghostTraceProvider);
    final notifier = ref.read(ghostTraceProvider.notifier);

    switch (state.phase) {
      case GhostTracePhase.scan:
        notifier.tapNode(nodeId);
        if (ref.read(ghostTraceProvider).suspectNodeId != null) {
          _game?.markAttacker(nodeId);
          _game?.dimAll();
        }
        break;

      case GhostTracePhase.trace:
        final before = ref.read(ghostTraceProvider).currentHopIdx;
        notifier.tapHop(nodeId);
        final after  = ref.read(ghostTraceProvider).currentHopIdx;
        if (after > before) {
          _game?.markTraced(nodeId);
        }
        break;

      case GhostTracePhase.reconstruct:
      case GhostTracePhase.result:
        break;
    }
  }

  void _restart() {
    final notifier = ref.read(ghostTraceProvider.notifier);
    final game     = _game;
    if (game != null) {
      notifier.initialise(game.nodeIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ghostTraceProvider);
    final game  = _game;

    if (game == null) {
      return const Scaffold(
        backgroundColor: GhostTraceColors.background,
        body: Center(
          child: CircularProgressIndicator(
              color: GhostTraceColors.nodeNormal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: GhostTraceColors.background,
      body: Stack(
        children: [

          GameWidget(game: game),

          if (state.phase != GhostTracePhase.result)
            HudOverlay(onShowTutorial: _openTutorial),

          if (state.phase == GhostTracePhase.scan &&
              !state.attackerIdentified)
            const _InstructionBanner(
                text: 'IDENTIFY THE MALICIOUS NODE'),

          if (_showTutorial)
            TutorialOverlay(onDismiss: _closeTutorial),

          if (state.phase == GhostTracePhase.trace)
            _InstructionBanner(
                  text: 'TRACE HOP ' + (state.currentHopIdx + 1).toString() + ' / ' + state.config.relayHops.toString(),
            ),

          if (state.phase == GhostTracePhase.reconstruct)
            const ScramblePanel(),

          if (state.phase == GhostTracePhase.result)
            ResultOverlay(onDismiss: _restart),
        ],
      ),
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  final String text;
  const _InstructionBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 32,
      left:   0,
      right:  0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            border: Border.all(
                color: GhostTraceColors.hudDim, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color:      GhostTraceColors.hudText,
              fontSize:   11,
              fontFamily: 'monospace',
              letterSpacing: 1.8,
            ),
          ),
        ),
      ),
    );
  }
}
