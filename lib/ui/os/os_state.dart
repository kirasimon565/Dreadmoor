import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PhoneApp {
  messenger,
  browser,
  phone,
  apps,
  store,
  puzzle,
  profile,
}

/// Controls which app is currently visible in the IndexedStack
final activeAppProvider = StateProvider<PhoneApp>((ref) {
  return PhoneApp.messenger;
});

/// Controls the Glitch/Secret Intercept UI (Used in Scene 5)
final isHackedProvider = StateProvider<bool>((ref) {
  return false;
});

/// Controls whether the bottom navigation bar is visible
final showNavigationBarProvider = StateProvider<bool>((ref) {
  return true;
});
