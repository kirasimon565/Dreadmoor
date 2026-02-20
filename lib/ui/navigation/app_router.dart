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

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const StudioIntroScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const PlayerSetupScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/messenger',
        builder: (context, state) => const MessengerListScreen(),
        routes: [
          GoRoute(
            path: 'chat/:threadId',
            builder: (context, state) {
              final threadId = state.pathParameters['threadId']!;
              return ChatScreen(threadId: threadId);
            },
          ),
          GoRoute(
            path: 'secret/:threadId',
            builder: (context, state) {
              final threadId = state.pathParameters['threadId']!;
              return SecretChatScreen(threadId: threadId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/detective',
        builder: (context, state) => const DetectiveBoardScreen(),
      ),
      GoRoute(
        path: '/diary',
        builder: (context, state) => const DiaryViewerScreen(),
      ),
      GoRoute(
        path: '/profile/:characterId',
        builder: (context, state) {
          final characterId = state.pathParameters['characterId']!;
          return CharacterProfileScreen(characterId: characterId);
        },
      ),
      GoRoute(
        path: '/player_profile',
        builder: (context, state) => const PlayerProfileScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/episodes',
        builder: (context, state) => const EpisodeSelectScreen(),
      ),
      GoRoute(
        path: '/recap',
        builder: (context, state) => const RecapScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/saveload',
        builder: (context, state) => const SaveLoadScreen(),
      ),
      GoRoute(
        path: '/credits',
        builder: (context, state) => const CreditsScreen(),
      ),
      GoRoute(
        path: '/legal',
        builder: (context, state) => const LegalDisclaimerScreen(),
      ),
      GoRoute(
        path: '/debug',
        builder: (context, state) => const DebugScreen(),
      ),
    ],
  );
});
