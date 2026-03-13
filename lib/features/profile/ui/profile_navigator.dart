import 'package:flutter/material.dart';
import 'package:dreadmoor/ui/screens/profiles/player_profile_screen.dart';

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
          // Use a Fade transition for the Player Profile to make it feel like 
          // a deep-level OS system loading up.
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const PlayerProfileScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        }
        return null;
      },
    );
  }
}
