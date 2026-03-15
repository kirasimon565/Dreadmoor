import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PhoneApp {
  messenger,
  browser,
  phone,
  apps,
  puzzle,
  profile,
  // store removed — not needed
}

/// Controls which app is currently visible in the IndexedStack.
final activeAppProvider = StateProvider<PhoneApp>((ref) {
  return PhoneApp.messenger;
});

/// Controls the Glitch/Secret Intercept UI (Scene 5).
final isHackedProvider = StateProvider<bool>((ref) => false);

/// Controls whether the bottom navigation bar is visible.
final showNavigationBarProvider = StateProvider<bool>((ref) => true);
