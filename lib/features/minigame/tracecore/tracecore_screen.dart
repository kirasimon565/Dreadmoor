// lib/features/minigame/tracecore/tracecore_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tracecore_controller.dart';
import 'tracecore_state.dart';
import 'ui/tracecore_layout.dart';
import 'ui/widgets/timer_bar.dart';
import 'ui/overlays/result_overlay.dart';

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
                        'TRACECORE',
                        style: GoogleFonts.sourceCodePro(
                          color:         const Color(0xFF00FF41),
                          fontSize:      13,
                          fontWeight:    FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFF1A3A1A)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'LVL ${widget.difficulty}',
                          style: GoogleFonts.sourceCodePro(
                            color:     const Color(0xFF2A5A2A),
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

                // Permanent hint above submit bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  color: const Color(0xFF030D03),
                  child: Text(
                    'Match location → IP → identity',
                    style: GoogleFonts.sourceCodePro(
                      color:     const Color(0xFF1A4A1A),
                      fontSize:  10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                // Submit bar
                _SubmitBar(state: state, notifier: notifier),

                // Timer bar
                TimerBar(
                  secondsLeft:  state.secondsLeft,
                  totalSeconds: state.difficulty.durationSeconds,
                  hearts:       state.hearts,
                  maxHearts:    state.difficulty.hearts,
                ),
              ],
            ),

            // ── STATIC TUTORIAL OVERLAY ─────────────────────────────────
            if (state.phase == TracecorePhase.tutorial)
              _StaticTutorialOverlay(
                onDismiss: notifier.dismissTutorial,
              ),

            // ── RESULT OVERLAY ─────────────────────────────────────────
            if (state.phase == TracecorePhase.result)
              const TracecoreResultOverlay(),
          ],
        ),
      ),
    );
  }
}

// ── STATIC TUTORIAL ───────────────────────────────────────────────────────────

class _StaticTutorialOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  const _StaticTutorialOverlay({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              'TRACECORE',
              style: GoogleFonts.sourceCodePro(
                color:         const Color(0xFF00FF41),
                fontSize:      22,
                fontWeight:    FontWeight.w700,
                letterSpacing: 4,
              ),
            ),

            const SizedBox(height: 32),

            _line('Chat reveals location.'),
            _line('Network reveals IP.'),
            _line('Database reveals identity.'),

            const SizedBox(height: 24),

            Text(
              'Find the match.\nSubmit before time runs out.',
              style: GoogleFonts.sourceCodePro(
                color:    const Color(0xFF4A7A4A),
                fontSize: 14,
                height:   1.7,
              ),
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00FF41),
                  side: const BorderSide(
                      color: Color(0xFF00FF41), width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: onDismiss,
                child: Text(
                  'BEGIN',
                  style: GoogleFonts.sourceCodePro(
                    fontSize:      13,
                    fontWeight:    FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '> ',
            style: GoogleFonts.sourceCodePro(
              color:    const Color(0xFF00FF41),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.sourceCodePro(
                color:    const Color(0xFF00FF41),
                fontSize: 14,
                height:   1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SUBMIT BAR ────────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final TracecoreState      state;
  final TracecoreController notifier;

  const _SubmitBar({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF050505),
        border: Border(
            top: BorderSide(color: Color(0xFF1A3A1A), width: 1)),
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
