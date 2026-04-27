import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/os/dreadmoor_os.dart';

import '../screens/player_setup/player_setup_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/studio_intro/studio_intro_screen.dart';
import '../screens/error/fatal_error_screen.dart';
import '../screens/legal/legal_disclaimer_screen.dart';
import '../screens/save_load/save_load_screen.dart';
import '../screens/update_gate/content_update_screen.dart';
import '../screens/episode_select/episode_select_screen.dart';
import '../screens/credits/credits_screen.dart';
import '../screens/debug/debug_screen.dart';
import '../screens/recap/recap_screen.dart';
import '../screens/intro/intro_trailer_screen.dart';
import '../screens/intro/title_cinematic_screen.dart';

import 'package:dreadmoor/features/messenger/ui/screens/chat/chat_screen.dart';

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

      final onStudio = loc == Routes.studio;
      final onSetup = loc == Routes.setup;
      final onWelcome = loc == Routes.welcome;
      final onLegal = loc == Routes.legal;
      final onIntroTrailer = loc == Routes.introTrailer;
      final onTitleCinematic = loc == Routes.titleCinematic;
      final onOS = loc == Routes.os;

      /// Allow these routes freely
      if (onStudio || onLegal) return null;

      /// Player must complete setup first
      if (!hasCompletedSetup && !onSetup) {
        return Routes.setup;
      }

      /// After setup, go to welcome screen
      if (hasCompletedSetup && onSetup) {
        return Routes.welcome;
      }

      /// From welcome → OS (allow intro/title sequence as part of transition)
      if (hasCompletedSetup && (onWelcome || onIntroTrailer || onTitleCinematic)) {
        return null;
      }

      /// If player already setup but tries to access other early routes
      if (hasCompletedSetup && !onOS && !onWelcome && !onIntroTrailer && !onTitleCinematic) {
        // Exception: Let utility routes pass through (like settings or debug)
        final allowedUtilities = [
          Routes.settings,
          Routes.debug,
          Routes.legal,
          Routes.credits,
          Routes.episodes,
          Routes.save,
        ];
        if (allowedUtilities.contains(loc) || loc.startsWith('/recap') || loc.startsWith('/chat') || loc.startsWith('/secret') || loc.startsWith('/profile')) {
          return null;
        }

        // Otherwise enforce OS routing
        return Routes.os;
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

      /// Intro Trailer
      GoRoute(
        path: Routes.introTrailer,
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const IntroTrailerScreen()),
      ),

      /// Title Cinematic
      GoRoute(
        path: Routes.titleCinematic,
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const TitleCinematicScreen()),
      ),

      /// MAIN PHONE OS
      GoRoute(
        path: Routes.os,
        pageBuilder: (context, state) =>
            DreadmoorPage(key: state.pageKey, child: const DreadmoorOS()),
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

      /// Chat
      GoRoute(
        path: '/chat/:threadId',
        pageBuilder: (context, state) {
          final threadId = state.pathParameters['threadId']!;

          return DreadmoorPage(
            key: state.pageKey,
            child: ChatScreen(threadId: threadId),
          );
        },
      ),
    ],
  );

  ref.listen(playerStateProvider, (_, __) => router.refresh());

  return router;
});
