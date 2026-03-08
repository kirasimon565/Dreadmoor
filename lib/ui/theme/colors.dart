import 'package:flutter/material.dart';

abstract final class DreadmoorColors {
  /// Core surfaces
  static const background = Color(0xFF1C1F26); // Dark Blue-Gray
  static const surface = Color(0xFF242830); // Charcoal
  static const surfaceAlt = Color(0xFF181A20); // Darker alternative

  /// Glass UI (Reduced, mostly for specific elements)
  static const surfaceGlass = Color(0x0AFFFFFF); // 4% white
  static const borderGlass = Color(0x14FFFFFF); // 8% white
  static const scrimDark = Color(0x99000000); // 60% black overlay

  /// Accent colors
  static const accentCyan = Color(0xFF00FFD1); // Cyan/Teal
  static const accentRed = Color(0xFFFF3C3C); // Muted Red

  /// Text colors
  static const textPrimary = Color(0xDEFFFFFF); // 87%
  static const textSecondary = Color(0x73FFFFFF); // 45%
  static const textMeta = Color(0x59FFFFFF); // 35%
  static const textDisabled = Color(0x40FFFFFF); // 25%

  /// Borders
  static const divider = Color(0x14FFFFFF);
  static const borderSubtle = Color(0x1FFFFFFF);

  /// Neon glow (Subtle, only for specific states)
  static const glowCyan = Color(0x1A00FFD1);
  static const glowRed = Color(0x1AFF3C3C);

  /// Status
  static const success = accentCyan;
  static const error = accentRed;
  static const warning = Color(0xFFFFB703);

  /// Utility
  static Color withOpacity(Color base, double opacity) {
    return base.withOpacity(opacity.clamp(0.0, 1.0));
  }
}
