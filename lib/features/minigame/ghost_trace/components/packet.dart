// lib/features/minigame/ghost_trace/components/packet.dart

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../data/ghost_trace_constants.dart';

enum PacketType { normal, suspicious, malicious }

class Packet extends PositionComponent {
  final PacketType type;

  Packet({
    required Vector2 start,
    required Vector2 end,
    required this.type,
    required double speed,
    VoidCallback? onComplete,
  }) : super(
         position: start.clone(),
         size: Vector2.all(GhostTraceConstants.packetRadius * 2),
         anchor: Anchor.center,
       ) {
    final distance = start.distanceTo(end);
    final duration = distance / speed;

    add(
      MoveToEffect(
        end,
        EffectController(duration: duration),
        onComplete: () {
          onComplete?.call();
          removeFromParent();
        },
      ),
    );
  }

  Color get _color {
    switch (type) {
      case PacketType.normal:     return GhostTraceColors.packetNormal;
      case PacketType.suspicious: return GhostTraceColors.packetSuspect;
      case PacketType.malicious:  return GhostTraceColors.packetEvil;
    }
  }

  @override
  void render(Canvas canvas) {
    final r      = GhostTraceConstants.packetRadius;
    final center = Offset(r, r);

    // Glow
    canvas.drawCircle(
      center,
      r + 3,
      Paint()..color = _color.withOpacity(0.3)..style = PaintingStyle.fill,
    );

    // Core
    canvas.drawCircle(
      center,
      r,
      Paint()..color = _color..style = PaintingStyle.fill,
    );

    super.render(canvas);
  }
}
