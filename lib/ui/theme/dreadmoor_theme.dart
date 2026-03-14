import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class DreadmoorTheme {
  // --- STATIC STYLES FOR UI HELPERS ---

  static TextStyle headingStyle(Brightness b) => GoogleFonts.spectral(
        color: DreadmoorColors.text(b),
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      );

  static TextStyle bodyStyle(Brightness b) => GoogleFonts.spaceGrotesk(
        color: DreadmoorColors.text(b),
      );

  // --- LIGHT THEME: THE ARCHIVE (Yellow Newspaper) ---

  static ThemeData get lightTheme {
    return _buildTheme(Brightness.light);
  }

  // --- DARK THEME: THE SLATE (Blue-Gray Tactical) ---

  static ThemeData get darkTheme {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bgColor = DreadmoorColors.background(brightness);
    final cardColor = DreadmoorColors.surface(brightness);
    final textColor = DreadmoorColors.text(brightness);
    final accent = isDark ? DreadmoorColors.investigatorCyan : DreadmoorColors.evidenceRed;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      cardColor: cardColor,

      // TYPOGRAPHY
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.spectral(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(color: textColor, fontSize: 16),
        bodyMedium: GoogleFonts.spaceGrotesk(color: textColor, fontSize: 14),
        labelLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 1.2,
        ),
      ),

      // APP BAR (Matches your OS Header needs)
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spectral(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),

      // CARDS (Floating Card Design from your screenshot)
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: DreadmoorColors.divider(brightness), width: 0.5),
        ),
      ),

      // TABS (Used in Profiles)
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: textColor.withOpacity(0.5),
        indicatorColor: accent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 12),
      ),

      // INPUTS (Search/Data entry)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DreadmoorColors.divider(brightness)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),

      // REMOVE RIPPLES FOR IMMERSION
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,

      // NO ANIMATIONS BETWEEN APPS (Feels like an OS)
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: NoTransitionsBuilder(),
          TargetPlatform.iOS: NoTransitionsBuilder(),
        },
      ),
    );
  }
}

// --- TRANSITION KILLER ---
class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}
