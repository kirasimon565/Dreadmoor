import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the main apps available in the Dreadmoor phone OS.
/// These correspond to the tabs shown in the bottom navigation bar.
enum PhoneApp {
  messenger,
  browser,
  phone,
  apps,
  diary,
  profile,
}

/// Controls which main phone app is currently visible.
/// The OS uses this to switch the IndexedStack screen.
class ActiveAppNotifier extends Notifier<PhoneApp> {
  @override
  PhoneApp build() => PhoneApp.messenger;

  void setApp(PhoneApp app) => state = app;
}
final activeAppProvider = NotifierProvider<ActiveAppNotifier, PhoneApp>(ActiveAppNotifier.new);

/// Controls the Glitch / Secret Intercept UI used in story events
/// such as Scene 5 when the phone is hacked.
class IsHackedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setHacked(bool hacked) => state = hacked;
}
final isHackedProvider = NotifierProvider<IsHackedNotifier, bool>(IsHackedNotifier.new);
