import 'package:drift/drift.dart';

// --------------------------------------------------
// PLAYER
// --------------------------------------------------

class Players extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get gender => text()();

  TextColumn get profilePath => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// --------------------------------------------------
// THREADS (CHAT LIST)
// --------------------------------------------------

class Threads extends Table {
  TextColumn get id => text()();

  TextColumn get title => text()();

  /// last visible message
  IntColumn get lastMessageId => integer().nullable()();

  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();

  BoolColumn get isTyping => boolean().withDefault(const Constant(false))();

  /// secret chat / intercept
  BoolColumn get isSecret => boolean().withDefault(const Constant(false))();

  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  /// JSON participant list
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

// --------------------------------------------------
// MESSAGES
// --------------------------------------------------

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// eventId from episode JSON (e001, e002, etc.)
  TextColumn get eventId => text().nullable()();

  /// chat thread
  TextColumn get threadId =>
      text().references(Threads, #id, onDelete: KeyAction.cascade)();

  /// sender character id
  TextColumn get senderId => text()();

  /// message text
  TextColumn get content => text().nullable()();

  /// message type
  /// text / image / video / audio / system / typing / choice
  TextColumn get type => text().withDefault(const Constant('text'))();

  /// attachment
  TextColumn get mediaPath => text().nullable()();

  /// ordering for playback
  IntColumn get sequence => integer()();

  /// event timestamp
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();

  BoolColumn get isPlayerMessage =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isSecret => boolean().withDefault(const Constant(false))();

  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  /// JSON metadata
  /// contains:
  /// choiceId
  /// delayAfter
  /// typing.duration
  /// etc
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
    Index(
      'messages_event_idx',
      'CREATE INDEX messages_event_idx ON messages (event_id)',
    ),
  ];
}

// --------------------------------------------------
// STORY FLAGS
// --------------------------------------------------

class StoryState extends Table {
  TextColumn get key => text()();

  BoolColumn get value => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

// --------------------------------------------------
// EPISODES
// --------------------------------------------------

class Episodes extends Table {
  TextColumn get id => text()();

  BoolColumn get isUnlocked => boolean().withDefault(const Constant(false))();

  /// playback progress (event index)
  IntColumn get progress => integer().withDefault(const Constant(0))();

  /// episode version (for future updates)
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
