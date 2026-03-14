// ─────────────────────────────────────────────────────────────────────────────
// PATCH: media_viewer.dart — change open() return type from void to Future<void>
//
// Find this line (~line 35):
//   static void open(
//
// Replace with:
//   static Future<void> open(
//
// The method body is unchanged. Navigator.push() already returns Future<T?>,
// so adding 'return' in front of the Navigator call is all that is needed.
//
// Full corrected method:
// ─────────────────────────────────────────────────────────────────────────────

  static Future<void> open(              // ← was: static void open(
    BuildContext context, {
    required List<MediaItem> items,
    int initialIndex = 0,
  }) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(   // ← was: Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => MediaViewer(
          items: items,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }
