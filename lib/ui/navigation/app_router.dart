import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dreadmoor/core/state/game_state.dart';

import 'package:dreadmoor/features/messenger/ui/screens/chat/chat_screen.dart';
import 'package:dreadmoor/features/messenger/ui/screens/messenger_list/messenger_list_screen.dart';
import 'package:dreadmoor/features/messenger/ui/screens/secret_chat/secret_chat_screen.dart';

import 'package:dreadmoor/features/apps/ui/screens/apps/apps_screen.dart';
import 'package:dreadmoor/features/puzzle/ui/screens/puzzle/puzzle_screen.dart';
import 'package:dreadmoor/features/store/ui/screens/store/store_screen.dart';

import 'package:dreadmoor/features/browser/ui/screens/browser/dreadmoor_browser_screen.dart';
import 'package:dreadmoor/features/browser/ui/screens/browser/article_viewer_screen.dart';

import 'package:dreadmoor/features/phone/ui/screens/phone/phone_app_screen.dart';

import '../screens/player_setup/player_setup_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/studio_intro/studio_intro_screen.dart';
import '../screens/error/fatal_error_screen.dart';
import '../screens/legal/legal_disclaimer_screen.dart';
import '../screens/profiles/player_profile_screen.dart';
import '../screens/profiles/character_profile_screen.dart';
import '../screens/save_load/save_load_screen.dart';
import '../screens/update_gate/content_update_screen.dart';
import '../screens/episode_select/episode_select_screen.dart';
import '../screens/credits/credits_screen.dart';
import '../screens/debug/debug_screen.dart';
import '../screens/recap/recap_screen.dart';

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

      /// Studio intro
      GoRoute(
        path: Routes.studio,
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const StudioIntroScreen()),
      ),

      /// Setup
      GoRoute(
        path: Routes.setup,
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const PlayerSetupScreen()),
      ),

      /// Welcome
      GoRoute(
        path: Routes.welcome,
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const WelcomeScreen()),
      ),

      /// MAIN APP SHELL
      ShellRoute(
        builder: (context, state, child) {
          return child;
        },

        routes: [

          /// Messenger
          GoRoute(
            path: Routes.messenger,
            pageBuilder: (context, state) =>
                DreadmoorPage(key: state.pageKey, child: const MessengerListScreen()),
          ),

          /// Puzzle
          GoRoute(
            path: '/puzzle',
            pageBuilder: (context, state) =>
                DreadmoorPage(key: state.pageKey, child: const PuzzleScreen()),
          ),

          /// Apps
          GoRoute(
            path: '/apps',
            pageBuilder: (context, state) =>
                DreadmoorPage(key: state.pageKey, child: const AppsScreen()),
          ),

          /// Store
          GoRoute(
            path: '/store',
            pageBuilder: (context, state) =>
                DreadmoorPage(key: state.pageKey, child: const StoreScreen()),
          ),

          /// Browser
          GoRoute(
  path: '/browser',
  pageBuilder: (context, state) {

    final article = state.extra as Article;

    return DreadmoorPage(
      key: state.pageKey,
      child: DreadmoorBrowserScreen(article: article),
    );
  },
),

          /// Article viewer
          GoRoute(
  path: '/article',
  pageBuilder: (context, state) {

    final article = state.extra as Article;

    return DreadmoorPage(
      key: state.pageKey,
      child: ArticleViewerScreen(article: article),
    );
  },
),

          /// Phone
          GoRoute(
            path: '/phone',
            pageBuilder: (context, state) =>
                DreadmoorPage(key: state.pageKey, child: const PhoneAppScreen()),
          ),

          /// Player profile
          GoRoute(
            path: Routes.playerProfile,
            pageBuilder: (context, state) =>
                DreadmoorPage(key: state.pageKey, child: const PlayerProfileScreen()),
          ),
        ],
      ),

      /// Chat
      GoRoute(
        path: '/chat/:threadId',
        pageBuilder: (context, state) {

          final id = state.pathParameters['threadId'] ?? 'group_chat';

          return DreadmoorPage(
            key: state.pageKey,
            child: ChatScreen(threadId: id),
          );
        },
      ),

      /// Secret chat
      GoRoute(
        path: '/secret/:threadId',
        pageBuilder: (context, state) {

          final id = state.pathParameters['threadId'] ?? 'spy';

          return DreadmoorPage(
            key: state.pageKey,
            child: SecretChatScreen(threadId: id),
          );
        },
      ),

      /// Character profile
      GoRoute(
        path: '/profiles/:characterId',
        pageBuilder: (context, state) {

          final id = state.pathParameters['characterId'] ?? 'unknown';

          return DreadmoorPage(
            key: state.pageKey,
            child: CharacterProfileScreen(characterId: id),
          );
        },
      ),

      /// Episodes
      GoRoute(
        path: Routes.episodes,
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const EpisodeSelectScreen()),
      ),

      /// Recap
      GoRoute(
        path: '/recap/:episodeId',
        pageBuilder: (context, state) {

          final id = state.pathParameters['episodeId'] ?? 'ep01';

          return DreadmoorPage(
            key: state.pageKey,
            child: RecapScreen(episodeId: id),
          );
        },
      ),

      /// Settings
      GoRoute(
        path: Routes.settings,
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const SettingsScreen()),
      ),

      /// Save
      GoRoute(
        path: Routes.save,
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const SaveLoadScreen()),
      ),

      /// Credits
      GoRoute(
        path: Routes.credits,
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const CreditsScreen()),
      ),

      /// Debug
      GoRoute(
        path: Routes.debug,
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const DebugScreen()),
      ),

      /// Legal
      GoRoute(
        path: Routes.legal,
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const LegalDisclaimerScreen()),
      ),

      /// Update
      GoRoute(
        path: Routes.update,
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const ContentUpdateScreen()),
      ),

      /// Error
      GoRoute(
        path: Routes.error,
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const FatalErrorScreen()),
      ),
    ],
  );

  ref.listen(playerStateProvider, (_, __) => router.refresh());

  return router;
});
