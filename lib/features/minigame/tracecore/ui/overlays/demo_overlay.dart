// lib/features/minigame/tracecore/ui/overlays/demo_overlay.dart
//
// Renders a semi-transparent dark layer over the screen with:
//   • A glowing highlight rectangle around the target area
//   • A caption card explaining what to do
//   • A pulsing arrow pointing at the target
//
// Layout zones (approximate, fixed for the TracecoreScreen layout):
//   TAB_BAR   → top strip (y: ~0–48)
//   CHAT_TAB  → left third of tab bar
//   NET_TAB   → centre third of tab bar
//   DB_TAB    → right third of tab bar
//   PANEL     → main content area (y: ~48–bottom-130)
//   SUBMIT    → bottom bar (y: ~bottom-90 to bottom-48)
//   TIMER     → very bottom strip

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../tracecore_controller.dart';
import '../../tracecore_state.dart';

class DemoOverlay extends ConsumerStatefulWidget {
  const DemoOverlay({super.key});

  @override
  ConsumerState<DemoOverlay> createState() => _DemoOverlayState();
}

class _DemoOverlayState extends ConsumerState<DemoOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(tracecoreProvider).demoStep;
    final size = MediaQuery.of(context).size;

    final cfg = _configFor(step, size);
    if (cfg == null) return const SizedBox.shrink();

    return Stack(
      children: [

        // Dark overlay with hole
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _HolePainter(
                hole:    cfg.highlight,
                opacity: 0.78,
                glowOpacity: _pulseAnim.value,
              ),
            ),
          ),
        ),

        // Caption card
        Positioned(
          left:  16,
          right: 16,
          top:   cfg.captionTop,
          child: _CaptionCard(text: cfg.caption),
        ),

        // Pulsing arrow
        if (cfg.arrowOffset != null)
          Positioned(
            left: cfg.highlight.left +
                cfg.highlight.width / 2 +
                (cfg.arrowOffset!.dx) - 12,
            top:  cfg.highlight.top +
                cfg.highlight.height / 2 +
                (cfg.arrowOffset!.dy) - 12,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Opacity(
                opacity: _pulseAnim.value,
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  color: Color(0xFF00FF41),
                  size:  24,
                ),
              ),
            ),
          ),
      ],
    );
  }

  _DemoConfig? _configFor(DemoStep step, Size size) {
    final w = size.width;
    final h = size.height;

    // Fixed layout measurements for TracecoreScreen
    const headerH = 44.0;  // TRACECORE header
    const tabH    = 44.0;  // tab bar
    const submitH = 64.0;  // submit bar
    const timerH  = 44.0;  // timer bar
    final panelTop = headerH + tabH;
    final panelBot = h - submitH - timerH;

    switch (step) {
      case DemoStep.intro:
        // Highlight the CHAT tab (left third of tab bar)
        return _DemoConfig(
          highlight: Rect.fromLTWH(0, headerH, w / 3, tabH),
          caption:   '"Start by reading the chat logs."',
          captionTop: headerH + tabH + 16,
          arrowOffset: const Offset(0, -30),
        );

      case DemoStep.chatPanel:
        // Highlight full chat panel area
        return _DemoConfig(
          highlight:   Rect.fromLTWH(0, panelTop, w, panelBot - panelTop),
          caption:     '"Clues are hidden in conversations.\nLook for location hints."',
          captionTop:  panelBot - 100,
          arrowOffset: null,
        );

      case DemoStep.networkTab:
        // Highlight NETWORK tab (centre third)
        return _DemoConfig(
          highlight:   Rect.fromLTWH(w / 3, headerH, w / 3, tabH),
          caption:     '"Now check the network activity."',
          captionTop:  headerH + tabH + 16,
          arrowOffset: const Offset(0, -30),
        );

      case DemoStep.networkPanel:
        return _DemoConfig(
          highlight:   Rect.fromLTWH(0, panelTop, w, panelBot - panelTop),
          caption:     '"Match the location clue to an IP address."',
          captionTop:  panelBot - 100,
          arrowOffset: null,
        );

      case DemoStep.databaseTab:
        // Highlight DATABASE tab (right third)
        return _DemoConfig(
          highlight:   Rect.fromLTWH(w * 2 / 3, headerH, w / 3, tabH),
          caption:     '"Check the database to confirm the identity."',
          captionTop:  headerH + tabH + 16,
          arrowOffset: const Offset(0, -30),
        );

      case DemoStep.databasePanel:
        return _DemoConfig(
          highlight:   Rect.fromLTWH(0, panelTop, w, panelBot - panelTop),
          caption:     '"Find who matches the pattern."',
          captionTop:  panelBot - 100,
          arrowOffset: null,
        );

      case DemoStep.selection:
        // Highlight submit bar (IP + name chips)
        return _DemoConfig(
          highlight:   Rect.fromLTWH(0, h - submitH - timerH, w * 0.7, submitH),
          caption:     '"Select the correct IP and identity."',
          captionTop:  h - submitH - timerH - 80,
          arrowOffset: const Offset(0, 20),
        );

      case DemoStep.submit:
        // Highlight submit button (right ~30% of submit bar)
        return _DemoConfig(
          highlight:   Rect.fromLTWH(w * 0.7, h - submitH - timerH, w * 0.3, submitH),
          caption:     '"Submit your answer."',
          captionTop:  h - submitH - timerH - 80,
          arrowOffset: const Offset(0, 20),
        );

      case DemoStep.complete:
        return null; // result overlay takes over

      default:
        return null;
    }
  }
}

// ── Config ────────────────────────────────────────────────────────────────────

class _DemoConfig {
  final Rect    highlight;
  final String  caption;
  final double  captionTop;
  final Offset? arrowOffset;

  const _DemoConfig({
    required this.highlight,
    required this.caption,
    required this.captionTop,
    required this.arrowOffset,
  });
}

// ── Hole Painter ──────────────────────────────────────────────────────────────

class _HolePainter extends CustomPainter {
  final Rect   hole;
  final double opacity;
  final double glowOpacity;

  _HolePainter({
    required this.hole,
    required this.opacity,
    required this.glowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dark mask
    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(4)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      maskPath,
      Paint()
        ..color = Colors.black.withOpacity(opacity)
        ..style = PaintingStyle.fill,
    );

    // Glow border around hole
    canvas.drawRRect(
      RRect.fromRectAndRadius(hole.inflate(1.5), const Radius.circular(5)),
      Paint()
        ..color       = const Color(0xFF00FF41).withOpacity(glowOpacity * 0.8)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter  = const MaskFilter.blur(BlurStyle.outer, 6),
    );
  }

  @override
  bool shouldRepaint(_HolePainter old) =>
      old.glowOpacity != glowOpacity || old.hole != hole;
}

// ── Caption Card ──────────────────────────────────────────────────────────────

class _CaptionCard extends StatelessWidget {
  final String text;
  const _CaptionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        const Color(0xFF001A00),
        border:       Border.all(color: const Color(0xFF2A5A2A)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.sourceCodePro(
          color:      const Color(0xFF00FF41),
          fontSize:   13,
          height:     1.55,
          fontStyle:  FontStyle.italic,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
