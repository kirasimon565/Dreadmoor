import 'package:flutter/material.dart';

import 'package:dreadmoor/features/messenger/ui/screens/messenger_list/messenger_list_screen.dart';
import 'package:dreadmoor/features/messenger/ui/screens/chat/chat_screen.dart';
import 'package:dreadmoor/features/messenger/ui/screens/secret_chat/secret_chat_screen.dart';
import 'package:dreadmoor/features/messenger/ui/screens/settings/settings_screen.dart';
import 'package:dreadmoor/ui/screens/profiles/character_profile_screen.dart';

class MessengerRoutes {
  static const list = '/';
  static const chat = '/chat';
  static const secret = '/secret';
  static const profile = '/profile/character';
  static const settings = '/settings';
}

class MessengerNavigator extends StatelessWidget {
  const MessengerNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: MessengerRoutes.list,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case MessengerRoutes.list:
            return _noTransitionRoute(const MessengerListScreen());

          case MessengerRoutes.chat:
            final threadId = settings.arguments as String;
            // Full-screen Chat with the Red Quill Input
            return _noTransitionRoute(ChatScreen(threadId: threadId));

          case MessengerRoutes.secret:
            final threadId = settings.arguments as String;
            return _noTransitionRoute(SecretChatScreen(threadId: threadId));

          case MessengerRoutes.profile:
            final threadId = settings.arguments as String;
            // The Case File overlaps from the bottom (Slide Up)
            return _slideUpRoute(CharacterProfileScreen(threadId: threadId));

          case MessengerRoutes.settings:
            return _noTransitionRoute(const SettingsScreen());

          default:
            return null;
        }
      },
    );
  }

  /// OS-style instant switching for apps and chats
  Route _noTransitionRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }

  /// Dramatic "Open Case File" animation for character profiles
  Route _slideUpRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutQuart; // Smooth, heavy deceleration
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
