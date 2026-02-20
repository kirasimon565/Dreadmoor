import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DreadmoorColors {
  static const Color background = Color(0xFF121212); // Almost black
  static const Color surface = Color(0xFF1E1E1E); // Dark grey
  static const Color primary = Color(0xFFBB86FC); // Purple (Noir/Cyberpunk feel)
  static const Color secondary = Color(0xFF03DAC6); // Teal
  static const Color error = Color(0xFFCF6679);
  static const Color onBackground = Color(0xFFE0E0E0);
  static const Color onSurface = Color(0xFFE0E0E0);
  static const Color neonBlue = Color(0xFF00FFFF);
  static const Color neonPink = Color(0xFFFF00FF);
  static const Color fogGrey = Color(0xFF2C2C2C);
}

class DreadmoorTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DreadmoorColors.background,
      colorScheme: const ColorScheme.dark(
        primary: DreadmoorColors.primary,
        secondary: DreadmoorColors.secondary,
        surface: DreadmoorColors.surface,
        background: DreadmoorColors.background,
        error: DreadmoorColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: DreadmoorColors.onSurface,
        onBackground: DreadmoorColors.onBackground,
        onError: Colors.black,
      ),
      fontFamily: GoogleFonts.merriweather().fontFamily, // Fallback/Body font
      textTheme: TextTheme(
        displayLarge: GoogleFonts.cinzel( // Noir Display
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: DreadmoorColors.onBackground,
          letterSpacing: 1.5,
        ),
        displayMedium: GoogleFonts.cinzel(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: DreadmoorColors.onBackground,
        ),
        bodyLarge: GoogleFonts.merriweather(
          fontSize: 16,
          color: DreadmoorColors.onBackground,
        ),
        bodyMedium: GoogleFonts.merriweather(
          fontSize: 14,
          color: DreadmoorColors.onBackground.withOpacity(0.8),
        ),
      ),
    );
  }
}
