import 'package:flutter/material.dart';

/// ------------------------------------------------------------
/// DREADMOOR DESIGN SYSTEM 2026
/// ------------------------------------------------------------
/// Light Mode: "The Archive" - Old newspaper, sepia, ink.
/// Dark Mode: "The Tactical OS" - Slate blue, muted gray, high-tech.
/// ------------------------------------------------------------

abstract final class DreadmoorColors {
  // --------------------------------------------------
  // LIGHT MODE: NEWSPAPER YELLOW
  // --------------------------------------------------
  static const paperBackground = Color(0xFFF4ECD8); // Aged Parchment
  static const paperCard = Color(0xFFFAF6E9);       // Clean Newsprint
  static const inkPrimary = Color(0xFF2B2B2B);      // Carbon Ink
  static const inkSecondary = Color(0xFF5D5D5D);    // Faded Print
  static const paperBorder = Color(0xFFD9CFB5);     // Pressed Crease
  
  // --------------------------------------------------
  // DARK MODE: SLATE BLUE-GRAY
  // --------------------------------------------------
  static const slateBackground = Color(0xFF1E252B); // Muted Slate
  static const slateSurface = Color(0xFF2A3239);    // Steel Panel
  static const slateHeader = Color(0xFF161C21);     // Deep Graphite
  static const slateText = Color(0xFFE1E4E7);       // Off-White
  static const slateTextDim = Color(0xFF8F9BA3);    // Steel Gray
  static const slateBorder = Color(0xFF38434D);     // Metallic Edge

  // --------------------------------------------------
  // SHARED ACCENTS (Visual Identity)
  // --------------------------------------------------
  static const evidenceRed = Color(0xFFB71C1C);    // The "Media" Tag Red
  static const investigatorCyan = Color(0xFF00ACC1); // Modern Steel Blue
  static const cautionYellow = Color(0xFFFBC02D);   // Police Tape
  
  // --------------------------------------------------
  // HELPER: THEME RESOLVER
  // --------------------------------------------------
  
  /// Get background based on Brightness
  static Color background(Brightness b) => 
      b == Brightness.light ? paperBackground : slateBackground;

  /// Get surface/card color based on Brightness
  static Color surface(Brightness b) => 
      b == Brightness.light ? paperCard : slateSurface;

  /// Get primary text color based on Brightness
  static Color text(Brightness b) => 
      b == Brightness.light ? inkPrimary : slateText;

  /// Get divider color based on Brightness
  static Color divider(Brightness b) => 
      b == Brightness.light ? paperBorder : slateBorder;
}
