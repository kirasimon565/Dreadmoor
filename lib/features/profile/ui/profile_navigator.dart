import 'package:flutter/material.dart';

import 'package:dreadmoor/features/profile/ui/screens/player_profile_screen.dart';

class ProfileRoutes {
  static const player = '/';
}

class ProfileNavigator extends StatelessWidget {
  const ProfileNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: ProfileRoutes.player,
      onGenerateRoute: (settings) {
        if (settings.name == ProfileRoutes.player) {
          return MaterialPageRoute(builder: (_) => const PlayerProfileScreen());
        }
        return null;
      },
    );
  }
}
