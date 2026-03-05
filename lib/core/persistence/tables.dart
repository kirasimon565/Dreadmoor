import 'package:drift/drift.dart';

class Players extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get gender => text()();
  TextColumn get profilePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Threads extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();

  /// id of last visible message
  IntColumn get lastMessageId => integer().nullable()();

  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  BoolColumn get isTyping => boolean().withDefault(const Constant(false))();

  /// for secret chats / intercepts
  BoolColumn get isSecret => boolean().withDefault(const Constant(false))();

  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  /// JSON list of participant ids
  TextColumn get participants => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Index> get indexes => [
        Index(
          'threads_last_message_idx',
          'CREATE INDEX threads_last_message_idx ON threads (last_message_id)',
        ),
        Index(
          'threads_locked_idx',
          'CREATE INDEX threads_locked_idx ON threads (is_locked)',
        ),
      ];
}

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// chat thread
  TextColumn get threadId =>
      text().references(Threads, #id, onDelete: KeyAction.cascade)();

  /// sender character id
  TextColumn get senderId => text()();

  /// visible message text
  TextColumn get content => text().nullable()();

  /// text / image / video / audio / system / typing / choice
  TextColumn get type =>
      text().withDefault(const Constant('text'))();

  /// attachment path (video, image, audio)
  TextColumn get mediaPath => text().nullable()();

  /// ordering control (important for scripted playback)
  IntColumn get sequence => integer()();

  DateTimeColumn get timestamp =>
      dateTime().withDefault(currentDateAndTime)();

  BoolColumn get isPlayerMessage =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isSecret =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isRead =>
      boolean().withDefault(const Constant(false))();

  /// JSON metadata (choices, pauses, typing indicators)
  TextColumn get meta => text().nullable()();

  @override
  List<Index> get indexes => [
        Index(
          'messages_thread_idx',
          'CREATE INDEX messages_thread_idx ON messages (thread_id)',
        ),
        Index(
          'messages_sequence_idx',
          'CREATE INDEX messages_sequence_idx ON messages (sequence)',
        ),
      ];
}

class StoryState extends Table {
  TextColumn get key => text()();

  /// story flags
  BoolColumn get value =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

class Episodes extends Table {
  TextColumn get id => text()();

  BoolColumn get isUnlocked =>
      boolean().withDefault(const Constant(false))();

  IntColumn get progress =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
