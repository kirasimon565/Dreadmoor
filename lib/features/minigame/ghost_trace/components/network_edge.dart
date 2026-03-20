// lib/features/minigame/ghost_trace/components/network_edge.dart

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../data/ghost_trace_constants.dart';

class NetworkEdge extends Component {
  final Vector2 from;
  final Vector2 to;
  bool isActive;

  NetworkEdge({
    required this.from,
    required this.to,
    this.isActive = false,
  });

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color      = isActive
          ? GhostTraceColors.edgeActive
          : GhostTraceColors.edgeNormal
      ..strokeWidth = GhostTraceConstants.edgeStrokeWidth
      ..style       = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(from.x, from.y),
      Offset(to.x,   to.y),
      paint,
    );

    super.render(canvas);
  }
}
