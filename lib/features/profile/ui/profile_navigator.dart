import 'package:flutter/material.dart';
import 'package:dreadmoor/ui/screens/profiles/player_profile_screen.dart';

/// Renders ProfileScreen directly — no Navigator wrapper.
///
/// The old version used a PageRouteBuilder which inserted its own
/// Material widget with the default grey background, painting over
/// ProfileScreen's white Scaffold. Removing the Navigator fixes
/// the permanently grey profile tab.
class ProfileNavigator extends StatelessWidget {
  const ProfileNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
