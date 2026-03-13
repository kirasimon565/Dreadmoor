import 'package:drift/drift.dart';

// --------------------------------------------------
// PLAYER: The global user state
// --------------------------------------------------
class Players extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get gender => text()();
  TextColumn get profilePath => text().nullable()();
  TextColumn get phoneNumber => text().withDefault(const Constant('+1 (555) 000-0000'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// --------------------------------------------------
// CHARACTERS: NPC Registry
// --------------------------------------------------
class Characters extends Table {
  TextColumn get id => text()(); // e.g., 'unknown', 'amelia'
  TextColumn get name => text()();
  TextColumn get phoneNumber => text()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get knownInfo => text().nullable()();
  TextColumn get investigationNotes => text().nullable()();
  TextColumn get colorHex => text().withDefault(const Constant('#746fbc'))();

  @override
  Set<Column> get primaryKey => {id};
}

// --------------------------------------------------
// STORY_NODES: The "Brain" (Imported from Obsidian)
// --------------------------------------------------
class StoryNodes extends Table {
  TextColumn get id => text()(); // The [[ID]]
  TextColumn get type => text()(); // Chat_Event, Player_Choice, Video_Message, News_Module, Phone_Call
  TextColumn get senderId => text().nullable().references(Characters, #id)();
  TextColumn get content => text().nullable()();
  TextColumn get nextNodeId => text().nullable()();
  
  /// Stores JSON metadata: { "action": "Typing", "duration": 2000, "asset": "path/to/video.mp4" }
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --------------------------------------------------
// THREADS: Active conversations in Messenger
// --------------------------------------------------
class Threads extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get lastMessageId => integer().nullable()();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  BoolColumn get isTyping => boolean().withDefault(const Constant(false))();
  BoolColumn get isSecret => boolean().withDefault(const Constant(false))();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  TextColumn get participants => text()(); // JSON List of character IDs

  @override
  Set<Column> get primaryKey => {id};
}

// --------------------------------------------------
// MESSAGES: The immutable history
// --------------------------------------------------
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nodeId => text().references(StoryNodes, #id).nullable()();
  TextColumn get threadId => text().references(Threads, #id, onDelete: KeyAction.cascade)();
  TextColumn get senderId => text()();
  TextColumn get content => text().nullable()();
  
  /// text, video, image, call_log, system_label
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
    Index('messages_thread_idx', 'CREATE INDEX messages_thread_idx ON messages (thread_id)'),
    Index('messages_sequence_idx', 'CREATE INDEX messages_sequence_idx ON messages (sequence)'),
  ];
}

// --------------------------------------------------
// NOTIFICATIONS: OS-level alerts
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
// STORY_STATE: Global Flags and Call Counters
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
// EPISODES: Unlock progress
// --------------------------------------------------
class Episodes extends Table {
  TextColumn get id => text()();
  BoolColumn get isUnlocked => boolean().withDefault(const Constant(false))();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
