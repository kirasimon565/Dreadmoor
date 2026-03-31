// lib/features/minigame/minigame_gate.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/features/minigame/tracecore/tracecore_screen.dart';

/// Routes minigame_id → the correct investigation system.
///
/// tracecore_* → TracecoreScreen (primary investigation system)
///
/// NOTE:
/// GhostTrace has been removed to maintain a single coherent gameplay system.
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

    // ── TRACECORE (MAIN SYSTEM) ───────────────────────────────────────
    if (minigameId.startsWith('tracecore')) {
      return TracecoreScreen(
        minigameId: minigameId,
        difficulty: difficulty,
      );
    }

    // ── FALLBACK (SAFETY) ────────────────────────────────────────────
    // If something still references old minigame IDs (e.g. ghost_trace),
    // we show a safe error screen instead of crashing.
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Unknown investigation module:\n$minigameId',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
