// lib/features/minigame/minigame_gate.dart
//
// Called by the scheduler when it encounters:
//   { "action": "Launch_Minigame", "minigame_id": "...", "difficulty": 1 }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ghost_trace/ghost_trace_screen.dart';

/// Routes minigame_id → the correct minigame screen.
/// Add new minigames here as they're created.
class MinigameGate extends ConsumerWidget {
  final String minigameId;
  final int    difficulty;

  const MinigameGate({
    super.key,
    required this.minigameId,
    this.difficulty = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (minigameId.startsWith('ghost_trace')) {
      return GhostTraceScreen(
        minigameId: minigameId,
        difficulty: difficulty,
      );
    }

    // Fallback — should not happen if JSON is correct
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Unknown minigame: $minigameId',
          style: const TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}
