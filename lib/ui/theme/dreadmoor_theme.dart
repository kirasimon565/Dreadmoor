import 'package:flutter/material.dart';
import 'colors.dart';

class DreadmoorTheme {
  static ThemeData get darkTheme {
    const baseText = TextTheme(
      bodyMedium: TextStyle(color: DreadmoorColors.textPrimary),
      bodySmall: TextStyle(color: DreadmoorColors.textSecondary),
      titleMedium: TextStyle(color: DreadmoorColors.textPrimary),
      labelMedium: TextStyle(color: DreadmoorColors.textMeta),
    );

    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.dark,

      scaffoldBackgroundColor: DreadmoorColors.background,

      colorScheme: const ColorScheme.dark(
        primary: DreadmoorColors.accentCyan,
        error: DreadmoorColors.accentRed,
        surface: DreadmoorColors.surface,
        onPrimary: Colors.black,
        onSurface: Colors.white,
      ),

      textTheme: baseText,

      /// Remove Android ripple animations
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: NoTransitionsBuilder(),
          TargetPlatform.iOS: NoTransitionsBuilder(),
          TargetPlatform.linux: NoTransitionsBuilder(),
          TargetPlatform.macOS: NoTransitionsBuilder(),
          TargetPlatform.windows: NoTransitionsBuilder(),
        },
      ),

      /// Cursor & selection
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: DreadmoorColors.accentCyan,
        selectionColor: Color(0x3300FFD1),
        selectionHandleColor: DreadmoorColors.accentCyan,
      ),

      /// Icons
      iconTheme: const IconThemeData(color: Colors.white70, size: 22),

      /// AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      /// Cards
      cardTheme: CardThemeData(
        color: DreadmoorColors.surface.withOpacity(0.85),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: DreadmoorColors.borderSubtle.withOpacity(0.6),
            width: 0.6,
          ),
        ),
      ),

      /// Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(
            DreadmoorColors.accentCyan.withOpacity(0.15),
          ),
          foregroundColor: const MaterialStatePropertyAll(Colors.white),
          overlayColor: const MaterialStatePropertyAll(Colors.transparent),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),

      /// Bottom navigation
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DreadmoorColors.surface.withOpacity(0.9),
        indicatorColor: DreadmoorColors.accentCyan.withOpacity(0.2),
        labelTextStyle: const MaterialStatePropertyAll(
          TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ),

      /// Dividers
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.08),
        thickness: 0.6,
        space: 24,
      ),

      /// Dialogs
      dialogTheme: const DialogThemeData(
        backgroundColor: DreadmoorColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      /// Bottom sheets
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: DreadmoorColors.surface,
        modalBackgroundColor: DreadmoorColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      /// Snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DreadmoorColors.surface.withOpacity(0.95),
        contentTextStyle: const TextStyle(color: DreadmoorColors.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),

      /// Tooltips
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: DreadmoorColors.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(
          color: DreadmoorColors.textPrimary,
          fontSize: 12,
        ),
      ),

      /// Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DreadmoorColors.surface.withOpacity(0.6),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.12),
            width: 0.6,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.12),
            width: 0.6,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: DreadmoorColors.accentCyan,
            width: 1,
          ),
        ),

        hintStyle: const TextStyle(color: DreadmoorColors.textMeta),
      ),
    );
  }
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
