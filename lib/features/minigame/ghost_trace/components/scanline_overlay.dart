// lib/features/minigame/ghost_trace/components/scanline_overlay.dart

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../data/ghost_trace_constants.dart';

class ScanlineOverlay extends PositionComponent {
  double _scrollOffset = 0;

  ScanlineOverlay({required Vector2 canvasSize})
      : super(size: canvasSize, position: Vector2.zero());

  @override
  void update(double dt) {
    super.update(dt);
    _scrollOffset += dt * 30;
    if (_scrollOffset > GhostTraceConstants.scanlineCount) {
      _scrollOffset = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    final h    = size.y;
    final w    = size.x;
    final gap  = h / GhostTraceConstants.scanlineCount;
    final paint = Paint()
      ..color       = GhostTraceColors.scanline
      ..strokeWidth = 1.0;

    for (int i = 0; i < GhostTraceConstants.scanlineCount; i++) {
      final y = (i * gap + _scrollOffset) % h;
      canvas.drawLine(Offset(0, y), Offset(w, y), paint);
    }

    // Vignette
    final vignette = RadialGradient(
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(0.55),
      ],
      stops: const [0.6, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = vignette..blendMode = BlendMode.multiply,
    );

    super.render(canvas);
  }
}
