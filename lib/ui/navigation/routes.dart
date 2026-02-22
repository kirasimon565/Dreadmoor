abstract final class Routes {
  // Core flow
  static const studio = '/';
  static const setup = '/setup';
  static const welcome = '/welcome';

  // Main gameplay
  static const messenger = '/messenger';
  static const board = '/board';
  static const map = '/map';
  static const episodes = '/episodes';

  // Utility
  static const settings = '/settings';
  static const save = '/save';
  static const credits = '/credits';
  static const legal = '/legal';
  static const update = '/update';
  static const error = '/error';

  // Profiles
  static const playerProfile = '/profile/player';

  // 🔧 Debug (DEV ONLY)
  static const debug = '/debug';

  // Dynamic routes
  static String chat(String threadId) => '/chat/$threadId';
  static String secret(String threadId) => '/secret/$threadId';
  static String diary(String diaryId) => '/board/diary/$diaryId';
  static String evidence(String evidenceId) => '/board/evidence/$evidenceId';
  static String profile(String characterId) => '/profiles/$characterId';
  static String recap(String episodeId) => '/recap/$episodeId';

  // 🔐 Debug helper (optional)
  static String debugSafe() => debug;
}
