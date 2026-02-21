abstract final class Routes {
  static const studio = '/';
  static const setup = '/setup';
  static const welcome = '/welcome';
  static const messenger = '/messenger';
  static const board = '/board';
  static const map = '/map';
  static const episodes = '/episodes';
  static const settings = '/settings';
  static const save = '/save';
  static const credits = '/credits';
  static const legal = '/legal';
  static const update = '/update';
  static const error = '/error';
  static const debug = '/debug';

  static String chat(String threadId) => '/chat/$threadId';
  static String secret(String threadId) => '/secret/$threadId';
  static String diary(String diaryId) => '/board/diary/$diaryId';
  static String evidence(String evidenceId) => '/board/evidence/$evidenceId';
  static String profile(String characterId) => '/profiles/$characterId';
  static const playerProfile = '/profile/player';
  static String recap(String episodeId) => '/recap/$episodeId';
}
