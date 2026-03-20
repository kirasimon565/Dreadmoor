// lib/features/minigame/ghost_trace/overlays/hud_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/ghost_trace_notifier.dart';
import '../state/ghost_trace_state.dart';
import '../data/ghost_trace_constants.dart';

class HudOverlay extends ConsumerWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ghostTraceProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        children: [
          // Top row: phase label + timer + hearts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PhaseLabel(phase: state.phase),
              _Timer(seconds: state.secondsLeft),
              _Hearts(hearts: state.hearts),
            ],
          ),

          const SizedBox(height: 8),

          // Confidence bar (shown during trace)
          if (state.phase == GhostTracePhase.trace)
            _ConfidenceBar(confidence: state.confidence),
        ],
      ),
    );
  }
}

class _PhaseLabel extends StatelessWidget {
  final GhostTracePhase phase;
  const _PhaseLabel({required this.phase});

  String get _label {
    switch (phase) {
      case GhostTracePhase.scan:        return '> SCAN';
      case GhostTracePhase.trace:       return '> TRACE';
      case GhostTracePhase.reconstruct: return '> RECONSTRUCT';
      case GhostTracePhase.result:      return '> DONE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _label,
      style: GoogleFonts.sourceCodePro(
        color:     GhostTraceColors.hudText,
        fontSize:  12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _Timer extends StatelessWidget {
  final int seconds;
  const _Timer({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final isUrgent = seconds <= 10;
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');

    return Text(
      '$m:$s',
      style: GoogleFonts.sourceCodePro(
        color:     isUrgent ? GhostTraceColors.nodeAttacker : GhostTraceColors.hudText,
        fontSize:  18,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}

class _Hearts extends StatelessWidget {
  final int hearts;
  const _Hearts({required this.hearts});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        GhostTraceConstants.maxHearts,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            Icons.favorite,
            size: 14,
            color: i < hearts
                ? GhostTraceColors.heartFull
                : GhostTraceColors.heartEmpty,
          ),
        ),
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final double confidence;
  const _ConfidenceBar({required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRACE CONFIDENCE  ${(confidence * 100).toInt()}%',
          style: GoogleFonts.sourceCodePro(
            color:     GhostTraceColors.hudDim,
            fontSize:  9,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value:           confidence,
            minHeight:       6,
            backgroundColor: GhostTraceColors.hudDim,
            valueColor: const AlwaysStoppedAnimation<Color>(
              GhostTraceColors.nodeTraced,
            ),
          ),
        ),
      ],
    );
  }
}
