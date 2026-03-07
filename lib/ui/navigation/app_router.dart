import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dreadmoor/core/state/game_state.dart';

import 'package:dreadmoor/features/messenger/ui/screens/chat/chat_screen.dart';
import '../screens/credits/credits_screen.dart';
import '../screens/debug/debug_screen.dart';
import '../screens/episode_select/episode_select_screen.dart';
import '../screens/error/fatal_error_screen.dart';
import '../screens/legal/legal_disclaimer_screen.dart';
import 'package:dreadmoor/features/messenger/ui/screens/messenger_list/messenger_list_screen.dart';
import '../screens/player_setup/player_setup_screen.dart';
import '../screens/profiles/character_profile_screen.dart';
import '../screens/profiles/player_profile_screen.dart';
import '../screens/recap/recap_screen.dart';
import '../screens/save_load/save_load_screen.dart';
import 'package:dreadmoor/features/messenger/ui/screens/secret_chat/secret_chat_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/studio_intro/studio_intro_screen.dart';
import '../screens/update_gate/content_update_screen.dart';
import '../screens/welcome/welcome_screen.dart';

import 'routes.dart';

class DreadmoorPage<T> extends CustomTransitionPage<T> {
  DreadmoorPage({required super.child, required super.key})
    : super(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );

          final scale = Tween<double>(begin: 1.04, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );

          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
      );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.studio,

    errorPageBuilder: (context, state) =>
        DreadmoorPage(key: state.pageKey, child: const FatalErrorScreen()),

    redirect: (context, state) {
      final player = ref.read(playerStateProvider);
      final hasCompletedSetup = player != null;

      final loc = state.uri.toString();

      final onSetup = loc == Routes.setup;
      final onStudio = loc == Routes.studio;
      final onLegal = loc == Routes.legal;

      if (onStudio || onLegal) return null;

      if (!hasCompletedSetup && !onSetup) {
        return Routes.setup;
      }

      if (hasCompletedSetup && onSetup) {
        return Routes.welcome;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: Routes.studio,
        name: 'studio',
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const StudioIntroScreen()),
      ),

      GoRoute(
        path: Routes.setup,
        name: 'setup',
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const PlayerSetupScreen()),
      ),

      GoRoute(
        path: Routes.welcome,
        name: 'welcome',
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const WelcomeScreen()),
      ),

      GoRoute(
        path: Routes.messenger,
        name: 'messenger',
        pageBuilder: (context, state) => DreadmoorPage(
          key: state.pageKey,
          child: const MessengerListScreen(),
        ),
      ),

      GoRoute(
        path: '/chat/:threadId',
        name: 'chat',
        pageBuilder: (context, state) {
          final id = state.pathParameters['threadId'] ?? 'group_chat';

          return DreadmoorPage(
            key: state.pageKey,
            child: ChatScreen(threadId: id),
          );
        },
      ),

      GoRoute(
        path: '/secret/:threadId',
        name: 'secret',
        pageBuilder: (context, state) {
          final id = state.pathParameters['threadId'] ?? 'spy_amelia_michael';

          return DreadmoorPage(
            key: state.pageKey,
            child: SecretChatScreen(threadId: id),
          );
        },
      ),

      GoRoute(
        path: '/profiles/:characterId',
        name: 'profile',
        pageBuilder: (context, state) {
          final id = state.pathParameters['characterId'] ?? 'amelia';

          return DreadmoorPage(
            key: state.pageKey,
            child: CharacterProfileScreen(characterId: id),
          );
        },
      ),

      GoRoute(
        path: Routes.playerProfile,
        name: 'playerProfile',
        pageBuilder: (context, state) => DreadmoorPage(
          key: state.pageKey,
          child: const PlayerProfileScreen(),
        ),
      ),

      GoRoute(
        path: Routes.episodes,
        name: 'episodes',
        pageBuilder: (context, state) => DreadmoorPage(
          key: state.pageKey,
          child: const EpisodeSelectScreen(),
        ),
      ),

      GoRoute(
        path: '/recap/:episodeId',
        name: 'recap',
        pageBuilder: (context, state) {
          final id = state.pathParameters['episodeId'] ?? 'ep01';

          return DreadmoorPage(
            key: state.pageKey,
            child: RecapScreen(episodeId: id),
          );
        },
      ),

      GoRoute(
        path: Routes.settings,
        name: 'settings',
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const SettingsScreen()),
      ),

      GoRoute(
        path: Routes.save,
        name: 'save',
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const SaveLoadScreen()),
      ),

      GoRoute(
        path: Routes.credits,
        name: 'credits',
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const CreditsScreen()),
      ),

      GoRoute(
        path: Routes.debug,
        name: 'debug',
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const DebugScreen()),
      ),

      GoRoute(
        path: Routes.legal,
        name: 'legal',
        pageBuilder: (context, state) => DreadmoorPage(
          key: state.pageKey,
          child: const LegalDisclaimerScreen(),
        ),
      ),

      GoRoute(
        path: Routes.update,
        name: 'update',
        pageBuilder: (context, state) => DreadmoorPage(
          key: state.pageKey,
          child: const ContentUpdateScreen(),
        ),
      ),

      GoRoute(
        path: Routes.error,
        name: 'error',
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const FatalErrorScreen()),
      ),
    ],
  );

  ref.listen(playerStateProvider, (_, __) => router.refresh());

  return router;
});
