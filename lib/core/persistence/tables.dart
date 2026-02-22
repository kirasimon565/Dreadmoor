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
  IntColumn get lastMessageId => integer().nullable()();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  BoolColumn get isTyping => boolean().withDefault(const Constant(false))();
  BoolColumn get isSecret => boolean().withDefault(const Constant(false))();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  TextColumn get participants => text()(); // JSON list

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Index> get indexes => [
        Index('threads_last_message_idx', [lastMessageId]),
        Index('threads_locked_idx', [isLocked]),
      ];
}

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get threadId =>
      text().references(Threads, #id, onDelete: KeyAction.cascade)();
  TextColumn get senderId => text()();
  TextColumn get content => text()();
  TextColumn get type =>
      text().withDefault(const Constant('text'))(); // text, image, system
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isPlayerMessage => boolean().withDefault(const Constant(false))();
  BoolColumn get isSecret => boolean().withDefault(const Constant(false))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  @override
  List<Index> get indexes => [
        Index('messages_thread_idx', [threadId]),
        Index('messages_time_idx', [timestamp]),
      ];
}

class StoryState extends Table {
  TextColumn get key => text()();
  BoolColumn get value => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

class Episodes extends Table {
  TextColumn get id => text()();
  BoolColumn get isUnlocked => boolean().withDefault(const Constant(false))();
  IntColumn get progress => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
