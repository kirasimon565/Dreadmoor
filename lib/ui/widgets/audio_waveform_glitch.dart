import 'dart:math';
import 'package:flutter/material.dart';

class AudioWaveformGlitch extends StatefulWidget {
  final bool isPlaying;

  const AudioWaveformGlitch({super.key, this.isPlaying = true});

  @override
  State<AudioWaveformGlitch> createState() => _AudioWaveformGlitchState();
}

class _AudioWaveformGlitchState extends State<AudioWaveformGlitch> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Loops every 3 seconds for glitch trigger
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AudioWaveformGlitch old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !old.isPlaying) {
      _controller.repeat();
    } else if (!widget.isPlaying && old.isPlaying) {
      _controller.stop();
    }
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
        // The spec asks for a glitch at 3-second intervals.
        // We'll consider a "glitch state" to be true for the last 200ms of the 3s loop.
        final isGlitching = _controller.value > 0.93;

        return CustomPaint(
          size: const Size(double.infinity, 100),
          painter: _WaveformPainter(
            progress: _controller.value,
            isGlitching: isGlitching,
            rng: _rng,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final bool isGlitching;
  final Random rng;

  _WaveformPainter({
    required this.progress,
    required this.isGlitching,
    required this.rng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 4.0;
    final spacing = 3.0;
    final count = (size.width / (barWidth + spacing)).floor();

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.cyan.withOpacity(0.6);

    final glitchPaintRed = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red.withOpacity(0.7)
      ..blendMode = BlendMode.screen;

    final centerY = size.height / 2;

    for (int i = 0; i < count; i++) {
      // Create a smooth, animated sine wave foundation
      final phase = progress * 2 * pi;
      final xOffset = (i / count) * 4 * pi;
      final baseHeight = sin(phase + xOffset).abs() * 30 + 10;

      // Add randomness for audio-like flickering
      var height = baseHeight + rng.nextDouble() * 20;

      if (isGlitching) {
        // Exaggerate height and jitter during glitch
        if (rng.nextBool()) {
          height += rng.nextDouble() * 40;
        }

        final x = i * (barWidth + spacing);
        final shift = rng.nextDouble() * 10 - 5;

        canvas.drawRect(
          Rect.fromLTWH(x + shift - 2, centerY - height / 2, barWidth, height),
          glitchPaintRed,
        );
      } else {
        final x = i * (barWidth + spacing);
        canvas.drawRect(
          Rect.fromLTWH(x, centerY - height / 2, barWidth, height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) => true;
}
