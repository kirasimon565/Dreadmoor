// lib/features/minigame/ghost_trace/data/ghost_trace_constants.dart

import 'package:flutter/material.dart';

abstract final class GhostTraceColors {
  static const background   = Color(0xFF000000);
  static const gridLines    = Color(0xFF0A2A0A);
  static const nodeIdle     = Color(0xFF1A3A1A);
  static const nodeNormal   = Color(0xFF00FF41);
  static const nodeSuspect  = Color(0xFFFFB300);
  static const nodeAttacker = Color(0xFFFF1744);
  static const nodeTraced   = Color(0xFF00E5FF);
  static const edgeNormal   = Color(0xFF1A4A1A);
  static const edgeActive   = Color(0xFF00CC33);
  static const packetNormal = Color(0xFFCCCCCC);
  static const packetSuspect= Color(0xFFFFB300);
  static const packetEvil   = Color(0xFFFF1744);
  static const hudText      = Color(0xFF00FF41);
  static const hudDim       = Color(0xFF005A14);
  static const heartFull    = Color(0xFFFF1744);
  static const heartEmpty   = Color(0xFF3A0A0A);
  static const scanline     = Color(0x0A00FF41);
  static const glow         = Color(0x3300FF41);
}

abstract final class GhostTraceConstants {
  static const int    maxHearts          = 5;
  static const int    cooldownMinutes    = 10;
  static const double nodeRadius        = 22.0;
  static const double packetRadius      = 5.0;
  static const double edgeStrokeWidth   = 1.5;
  static const int    scanlineCount     = 80;
  static const double packetBaseSpeed   = 120.0; // px/s
  static const int    scrambleSnapMs    = 180;
}
