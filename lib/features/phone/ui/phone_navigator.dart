import 'package:flutter/material.dart';

import 'package:dreadmoor/features/phone/ui/screens/phone/phone_app_screen.dart';

class PhoneRoutes {
  static const dialpad = '/';
  static const call = '/call';
}

class PhoneNavigator extends StatelessWidget {
  const PhoneNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: PhoneRoutes.dialpad,
      onGenerateRoute: (settings) {
        if (settings.name == PhoneRoutes.dialpad) {
          return MaterialPageRoute(builder: (_) => const PhoneAppScreen());
        }
        return null;
      },
    );
  }
}
