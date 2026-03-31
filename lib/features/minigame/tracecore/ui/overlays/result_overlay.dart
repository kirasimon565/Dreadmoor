// lib/features/minigame/tracecore/ui/overlays/result_overlay.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../tracecore_controller.dart';

class TracecoreResultOverlay extends ConsumerWidget {
  final bool isDemo;
  const TracecoreResultOverlay({super.key, this.isDemo = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tracecoreProvider);
    final won   = state.won ?? false;

    return Container(
      color: Colors.black.withOpacity(0.90),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Icon(
              won ? Icons.check_circle_outline : Icons.cancel_outlined,
              size:  64,
              color: won
                  ? const Color(0xFF00FF41)
                  : const Color(0xFFFF1744),
            ),

            const SizedBox(height: 20),

            Text(
              isDemo
                  ? 'TRACE COMPLETE'
                  : won
                      ? 'TARGET IDENTIFIED'
                      : 'TRACE FAILED',
              style: GoogleFonts.sourceCodePro(
                color:         won
                    ? const Color(0xFF00FF41)
                    : const Color(0xFFFF1744),
                fontSize:      20,
                fontWeight:    FontWeight.w700,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              isDemo
                  ? 'Tutorial complete.\nStarting real investigation...'
                  : won
                      ? 'Analysis complete.\nStory continues.'
                      : state.isLocked
                          ? 'System locked.\nCooldown active.'
                          : 'Wrong submission.\nHeart lost. Try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.sourceCodePro(
                color:    const Color(0xFF2A5A2A),
                fontSize: 12,
                height:   1.6,
              ),
            ),

            if (state.isLocked && state.cooldownUntil != null) ...[
              const SizedBox(height: 20),
              _CooldownTimer(until: state.cooldownUntil!),
            ],

            const SizedBox(height: 32),

            // Demo: no button needed — auto-transitions
            if (!isDemo && !state.isLocked)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: won
                        ? const Color(0xFF00FF41)
                        : const Color(0xFFFF1744),
                    side: BorderSide(
                      color: won
                          ? const Color(0xFF00FF41)
                          : const Color(0xFFFF1744),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: won
                      ? null
                      : () =>
                          ref.read(tracecoreProvider.notifier).retry(),
                  child: Text(
                    won ? 'COMPLETE' : 'RETRY',
                    style: GoogleFonts.sourceCodePro(
                      fontSize:      12,
                      fontWeight:    FontWeight.w700,
                      letterSpacing: 2,
                    ),
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
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    final r = widget.until.difference(DateTime.now());
    setState(() => _remaining = r.isNegative ? Duration.zero : r);
    if (_remaining > Duration.zero) {
      _t = Timer(const Duration(seconds: 1), _tick);
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text(
      'TRY AGAIN IN  $m:$s',
      style: GoogleFonts.sourceCodePro(
        color:         const Color(0xFFFF1744),
        fontSize:      14,
        fontWeight:    FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}
