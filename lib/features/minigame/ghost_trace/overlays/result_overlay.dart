// lib/features/minigame/ghost_trace/overlays/result_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/ghost_trace_notifier.dart';
import '../data/ghost_trace_constants.dart';

class ResultOverlay extends ConsumerWidget {
  final VoidCallback onDismiss;
  const ResultOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ghostTraceProvider);
    final won   = state.won ?? false;

    return Container(
      color: Colors.black.withOpacity(0.85),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              won ? Icons.check_circle_outline : Icons.cancel_outlined,
              color:  won
                  ? GhostTraceColors.nodeNormal
                  : GhostTraceColors.nodeAttacker,
              size: 64,
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              won ? 'TRACE COMPLETE' : 'TRACE FAILED',
              style: GoogleFonts.sourceCodePro(
                color:     won
                    ? GhostTraceColors.nodeNormal
                    : GhostTraceColors.nodeAttacker,
                fontSize:  22,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              won
                  ? 'Attacker identity confirmed.\nStory continues.'
                  : state.isLocked
                      ? 'Network locked.\nCooldown active.'
                      : 'Incorrect trace.\nHeart lost.',
              textAlign: TextAlign.center,
              style: GoogleFonts.sourceCodePro(
                color:    GhostTraceColors.hudDim,
                fontSize: 12,
                height:   1.6,
                letterSpacing: 0.8,
              ),
            ),

            // Cooldown timer
            if (state.isLocked && state.cooldownUntil != null) ...[
              const SizedBox(height: 16),
              _CooldownTimer(until: state.cooldownUntil!),
            ],

            const SizedBox(height: 32),

            if (!state.isLocked)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: won
                      ? GhostTraceColors.nodeNormal
                      : GhostTraceColors.nodeAttacker,
                  side: BorderSide(
                    color: won
                        ? GhostTraceColors.nodeNormal
                        : GhostTraceColors.nodeAttacker,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                ),
                onPressed: onDismiss,
                child: Text(
                  won ? 'CONTINUE' : 'RETRY',
                  style: GoogleFonts.sourceCodePro(
                    fontSize:  12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CooldownTimer extends StatefulWidget {
  final DateTime until;
  const _CooldownTimer({required this.until});

  @override
  State<_CooldownTimer> createState() => _CooldownTimerState();
}

class _CooldownTimerState extends State<_CooldownTimer> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    final r = widget.until.difference(DateTime.now());
    setState(() => _remaining = r.isNegative ? Duration.zero : r);
    if (_remaining > Duration.zero) {
      Future.delayed(const Duration(seconds: 1), _tick);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text(
      'TRY AGAIN IN  $m:$s',
      style: GoogleFonts.sourceCodePro(
        color:     GhostTraceColors.nodeAttacker,
        fontSize:  14,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}
