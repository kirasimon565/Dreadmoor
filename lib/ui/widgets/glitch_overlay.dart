import 'dart:math';
import 'package:flutter/material.dart';

class GlitchOverlay extends StatefulWidget {
  final Duration duration;
  final VoidCallback onComplete;

  const GlitchOverlay({
    super.key,
    required this.duration,
    required this.onComplete,
  });

  @override
  State<GlitchOverlay> createState() => _GlitchOverlayState();
}

class _GlitchOverlayState extends State<GlitchOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Fade out in the last 200ms
        final timeRemaining = widget.duration.inMilliseconds * (1 - _controller.value);
        final opacity = timeRemaining < 200 ? timeRemaining / 200 : 1.0;

        return Opacity(
          opacity: opacity,
          child: CustomPaint(
            painter: _GlitchPainter(_controller.value, _rng),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _GlitchPainter extends CustomPainter {
  final double progress;
  final Random _baseRng;

  _GlitchPainter(this.progress, this._baseRng);

  @override
  void paint(Canvas canvas, Size size) {
    // We update slices rapidly based on time (tick interval approx 60ms)
    final tick = (progress * 1000 ~/ 60);

    // Create a deterministic RNG based on the tick, so it only changes every 60ms
    final seededRng = Random(tick);

    // 3 to 5 slices
    final sliceCount = seededRng.nextInt(3) + 3;

    for (int i = 0; i < sliceCount; i++) {
      // Random slice height and position
      final height = seededRng.nextDouble() * 40 + 10;
      final y = seededRng.nextDouble() * (size.height - height);

      // Horizontal shift ±8 to 18px
      final shift = (seededRng.nextDouble() * 10 + 8) * (seededRng.nextBool() ? 1 : -1);

      // We don't have the background pixels easily in Flutter without a RepaintBoundary.
      // Instead we use a ShaderMask approach or we draw glitchy semi-transparent blocks to simulate it.
      // As per specs: "Red channel shift: 4px". We draw red and cyan semi-transparent rects.

      final paintRed = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..blendMode = BlendMode.screen;

      final paintCyan = Paint()
        ..color = Colors.cyan.withOpacity(0.5)
        ..blendMode = BlendMode.screen;

      // Draw red shifted left, cyan shifted right
      canvas.drawRect(Rect.fromLTWH(shift - 4, y, size.width, height), paintRed);
      canvas.drawRect(Rect.fromLTWH(shift + 4, y, size.width, height), paintCyan);

      // Draw some static noise lines
      final noisePaint = Paint()
        ..color = Colors.white.withOpacity(seededRng.nextDouble() * 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, y + seededRng.nextDouble() * height, size.width, 2), noisePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlitchPainter oldDelegate) {
    // Determine the tick of the old delegate and current delegate
    final oldTick = (oldDelegate.progress * 1000 ~/ 60);
    final newTick = (progress * 1000 ~/ 60);

    // Only repaint if the 60ms tick boundary has been crossed
    return oldTick != newTick;
  }
}
