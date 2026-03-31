// lib/features/minigame/tracecore/tracecore_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tracecore_controller.dart';
import 'tracecore_state.dart';
import 'ui/tracecore_layout.dart';
import 'ui/widgets/timer_bar.dart';
import 'ui/overlays/result_overlay.dart';
import 'ui/overlays/demo_overlay.dart';

class TracecoreScreen extends ConsumerStatefulWidget {
  final String minigameId;
  final int    difficulty;

  const TracecoreScreen({
    super.key,
    required this.minigameId,
    this.difficulty = 1,
  });

  @override
  ConsumerState<TracecoreScreen> createState() => _TracecoreScreenState();
}

class _TracecoreScreenState extends ConsumerState<TracecoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(tracecoreProvider.notifier);
      notifier.minigameId = widget.minigameId;
      notifier.difficulty  = widget.difficulty;
      await notifier.initialise();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(tracecoreProvider);
    final notifier = ref.read(tracecoreProvider.notifier);
    final isDemo   = state.isDemo;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [

            // ── MAIN LAYOUT ────────────────────────────────────────────
            Column(
              children: [

                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: Color(0xFF1A3A1A), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isDemo ? 'TRACECORE  //  DEMO' : 'TRACECORE',
                        style: GoogleFonts.sourceCodePro(
                          color:         const Color(0xFF00FF41),
                          fontSize:      13,
                          fontWeight:    FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                      const Spacer(),
                      // ? button — replay demo anytime
                      if (!isDemo)
                        GestureDetector(
                          onTap: notifier.replayDemo,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFF1A3A1A)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              '?',
                              style: GoogleFonts.sourceCodePro(
                                color:     const Color(0xFF2A5A2A),
                                fontSize:  13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (!isDemo) const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFF1A3A1A)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          isDemo ? 'TUTORIAL' : 'LVL ${widget.difficulty}',
                          style: GoogleFonts.sourceCodePro(
                            color:     isDemo
                                ? const Color(0xFF4A7A2A)
                                : const Color(0xFF2A5A2A),
                            fontSize:  10,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Data panels (tabs)
                const Expanded(child: TracecoreLayout()),

                // Submit bar
                _SubmitBar(state: state, notifier: notifier),

                // Timer bar — hidden in demo (no time pressure)
                if (!isDemo)
                  TimerBar(
                    secondsLeft:  state.secondsLeft,
                    totalSeconds: state.difficulty.durationSeconds,
                    hearts:       state.hearts,
                    maxHearts:    state.difficulty.hearts,
                  ),
              ],
            ),

            // ── DEMO OVERLAY ───────────────────────────────────────────
            // Rendered ABOVE the layout so it can highlight any zone.
            // The overlay itself is IgnorePointer so taps pass through
            // to the real UI — interaction locking is done in the
            // controller (wrong taps are silently ignored).
            if (isDemo && state.demoStep != DemoStep.complete)
              const DemoOverlay(),

            // ── RESULT OVERLAY ─────────────────────────────────────────
            if (state.phase == TracecorePhase.result)
              TracecoreResultOverlay(isDemo: isDemo),
          ],
        ),
      ),
    );
  }
}

// ── SUBMIT BAR ────────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final TracecoreState       state;
  final TracecoreController  notifier;

  const _SubmitBar({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF050505),
        border: Border(
          top: BorderSide(color: Color(0xFF1A3A1A), width: 1),
        ),
      ),
      child: Row(
        children: [
          _SelectionChip(
            label:    'IP',
            value:    state.selectedIp ?? '—',
            hasValue: state.selectedIp != null,
          ),
          const SizedBox(width: 10),
          _SelectionChip(
            label:    'NAME',
            value:    state.selectedName ?? '—',
            hasValue: state.selectedName != null,
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: state.canSubmit ? notifier.submit : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: state.canSubmit
                    ? const Color(0xFF003A00)
                    : const Color(0xFF0A0A0A),
                border: Border.all(
                  color: state.canSubmit
                      ? const Color(0xFF00FF41)
                      : const Color(0xFF1A3A1A),
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'SUBMIT',
                style: GoogleFonts.sourceCodePro(
                  fontSize:      12,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 1.5,
                  color:         state.canSubmit
                      ? const Color(0xFF00FF41)
                      : const Color(0xFF1A3A1A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  final String label;
  final String value;
  final bool   hasValue;

  const _SelectionChip({
    required this.label,
    required this.value,
    required this.hasValue,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border.all(
            color: hasValue
                ? const Color(0xFF2A5A2A)
                : const Color(0xFF1A2A1A),
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.sourceCodePro(
                fontSize:      8,
                color:         const Color(0xFF2A5A2A),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.sourceCodePro(
                fontSize:  11,
                color:     hasValue
                    ? const Color(0xFF00FF41)
                    : const Color(0xFF1A3A1A),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
