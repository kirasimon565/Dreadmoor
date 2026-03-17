import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the main apps available in the Dreadmoor phone OS.
/// These correspond to the tabs shown in the bottom navigation bar.
enum PhoneApp {
  messenger,
  browser,
  phone,
  apps,
  puzzle,
  profile,
}

/// Controls which main phone app is currently visible.
/// The OS uses this to switch the IndexedStack screen.
final activeAppProvider = StateProvider<PhoneApp>((ref) {
  return PhoneApp.messenger;
});

/// Controls the Glitch / Secret Intercept UI used in story events
/// such as Scene 5 when the phone is hacked.
final isHackedProvider = StateProvider<bool>((ref) => false);
