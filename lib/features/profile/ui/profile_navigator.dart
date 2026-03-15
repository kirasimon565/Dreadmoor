import 'package:flutter/material.dart';
import 'package:dreadmoor/ui/screens/profiles/player_profile_screen.dart';

/// FIX: The old ProfileNavigator wrapped ProfileScreen inside a
/// Navigator + PageRouteBuilder. That inserted a Material widget
/// with the default grey canvas colour ON TOP of ProfileScreen's
/// white Scaffold — hence the permanently grey profile tab.
///
/// This version renders ProfileScreen directly. No Navigator, no
/// PageRouteBuilder, no grey Material in between.
class ProfileNavigator extends StatelessWidget {
  const ProfileNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
