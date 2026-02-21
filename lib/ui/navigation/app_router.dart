import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import '../../ui/screens/studio_intro_screen.dart';
import '../../ui/screens/player_setup_screen.dart';
import '../../ui/screens/welcome_screen.dart';
import '../../ui/screens/messenger_list_screen.dart';
import '../../ui/screens/chat_screen.dart';
import '../../ui/screens/secret_chat_screen.dart';
import '../../ui/screens/detective_board_screen.dart';
import '../../ui/screens/diary_viewer_screen.dart';
import '../../ui/screens/character_profile_screen.dart';
import '../../ui/screens/player_profile_screen.dart';
import '../../ui/screens/map_screen.dart';
import '../../ui/screens/episode_select_screen.dart';
import '../../ui/screens/recap_screen.dart';
import '../../ui/screens/settings_screen.dart';
import '../../ui/screens/save_load_screen.dart';
import '../../ui/screens/credits_screen.dart';
import '../../ui/screens/legal_disclaimer_screen.dart';
import '../../ui/screens/debug/debug_screen.dart';

/// A custom helper to apply a cinematic fade-and-scale transition.
/// This removes the "standard phone" slide effect and replaces it with a moody atmosphere.
CustomTransitionPage noirTransition(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 500), // Slightly slower for drama
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.05, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => noirTransition(context, state, const StudioIntroScreen()),
      ),
      GoRoute(
        path: '/setup',
        pageBuilder: (context, state) => noirTransition(context, state, const PlayerSetupScreen()),
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => noirTransition(context, state, const WelcomeScreen()),
      ),
      GoRoute(
        path: '/messenger',
        pageBuilder: (context, state) => noirTransition(context, state, const MessengerListScreen()),
        routes: [
          GoRoute(
            path: 'chat/:threadId',
            pageBuilder: (context, state) {
              final threadId = state.pathParameters['threadId']!;
              return noirTransition(context, state, ChatScreen(threadId: threadId));
            },
          ),
          GoRoute(
            path: 'secret/:threadId',
            pageBuilder: (context, state) {
              final threadId = state.pathParameters['threadId']!;
              return noirTransition(context, state, SecretChatScreen(threadId: threadId));
            },
          ),
        ],
      ),
      GoRoute(
        path: '/detective',
        pageBuilder: (context, state) => noirTransition(context, state, const DetectiveBoardScreen()),
      ),
      GoRoute(
        path: '/diary',
        pageBuilder: (context, state) => noirTransition(context, state, const DiaryViewerScreen()),
      ),
      GoRoute(
        path: '/profile/:characterId',
        pageBuilder: (context, state) {
          final characterId = state.pathParameters['characterId']!;
          return noirTransition(context, state, CharacterProfileScreen(characterId: characterId));
        },
      ),
      GoRoute(
        path: '/player_profile',
        pageBuilder: (context, state) => noirTransition(context, state, const PlayerProfileScreen()),
      ),
      GoRoute(
        path: '/map',
        pageBuilder: (context, state) => noirTransition(context, state, const MapScreen()),
      ),
      GoRoute(
        path: '/episodes',
        pageBuilder: (context, state) => noirTransition(context, state, const EpisodeSelectScreen()),
      ),
      GoRoute(
        path: '/recap',
        pageBuilder: (context, state) => noirTransition(context, state, const RecapScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => noirTransition(context, state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/saveload',
        pageBuilder: (context, state) => noirTransition(context, state, const SaveLoadScreen()),
      ),
      GoRoute(
        path: '/credits',
        pageBuilder: (context, state) => noirTransition(context, state, const CreditsScreen()),
      ),
      GoRoute(
        path: '/legal',
        pageBuilder: (context, state) => noirTransition(context, state, const LegalDisclaimerScreen()),
      ),
      GoRoute(
        path: '/debug',
        pageBuilder: (context, state) => noirTransition(context, state, const DebugScreen()),
      ),
    ],
  );
});
