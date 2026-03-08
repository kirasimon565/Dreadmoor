import 'package:flutter/material.dart';

import 'package:dreadmoor/features/messenger/ui/screens/messenger_list/messenger_list_screen.dart';
import 'package:dreadmoor/features/messenger/ui/screens/chat/chat_screen.dart';
import 'package:dreadmoor/features/messenger/ui/screens/secret_chat/secret_chat_screen.dart';
import 'package:dreadmoor/features/messenger/ui/screens/settings/settings_screen.dart';
import 'package:dreadmoor/features/profile/ui/screens/character_profile_screen.dart';

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
        if (settings.name == MessengerRoutes.list) {
          return MaterialPageRoute(builder: (_) => const MessengerListScreen());
        }
        if (settings.name == MessengerRoutes.chat) {
          final threadId = settings.arguments as String;
          return MaterialPageRoute(builder: (_) => ChatScreen(threadId: threadId));
        }
        if (settings.name == MessengerRoutes.secret) {
          final threadId = settings.arguments as String;
          return MaterialPageRoute(builder: (_) => SecretChatScreen(threadId: threadId));
        }
        if (settings.name == MessengerRoutes.profile) {
          final threadId = settings.arguments as String;
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => CharacterProfileScreen(threadId: threadId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.ease;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        }
        if (settings.name == MessengerRoutes.settings) {
          return MaterialPageRoute(builder: (_) => const SettingsScreen());
        }
        return null;
      },
    );
  }
}
