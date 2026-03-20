// lib/features/minigame/ghost_trace/components/network_node.dart

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../data/ghost_trace_constants.dart';

enum NodeState { idle, normal, suspect, attacker, traced }

class NetworkNode extends PositionComponent with TapCallbacks {
  final String nodeId;
  NodeState nodeState;
  final void Function(String) onTapped;

  double _pulseAngle = 0;
  bool   _glowing    = false;

  NetworkNode({
    required this.nodeId,
    required Vector2 position,
    required this.onTapped,
    this.nodeState = NodeState.idle,
  }) : super(
         position: position,
         size: Vector2.all(GhostTraceConstants.nodeRadius * 2),
         anchor: Anchor.center,
       );

  Color get _baseColor {
    switch (nodeState) {
      case NodeState.idle:     return GhostTraceColors.nodeIdle;
      case NodeState.normal:   return GhostTraceColors.nodeNormal;
      case NodeState.suspect:  return GhostTraceColors.nodeSuspect;
      case NodeState.attacker: return GhostTraceColors.nodeAttacker;
      case NodeState.traced:   return GhostTraceColors.nodeTraced;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseAngle += dt * 3.0;
    if (_pulseAngle > 2 * pi) _pulseAngle -= 2 * pi;
  }

  @override
  void render(Canvas canvas) {
    final r      = GhostTraceConstants.nodeRadius;
    final center = Offset(r, r);
    final color  = _baseColor;

    // Outer glow ring
    final pulse = (sin(_pulseAngle) + 1) / 2; // 0→1
    final glowRadius = r + 6 + pulse * 4;
    final glowPaint = Paint()
      ..color = color.withOpacity(0.18 + pulse * 0.12)
      ..style  = PaintingStyle.fill;
    canvas.drawCircle(center, glowRadius, glowPaint);

    // Main circle
    final fillPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style  = PaintingStyle.fill;
    canvas.drawCircle(center, r, fillPaint);

    // Border ring
    final borderPaint = Paint()
      ..color       = color
      ..style        = PaintingStyle.stroke
      ..strokeWidth  = 1.8;
    canvas.drawCircle(center, r, borderPaint);

    // Inner dot
    final dotPaint = Paint()
      ..color = color
      ..style  = PaintingStyle.fill;
    canvas.drawCircle(center, 4, dotPaint);

    // Node ID label
    final tp = TextPainter(
      text: TextSpan(
        text: nodeId.length > 4 ? nodeId.substring(0, 4) : nodeId,
        style: TextStyle(
          color:    color,
          fontSize: 8,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy + r + 3),
    );

    super.render(canvas);
  }

  @override
  bool onTapDown(TapDownEvent event) {
    onTapped(nodeId);
    return true;
  }

  void flash() {
    _glowing = true;
  }
}
