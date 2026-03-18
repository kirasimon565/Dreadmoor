import 'package:drift/drift.dart';

// --------------------------------------------------
// PLAYER: The global user state
// --------------------------------------------------
class Players extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get gender => text()();
  TextColumn get profilePath => text().nullable()();
  TextColumn get phoneNumber => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// --------------------------------------------------
// CHARACTERS: NPC Registry + Player Profile
// --------------------------------------------------
class Characters extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phoneNumber => text()();
  TextColumn get avatarPath => text().nullable()(); // Main profile pic
  TextColumn get bio => text().nullable()();
  TextColumn get knownInfo => text().nullable()();
  TextColumn get investigationNotes => text().nullable()();
  TextColumn get colorHex => text().withDefault(const Constant('#746fbc'))();

  @override
  Set<Column> get primaryKey => {id};
}

// --------------------------------------------------
// CHARACTER_NOTES: Player's personal notes about characters / case
// --------------------------------------------------
class CharacterNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get characterId =>
      text().references(Characters, #id, onDelete: KeyAction.cascade)();
  TextColumn get noteText => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE',
      ];
}

// --------------------------------------------------
// CHARACTER_PHOTOS: The Gallery System
// --------------------------------------------------
class CharacterPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Link to the character who owns this photo
  TextColumn get characterId =>
      text().references(Characters, #id, onDelete: KeyAction.cascade)();

  /// The path to the image in assets or local storage
  TextColumn get photoPath => text()();

  /// Optional caption for the photo
  TextColumn get caption => text().nullable()();

  /// Date added/found
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// --------------------------------------------------
// MEDIA_ITEMS: The investigation gallery
// --------------------------------------------------
class MediaItems extends Table {
  TextColumn get id => text()();
  TextColumn get threadId => text()();
  TextColumn get senderId => text()();
  TextColumn get mediaType => text()(); // 'image' | 'video' | 'audio'
  TextColumn get filePath => text()();
  TextColumn get thumbnailPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// --------------------------------------------------
// MINIGAME_RESULTS: The Hacker Tracing system
// --------------------------------------------------
class MinigameResults extends Table {
  TextColumn get id => text()();

  TextColumn get minigameId => text()();

  BoolColumn get completed =>
      boolean().withDefault(const Constant(false))();

  IntColumn get attemptsCount =>
      integer().withDefault(const Constant(0))();

  IntColumn get heartsRemaining =>
      integer().withDefault(const Constant(5))();

  DateTimeColumn get cooldownUntil =>
      dateTime().nullable()();

  DateTimeColumn get completedAt =>
      dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --------------------------------------------------
// STORY_NODES: The "Brain" (Imported from Obsidian)
// --------------------------------------------------
class StoryNodes extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get senderId => text().nullable().references(Characters, #id)();
  TextColumn get content => text().nullable()();
  TextColumn get nextNodeId => text().nullable()();
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --------------------------------------------------
// THREAD_MEMBERS: Group chat / Thread participants
// --------------------------------------------------
class ThreadMembers extends Table {
  TextColumn get threadId => text().references(Threads, #id)();
  TextColumn get characterId => text().references(Characters, #id)();

  @override
  Set<Column> get primaryKey => {threadId, characterId};
}

// --------------------------------------------------
// THREADS: Active conversations
// --------------------------------------------------
class Threads extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get lastMessageId => integer().nullable()();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  BoolColumn get isTyping => boolean().withDefault(const Constant(false))();
  BoolColumn get isSecret => boolean().withDefault(const Constant(false))();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  TextColumn get participants => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// --------------------------------------------------
// MESSAGES: The history
// --------------------------------------------------
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nodeId => text().references(StoryNodes, #id).nullable()();
  TextColumn get threadId =>
      text().references(Threads, #id, onDelete: KeyAction.cascade)();
  TextColumn get senderId => text()();
  TextColumn get content => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('text'))();
  TextColumn get mediaPath => text().nullable()();
  IntColumn get sequence => integer()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isPlayerMessage => boolean().withDefault(const Constant(false))();
  BoolColumn get isSecret => boolean().withDefault(const Constant(false))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  TextColumn get meta => text().nullable()();

  @override
  List<Index> get indexes => [
        Index('messages_thread_idx',
            'CREATE INDEX messages_thread_idx ON messages (thread_id)'),
        Index('messages_sequence_idx',
            'CREATE INDEX messages_sequence_idx ON messages (sequence)'),
      ];
}

// --------------------------------------------------
// NOTIFICATIONS: Alerts
// --------------------------------------------------
class Notifications extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get message => text()();
  IntColumn get createdAtMinutes => integer()();
  TextColumn get payload => text().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// --------------------------------------------------
// STORY_STATE: Flags
// --------------------------------------------------
class StoryState extends Table {
  TextColumn get key => text()();
  BoolColumn get value => boolean().withDefault(const Constant(false))();
  IntColumn get intValue => integer().withDefault(const Constant(0))();
  TextColumn get stringValue => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

// --------------------------------------------------
// EPISODES: Progress
// --------------------------------------------------
class Episodes extends Table {
  TextColumn get id => text()();
  BoolColumn get isUnlocked => boolean().withDefault(const Constant(false))();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
