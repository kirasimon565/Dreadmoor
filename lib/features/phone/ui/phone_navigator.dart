import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/features/phone/ui/screens/phone/phone_app_screen.dart';
import 'package:dreadmoor/features/phone/ui/screens/call/incoming_call_screen.dart';
import 'package:dreadmoor/features/phone/phone_state.dart';

class PhoneRoutes {
  static const dialpad = '/';
  static const call = '/call';
}

class PhoneNavigator extends ConsumerWidget {
  const PhoneNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for incoming calls to trigger the overlay automatically
    ref.listen<PhoneState>(phoneProvider, (previous, next) {
      if (next.callState == CallState.incoming && 
          previous?.callState != CallState.incoming) {
        // Navigate to the full-screen call UI within this local navigator
        Navigator.of(context).pushNamed(PhoneRoutes.call);
      } else if (next.callState == CallState.idle && 
                 previous?.callState != CallState.idle) {
        // Return to dialpad when call ends or is declined
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    return Navigator(
      initialRoute: PhoneRoutes.dialpad,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case PhoneRoutes.dialpad:
            return _noTransitionRoute(const PhoneAppScreen());
          case PhoneRoutes.call:
            return _noTransitionRoute(IncomingCallScreen(callerName: 'Unknown', callerNumber: '0000', onAccept: (){}, onDecline: (){}));
          default:
            return null;
        }
      },
    );
  }

  /// Instant switching for a seamless OS experience
  Route _noTransitionRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }
}
