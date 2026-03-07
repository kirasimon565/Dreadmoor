import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/recap_state.dart';
import 'package:dreadmoor/ui/theme/colors.dart';

class RecapScreen extends ConsumerStatefulWidget {
  final String episodeId;

  const RecapScreen({super.key, required this.episodeId});

  @override
  ConsumerState<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends ConsumerState<RecapScreen>
    with TickerProviderStateMixin {
  // One controller per revealed line for independent fade-in
  final List<AnimationController> _lineControllers = [];
  final List<Animation<double>> _lineOpacities = [];
  final List<Animation<Offset>> _lineSlides = [];

  // Header animation
  late AnimationController _headerController;
  late Animation<double> _headerOpacity;

  // Continue button animation
  late AnimationController _continueController;
  late Animation<double> _continueOpacity;

  // Film grain tick
  late AnimationController _grainController;

  // How many lines have been revealed so far
  int _revealedCount = 0;
  bool _allRevealed = false;
  bool _skipped = false;

  // Timers for sequential reveal
  final List<Timer> _timers = [];

  // Scroll controller for auto-scroll
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _headerOpacity = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );

    _continueController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _continueOpacity = CurvedAnimation(
      parent: _continueController,
      curve: Curves.easeOut,
    );

    // Film grain flicker — fast tick used to rebuild grain painter
    _grainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..repeat(reverse: true);

    _headerController.forward();
  }

  void _scheduleReveal(List<RecapLine> lines) {
    // Clear any existing timers (e.g. if provider rebuilds)
    _cancelTimers();

    // Build animation controllers for all lines upfront
    for (int i = _lineControllers.length; i < lines.length; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      );
      _lineControllers.add(ctrl);
      _lineOpacities.add(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
      _lineSlides.add(
        Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut)),
      );
    }

    // Stagger reveals — header: 0ms, lines: 400ms + 550ms per line
    for (int i = _revealedCount; i < lines.length; i++) {
      final delay = Duration(milliseconds: 400 + i * 550);
      final t = Timer(delay, () {
        if (!mounted) return;
        setState(() => _revealedCount = i + 1);
        _lineControllers[i].forward();
        // Auto-scroll to bottom
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        });
        // After last line, show continue button
        if (i == lines.length - 1) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            setState(() => _allRevealed = true);
            _continueController.forward();
          });
        }
      });
      _timers.add(t);
    }
  }

  void _skipAll(List<RecapLine> lines) {
    _cancelTimers();
    setState(() {
      _skipped = true;
      _revealedCount = lines.length;
      _allRevealed = true;
    });
    for (final ctrl in _lineControllers) {
      ctrl.value = 1.0;
    }
    _continueController.forward();
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _continue() {
    context.go('/messenger');
  }

  @override
  void dispose() {
    _cancelTimers();
    _headerController.dispose();
    _continueController.dispose();
    _grainController.dispose();
    for (final ctrl in _lineControllers) {
      ctrl.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Pass episodeId to the provider — original code ignored widget.episodeId
    final recapAsync = ref.watch(recapProvider(widget.episodeId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Film grain background ──────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _grainController,
              builder: (_, __) => CustomPaint(
                painter: _FilmGrainPainter(seed: _grainController.value),
              ),
            ),
          ),

          // ── Left film perforations ─────────────────────────
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 28,
            child: _FilmPerforations(),
          ),

          // ── Right film perforations ────────────────────────
          const Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 28,
            child: _FilmPerforations(),
          ),

          // ── Main content ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: recapAsync.when(
              loading: () => const _LoadingState(),
              error: (e, _) => const _ErrorState(),
              data: (lines) {
                // Schedule reveals once lines are loaded
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_lineControllers.length < lines.length) {
                    _scheduleReveal(lines);
                  }
                });

                return Column(
                  children: [
                    // ── "PREVIOUSLY IN DREADMOOR" header ──────
                    const SizedBox(height: 60),
                    FadeTransition(
                      opacity: _headerOpacity,
                      child: _RecapHeader(episodeId: widget.episodeId),
                    ),
                    const SizedBox(height: 36),

                    // ── Scrollable lines ───────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < _revealedCount; i++)
                              _buildLine(lines[i], i),
                            // Breathing room at bottom
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Continue button ────────────────────────────────
          if (_allRevealed)
            Positioned(
              bottom: 40,
              left: 44,
              right: 44,
              child: FadeTransition(
                opacity: _continueOpacity,
                child: _ContinueButton(onPressed: _continue),
              ),
            ),

          // ── Skip button (shown until all revealed) ─────────
          if (!_allRevealed)
            Positioned(
              bottom: 40,
              right: 44,
              child:
                  recapAsync.whenData((lines) {
                    return TextButton(
                      onPressed: () => _skipAll(lines),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SKIP',
                            style: GoogleFonts.michroma(
                              fontSize: 10,
                              letterSpacing: 3,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white.withOpacity(0.3),
                            size: 14,
                          ),
                        ],
                      ),
                    );
                  }).value ??
                  const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildLine(RecapLine line, int index) {
    if (index >= _lineControllers.length) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _lineOpacities[index],
      child: SlideTransition(
        position: _lineSlides[index],
        child: Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: _RecapLineWidget(line: line),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Recap header
// ─────────────────────────────────────────────────────────────

class _RecapHeader extends StatelessWidget {
  final String episodeId;
  const _RecapHeader({required this.episodeId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top rule
        Row(
          children: [
            Container(width: 32, height: 1, color: DreadmoorColors.accentRed),
            const SizedBox(width: 12),
            Text(
              'PREVIOUSLY IN',
              style: GoogleFonts.michroma(
                fontSize: 9,
                letterSpacing: 4,
                color: DreadmoorColors.accentRed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(height: 1, color: DreadmoorColors.accentRed),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'DREADMOOR',
          style: GoogleFonts.michroma(
            fontSize: 28,
            letterSpacing: 8,
            color: Colors.white,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          episodeId.toUpperCase().replaceAll('EP', 'EPISODE '),
          style: GoogleFonts.michroma(
            fontSize: 10,
            letterSpacing: 4,
            color: Colors.white.withOpacity(0.35),
          ),
        ),
        const SizedBox(height: 16),
        // Bottom rule
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Individual recap line
// ─────────────────────────────────────────────────────────────

class _RecapLineWidget extends StatelessWidget {
  final RecapLine line;
  const _RecapLineWidget({required this.line});

  @override
  Widget build(BuildContext context) {
    // Map line type to visual treatment
    return switch (line.type) {
      RecapLineType.category => _CategoryLabel(text: line.text),
      RecapLineType.cliffhanger => _CliffhangerLine(text: line.text),
      RecapLineType.choice => _ChoiceLine(text: line.text),
      RecapLineType.evidence => _EvidenceLine(text: line.text),
      RecapLineType.body => _BodyLine(text: line.text),
    };
  }
}

class _CategoryLabel extends StatelessWidget {
  final String text;
  const _CategoryLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 10,
            color: DreadmoorColors.accentRed,
            margin: const EdgeInsets.only(right: 10),
          ),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.michroma(
              fontSize: 8,
              letterSpacing: 3.5,
              color: DreadmoorColors.accentRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _CliffhangerLine extends StatelessWidget {
  final String text;
  const _CliffhangerLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: DreadmoorColors.accentRed, width: 2),
        ),
        color: DreadmoorColors.accentRed.withOpacity(0.06),
      ),
      child: Text(
        text,
        style: GoogleFonts.michroma(
          fontSize: 15,
          letterSpacing: 0.8,
          height: 1.6,
          color: Colors.white.withOpacity(0.95),
        ),
      ),
    );
  }
}

class _ChoiceLine extends StatelessWidget {
  final String text;
  const _ChoiceLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Icon(
            Icons.arrow_right_rounded,
            color: DreadmoorColors.accentCyan,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.sourceCodePro(
              fontSize: 13,
              height: 1.65,
              color: DreadmoorColors.accentCyan.withOpacity(0.85),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _EvidenceLine extends StatelessWidget {
  final String text;
  const _EvidenceLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.folder_outlined,
            color: Colors.white.withOpacity(0.35),
            size: 14,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.sourceCodePro(
                fontSize: 12,
                height: 1.6,
                color: Colors.white.withOpacity(0.55),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyLine extends StatelessWidget {
  final String text;
  const _BodyLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.sourceCodePro(
        fontSize: 14,
        height: 1.75,
        color: Colors.white.withOpacity(0.75),
        letterSpacing: 0.1,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Continue button
// ─────────────────────────────────────────────────────────────

class _ContinueButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _ContinueButton({required this.onPressed});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _hovered
                  ? DreadmoorColors.accentCyan
                  : Colors.white.withOpacity(0.25),
              width: 1,
            ),
            color: _hovered
                ? DreadmoorColors.accentCyan.withOpacity(0.08)
                : Colors.transparent,
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: DreadmoorColors.glowCyan.withOpacity(0.2),
                      blurRadius: 20,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'CONTINUE',
                style: GoogleFonts.michroma(
                  fontSize: 12,
                  letterSpacing: 4,
                  color: _hovered
                      ? DreadmoorColors.accentCyan
                      : Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.play_arrow_rounded,
                color: _hovered
                    ? DreadmoorColors.accentCyan
                    : Colors.white.withOpacity(0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Film perforations — decorative side strips
// ─────────────────────────────────────────────────────────────

class _FilmPerforations extends StatelessWidget {
  const _FilmPerforations();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PerforationPainter());
  }
}

class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.white.withOpacity(0.03);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final holePaint = Paint()..color = Colors.black;
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const holeH = 20.0;
    const holeW = 14.0;
    const gap = 16.0;
    final hx = (size.width - holeW) / 2;

    double y = 24;
    while (y + holeH < size.height) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(hx, y, holeW, holeH),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, holePaint);
      canvas.drawRRect(rect, borderPaint);
      y += holeH + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// Film grain painter — redraws on each tick for flicker
// ─────────────────────────────────────────────────────────────

class _FilmGrainPainter extends CustomPainter {
  final double seed;
  _FilmGrainPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    // Very subtle vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        radius: 1.1,
        colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignette);

    // Grain — pseudo-random dots based on seed
    final grainPaint = Paint()..color = Colors.white.withOpacity(0.03);
    final step = 4.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final noise = ((x * 1.3 + y * 7.9 + seed * 293) % 17) / 17;
        if (noise > 0.85) {
          canvas.drawCircle(Offset(x, y), 0.8, grainPaint);
        }
      }
    }

    // Horizontal scan flicker line
    final flickerY = size.height * ((seed * 0.618 + 0.1) % 1.0);
    canvas.drawRect(
      Rect.fromLTWH(0, flickerY, size.width, 1),
      Paint()..color = Colors.white.withOpacity(0.015),
    );
  }

  @override
  bool shouldRepaint(covariant _FilmGrainPainter old) => old.seed != seed;
}

// ─────────────────────────────────────────────────────────────
// Loading / Error states
// ─────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: DreadmoorColors.accentRed,
              strokeWidth: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'RETRIEVING CASE FILES...',
            style: GoogleFonts.michroma(
              fontSize: 9,
              letterSpacing: 3,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'SIGNAL LOST',
        style: GoogleFonts.michroma(
          fontSize: 11,
          letterSpacing: 4,
          color: DreadmoorColors.accentRed.withOpacity(0.7),
        ),
      ),
    );
  }
}
