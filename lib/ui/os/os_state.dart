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

final activeAppProvider = StateProvider<PhoneApp>((ref) {
  return PhoneApp.messenger;
});
