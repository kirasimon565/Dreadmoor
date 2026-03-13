import 'package:drift/drift.dart';

// --------------------------------------------------
// PLAYERS
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
// CHARACTERS
// --------------------------------------------------
class Characters extends Table {
  TextColumn get id => text()(); 
  TextColumn get name => text()();
  TextColumn get phoneNumber => text()();
  TextColumn get avatarPath => text().nullable()(); // Main Profile Picture
  TextColumn get bio => text().nullable()();
  TextColumn get knownInfo => text().nullable()();
  TextColumn get investigationNotes => text().nullable()();
  TextColumn get colorHex => text().withDefault(const Constant('#746fbc'))();

  @override
  Set<Column> get primaryKey => {id};
}

// --------------------------------------------------
// CHARACTER_GALLERY (New: Photo Gallery Support)
// --------------------------------------------------
class CharacterGallery extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  /// Links this photo to a specific character
  TextColumn get characterId => text().references(Characters, #id, onDelete: KeyAction.cascade)();
  
  /// Path to the image asset
  TextColumn get imagePath => text()();
  
  /// Optional caption for the specific photo
  TextColumn get caption => text().nullable()();

  /// Order in which the photo appears in the gallery
  IntColumn get priority => integer().withDefault(const Constant(0))();
}

// --------------------------------------------------
// STORY_NODES
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
// THREADS
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
// MESSAGES
// --------------------------------------------------
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nodeId => text().references(StoryNodes, #id).nullable()();
  TextColumn get threadId => text().references(Threads, #id, onDelete: KeyAction.cascade)();
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
}

// --------------------------------------------------
// STORY_STATE
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
// NOTIFICATIONS & EPISODES
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

class Episodes extends Table {
  TextColumn get id => text()();
  BoolColumn get isUnlocked => boolean().withDefault(const Constant(false))();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  @override
  Set<Column> get primaryKey => {id};
}
