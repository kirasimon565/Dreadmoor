import 'package:flutter/material.dart';

abstract final class DreadmoorColors {
  // Core surfaces
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF111111);
  static const surfaceAlt = Color(0xFF0D0D0D);

  // Glass UI
  static const surfaceGlass = Color(0x0AFFFFFF); // 4% white
  static const borderGlass = Color(0x14FFFFFF); // 8% white
  static const scrimDark = Color(0x99000000);   // 60% black overlay

  // Accents
  static const accentCyan = Color(0xFF00FFD1);
  static const accentRed = Color(0xFFFF003C);

  // Text
  static const textPrimary = Color(0xDEFFFFFF);   // 87% white
  static const textSecondary = Color(0x73FFFFFF); // 45% white
  static const textMeta = Color(0x59FFFFFF);      // 35% white
  static const textDisabled = Color(0x40FFFFFF);  // 25% white

  // Dividers / borders
  static const divider = Color(0x14FFFFFF);       // 8% white
  static const borderSubtle = Color(0x1FFFFFFF);  // ~12% white

  // Glows
  static const glowCyan = Color(0x3300FFD1); // 20% cyan for shadows
  static const glowRed = Color(0x33FF003C);

  // Status (mapped to your accents)
  static const success = accentCyan;
  static const error = accentRed;
  static const warning = Color(0xFFFFB703); // muted amber for noir

  // Utility (optional helper)
  static Color withOpacity(Color base, double opacity) =>
      base.withOpacity(opacity.clamp(0.0, 1.0));
}
