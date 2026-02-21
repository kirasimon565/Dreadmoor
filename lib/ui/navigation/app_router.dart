import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/chat/chat_screen.dart';
import '../screens/credits/credits_screen.dart';
import '../screens/debug/debug_screen.dart';
import '../screens/detective_board/detective_board_screen.dart';
import '../screens/detective_board/diary_viewer_screen.dart';
import '../screens/detective_board/evidence_detail_screen.dart';
import '../screens/episode_select/episode_select_screen.dart';
import '../screens/error/fatal_error_screen.dart';
import '../screens/legal/legal_disclaimer_screen.dart';
import '../screens/map/dreadmoor_map_screen.dart';
import '../screens/messenger_list/messenger_list_screen.dart';
import '../screens/player_setup/player_setup_screen.dart';
import '../screens/profiles/character_profile_screen.dart';
import '../screens/profiles/player_profile_screen.dart';
import '../screens/recap/recap_screen.dart';
import '../screens/save_load/save_load_screen.dart';
import '../screens/secret_chat/secret_chat_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/studio_intro/studio_intro_screen.dart';
import '../screens/update_gate/content_update_screen.dart';
import '../screens/welcome/welcome_screen.dart';
import 'routes.dart';

class DreadmoorPage<T> extends CustomTransitionPage<T> {
  DreadmoorPage({required super.child, required super.key})
      : super(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );
            final scale = Tween<double>(begin: 1.05, end: 1.0).animate(
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
  return GoRouter(
    initialLocation: Routes.studio,
    routes: [
      GoRoute(path: Routes.studio, pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const StudioIntroScreen())),
      GoRoute(path: Routes.setup, pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const PlayerSetupScreen())),
      GoRoute(path: Routes.welcome, pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const WelcomeScreen())),
      GoRoute(path: Routes.messenger, pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const MessengerListScreen())),
      GoRoute(path: '/chat/:threadId', pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: ChatScreen(threadId: state.pathParameters['threadId'] ?? 'group_chat'))),
      GoRoute(path: '/secret/:threadId', pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: SecretChatScreen(threadId: state.pathParameters['threadId'] ?? 'spy_amelia_michael'))),
      GoRoute(path: Routes.board, pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const DetectiveBoardScreen())),
      GoRoute(path: '/board/diary/:diaryId', pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: DiaryViewerScreen(diaryId: state.pathParameters['diaryId'] ?? 'unknown'))),
      GoRoute(path: '/board/evidence/:evidenceId', pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: EvidenceDetailScreen(evidenceId: state.pathParameters['evidenceId'] ?? 'evidence'))),
      GoRoute(path: '/profiles/:characterId', pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: CharacterProfileScreen(characterId: state.pathParameters['characterId'] ?? 'amelia'))),
      GoRoute(path: Routes.playerProfile, pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const PlayerProfileScreen())),
      GoRoute(path: Routes.map, pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const DreadmoorMapScreen())),
      GoRoute(path: Routes.episodes, pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const EpisodeSelectScreen())),
      GoRoute(path: '/recap/:episodeId', pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const RecapScreen())),
      GoRoute(path: Routes.settings, pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const SettingsScreen())),
      GoRoute(path: Routes.save, pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const SaveLoadScreen())),
      GoRoute(path: Routes.credits, pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const CreditsScreen())),
      GoRoute(path: Routes.debug, pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const DebugScreen())),
      GoRoute(path: Routes.legal, pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const LegalDisclaimerScreen())),
      GoRoute(path: Routes.update, pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const ContentUpdateScreen())),
      GoRoute(path: Routes.error, pageBuilder: (context, state) => DreadmoorPage(key: state.pageKey, child: const FatalErrorScreen())),
    ],
  );
});
