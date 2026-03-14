// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// ignore_for_file: type=lint
class $PlayersTable extends Players with TableInfo<$PlayersTable, Player> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profilePathMeta =
      const VerificationMeta('profilePath');
  @override
  late final GeneratedColumn<String> profilePath = GeneratedColumn<String>(
      'profile_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneNumberMeta =
      const VerificationMeta('phoneNumber');
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
      'phone_number', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('+1 (555) 000-0000'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, gender, profilePath, phoneNumber, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(Insertable<Player> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('profile_path')) {
      context.handle(
          _profilePathMeta,
          profilePath.isAcceptableOrUnknown(
              data['profile_path']!, _profilePathMeta));
    }
    if (data.containsKey('phone_number')) {
      context.handle(
          _phoneNumberMeta,
          phoneNumber.isAcceptableOrUnknown(
              data['phone_number']!, _phoneNumberMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Player map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Player(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender'])!,
      profilePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_path']),
      phoneNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone_number'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PlayersTable createAlias(String alias) {
    return $PlayersTable(attachedDatabase, alias);
  }
}

class Player extends DataClass implements Insertable<Player> {
  final int id;
  final String name;
  final String gender;
  final String? profilePath;
  final String phoneNumber;
  final DateTime createdAt;
  const Player(
      {required this.id,
      required this.name,
      required this.gender,
      this.profilePath,
      required this.phoneNumber,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['gender'] = Variable<String>(gender);
    if (!nullToAbsent || profilePath != null) {
      map['profile_path'] = Variable<String>(profilePath);
    }
    map['phone_number'] = Variable<String>(phoneNumber);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlayersCompanion toCompanion(bool nullToAbsent) {
    return PlayersCompanion(
      id: Value(id),
      name: Value(name),
      gender: Value(gender),
      profilePath: profilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePath),
      phoneNumber: Value(phoneNumber),
      createdAt: Value(createdAt),
    );
  }

  factory Player.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Player(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      gender: serializer.fromJson<String>(json['gender']),
      profilePath: serializer.fromJson<String?>(json['profilePath']),
      phoneNumber: serializer.fromJson<String>(json['phoneNumber']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'gender': serializer.toJson<String>(gender),
      'profilePath': serializer.toJson<String?>(profilePath),
      'phoneNumber': serializer.toJson<String>(phoneNumber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Player copyWith(
          {int? id,
          String? name,
          String? gender,
          Value<String?> profilePath = const Value.absent(),
          String? phoneNumber,
          DateTime? createdAt}) =>
      Player(
        id: id ?? this.id,
        name: name ?? this.name,
        gender: gender ?? this.gender,
        profilePath: profilePath.present ? profilePath.value : this.profilePath,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        createdAt: createdAt ?? this.createdAt,
      );
  Player copyWithCompanion(PlayersCompanion data) {
    return Player(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      gender: data.gender.present ? data.gender.value : this.gender,
      profilePath:
          data.profilePath.present ? data.profilePath.value : this.profilePath,
      phoneNumber:
          data.phoneNumber.present ? data.phoneNumber.value : this.phoneNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Player(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gender: $gender, ')
          ..write('profilePath: $profilePath, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, gender, profilePath, phoneNumber, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Player &&
          other.id == this.id &&
          other.name == this.name &&
          other.gender == this.gender &&
          other.profilePath == this.profilePath &&
          other.phoneNumber == this.phoneNumber &&
          other.createdAt == this.createdAt);
}

class PlayersCompanion extends UpdateCompanion<Player> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> gender;
  final Value<String?> profilePath;
  final Value<String> phoneNumber;
  final Value<DateTime> createdAt;
  const PlayersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.gender = const Value.absent(),
    this.profilePath = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PlayersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String gender,
    this.profilePath = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        gender = Value(gender);
  static Insertable<Player> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? gender,
    Expression<String>? profilePath,
    Expression<String>? phoneNumber,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (gender != null) 'gender': gender,
      if (profilePath != null) 'profile_path': profilePath,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PlayersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? gender,
      Value<String?>? profilePath,
      Value<String>? phoneNumber,
      Value<DateTime>? createdAt}) {
    return PlayersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      profilePath: profilePath ?? this.profilePath,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (profilePath.present) {
      map['profile_path'] = Variable<String>(profilePath.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gender: $gender, ')
          ..write('profilePath: $profilePath, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CharactersTable extends Characters
    with TableInfo<$CharactersTable, Character> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharactersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneNumberMeta =
      const VerificationMeta('phoneNumber');
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
      'phone_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _avatarPathMeta =
      const VerificationMeta('avatarPath');
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
      'avatar_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
      'bio', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _knownInfoMeta =
      const VerificationMeta('knownInfo');
  @override
  late final GeneratedColumn<String> knownInfo = GeneratedColumn<String>(
      'known_info', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _investigationNotesMeta =
      const VerificationMeta('investigationNotes');
  @override
  late final GeneratedColumn<String> investigationNotes =
      GeneratedColumn<String>('investigation_notes', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#746fbc'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        phoneNumber,
        avatarPath,
        bio,
        knownInfo,
        investigationNotes,
        colorHex
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'characters';
  @override
  VerificationContext validateIntegrity(Insertable<Character> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone_number')) {
      context.handle(
          _phoneNumberMeta,
          phoneNumber.isAcceptableOrUnknown(
              data['phone_number']!, _phoneNumberMeta));
    } else if (isInserting) {
      context.missing(_phoneNumberMeta);
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
          _avatarPathMeta,
          avatarPath.isAcceptableOrUnknown(
              data['avatar_path']!, _avatarPathMeta));
    }
    if (data.containsKey('bio')) {
      context.handle(
          _bioMeta, bio.isAcceptableOrUnknown(data['bio']!, _bioMeta));
    }
    if (data.containsKey('known_info')) {
      context.handle(_knownInfoMeta,
          knownInfo.isAcceptableOrUnknown(data['known_info']!, _knownInfoMeta));
    }
    if (data.containsKey('investigation_notes')) {
      context.handle(
          _investigationNotesMeta,
          investigationNotes.isAcceptableOrUnknown(
              data['investigation_notes']!, _investigationNotesMeta));
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Character map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Character(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phoneNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone_number'])!,
      avatarPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_path']),
      bio: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bio']),
      knownInfo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}known_info']),
      investigationNotes: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}investigation_notes']),
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
    );
  }

  @override
  $CharactersTable createAlias(String alias) {
    return $CharactersTable(attachedDatabase, alias);
  }
}

class Character extends DataClass implements Insertable<Character> {
  final String id;
  final String name;
  final String phoneNumber;
  final String? avatarPath;
  final String? bio;
  final String? knownInfo;
  final String? investigationNotes;
  final String colorHex;
  const Character(
      {required this.id,
      required this.name,
      required this.phoneNumber,
      this.avatarPath,
      this.bio,
      this.knownInfo,
      this.investigationNotes,
      required this.colorHex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['phone_number'] = Variable<String>(phoneNumber);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    if (!nullToAbsent || knownInfo != null) {
      map['known_info'] = Variable<String>(knownInfo);
    }
    if (!nullToAbsent || investigationNotes != null) {
      map['investigation_notes'] = Variable<String>(investigationNotes);
    }
    map['color_hex'] = Variable<String>(colorHex);
    return map;
  }

  CharactersCompanion toCompanion(bool nullToAbsent) {
    return CharactersCompanion(
      id: Value(id),
      name: Value(name),
      phoneNumber: Value(phoneNumber),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      knownInfo: knownInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(knownInfo),
      investigationNotes: investigationNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(investigationNotes),
      colorHex: Value(colorHex),
    );
  }

  factory Character.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Character(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phoneNumber: serializer.fromJson<String>(json['phoneNumber']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      bio: serializer.fromJson<String?>(json['bio']),
      knownInfo: serializer.fromJson<String?>(json['knownInfo']),
      investigationNotes:
          serializer.fromJson<String?>(json['investigationNotes']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phoneNumber': serializer.toJson<String>(phoneNumber),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'bio': serializer.toJson<String?>(bio),
      'knownInfo': serializer.toJson<String?>(knownInfo),
      'investigationNotes': serializer.toJson<String?>(investigationNotes),
      'colorHex': serializer.toJson<String>(colorHex),
    };
  }

  Character copyWith(
          {String? id,
          String? name,
          String? phoneNumber,
          Value<String?> avatarPath = const Value.absent(),
          Value<String?> bio = const Value.absent(),
          Value<String?> knownInfo = const Value.absent(),
          Value<String?> investigationNotes = const Value.absent(),
          String? colorHex}) =>
      Character(
        id: id ?? this.id,
        name: name ?? this.name,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
        bio: bio.present ? bio.value : this.bio,
        knownInfo: knownInfo.present ? knownInfo.value : this.knownInfo,
        investigationNotes: investigationNotes.present
            ? investigationNotes.value
            : this.investigationNotes,
        colorHex: colorHex ?? this.colorHex,
      );
  Character copyWithCompanion(CharactersCompanion data) {
    return Character(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phoneNumber:
          data.phoneNumber.present ? data.phoneNumber.value : this.phoneNumber,
      avatarPath:
          data.avatarPath.present ? data.avatarPath.value : this.avatarPath,
      bio: data.bio.present ? data.bio.value : this.bio,
      knownInfo: data.knownInfo.present ? data.knownInfo.value : this.knownInfo,
      investigationNotes: data.investigationNotes.present
          ? data.investigationNotes.value
          : this.investigationNotes,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Character(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('bio: $bio, ')
          ..write('knownInfo: $knownInfo, ')
          ..write('investigationNotes: $investigationNotes, ')
          ..write('colorHex: $colorHex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phoneNumber, avatarPath, bio,
      knownInfo, investigationNotes, colorHex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Character &&
          other.id == this.id &&
          other.name == this.name &&
          other.phoneNumber == this.phoneNumber &&
          other.avatarPath == this.avatarPath &&
          other.bio == this.bio &&
          other.knownInfo == this.knownInfo &&
          other.investigationNotes == this.investigationNotes &&
          other.colorHex == this.colorHex);
}

class CharactersCompanion extends UpdateCompanion<Character> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> phoneNumber;
  final Value<String?> avatarPath;
  final Value<String?> bio;
  final Value<String?> knownInfo;
  final Value<String?> investigationNotes;
  final Value<String> colorHex;
  final Value<int> rowid;
  const CharactersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.bio = const Value.absent(),
    this.knownInfo = const Value.absent(),
    this.investigationNotes = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharactersCompanion.insert({
    required String id,
    required String name,
    required String phoneNumber,
    this.avatarPath = const Value.absent(),
    this.bio = const Value.absent(),
    this.knownInfo = const Value.absent(),
    this.investigationNotes = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        phoneNumber = Value(phoneNumber);
  static Insertable<Character> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phoneNumber,
    Expression<String>? avatarPath,
    Expression<String>? bio,
    Expression<String>? knownInfo,
    Expression<String>? investigationNotes,
    Expression<String>? colorHex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (bio != null) 'bio': bio,
      if (knownInfo != null) 'known_info': knownInfo,
      if (investigationNotes != null) 'investigation_notes': investigationNotes,
      if (colorHex != null) 'color_hex': colorHex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharactersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? phoneNumber,
      Value<String?>? avatarPath,
      Value<String?>? bio,
      Value<String?>? knownInfo,
      Value<String?>? investigationNotes,
      Value<String>? colorHex,
      Value<int>? rowid}) {
    return CharactersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarPath: avatarPath ?? this.avatarPath,
      bio: bio ?? this.bio,
      knownInfo: knownInfo ?? this.knownInfo,
      investigationNotes: investigationNotes ?? this.investigationNotes,
      colorHex: colorHex ?? this.colorHex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (knownInfo.present) {
      map['known_info'] = Variable<String>(knownInfo.value);
    }
    if (investigationNotes.present) {
      map['investigation_notes'] = Variable<String>(investigationNotes.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharactersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('bio: $bio, ')
          ..write('knownInfo: $knownInfo, ')
          ..write('investigationNotes: $investigationNotes, ')
          ..write('colorHex: $colorHex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterPhotosTable extends CharacterPhotos
    with TableInfo<$CharacterPhotosTable, CharacterPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _characterIdMeta =
      const VerificationMeta('characterId');
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
      'character_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES characters (id) ON DELETE CASCADE'));
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _captionMeta =
      const VerificationMeta('caption');
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
      'caption', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, characterId, photoPath, caption, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_photos';
  @override
  VerificationContext validateIntegrity(Insertable<CharacterPhoto> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('character_id')) {
      context.handle(
          _characterIdMeta,
          characterId.isAcceptableOrUnknown(
              data['character_id']!, _characterIdMeta));
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    } else if (isInserting) {
      context.missing(_photoPathMeta);
    }
    if (data.containsKey('caption')) {
      context.handle(_captionMeta,
          caption.isAcceptableOrUnknown(data['caption']!, _captionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterPhoto(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      characterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}character_id'])!,
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path'])!,
      caption: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}caption']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CharacterPhotosTable createAlias(String alias) {
    return $CharacterPhotosTable(attachedDatabase, alias);
  }
}

class CharacterPhoto extends DataClass implements Insertable<CharacterPhoto> {
  final int id;

  /// Link to the character who owns this photo
  final String characterId;

  /// The path to the image in assets or local storage
  final String photoPath;

  /// Optional caption for the photo
  final String? caption;

  /// Date added/found
  final DateTime createdAt;
  const CharacterPhoto(
      {required this.id,
      required this.characterId,
      required this.photoPath,
      this.caption,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['character_id'] = Variable<String>(characterId);
    map['photo_path'] = Variable<String>(photoPath);
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CharacterPhotosCompanion toCompanion(bool nullToAbsent) {
    return CharacterPhotosCompanion(
      id: Value(id),
      characterId: Value(characterId),
      photoPath: Value(photoPath),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      createdAt: Value(createdAt),
    );
  }

  factory CharacterPhoto.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterPhoto(
      id: serializer.fromJson<int>(json['id']),
      characterId: serializer.fromJson<String>(json['characterId']),
      photoPath: serializer.fromJson<String>(json['photoPath']),
      caption: serializer.fromJson<String?>(json['caption']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'characterId': serializer.toJson<String>(characterId),
      'photoPath': serializer.toJson<String>(photoPath),
      'caption': serializer.toJson<String?>(caption),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CharacterPhoto copyWith(
          {int? id,
          String? characterId,
          String? photoPath,
          Value<String?> caption = const Value.absent(),
          DateTime? createdAt}) =>
      CharacterPhoto(
        id: id ?? this.id,
        characterId: characterId ?? this.characterId,
        photoPath: photoPath ?? this.photoPath,
        caption: caption.present ? caption.value : this.caption,
        createdAt: createdAt ?? this.createdAt,
      );
  CharacterPhoto copyWithCompanion(CharacterPhotosCompanion data) {
    return CharacterPhoto(
      id: data.id.present ? data.id.value : this.id,
      characterId:
          data.characterId.present ? data.characterId.value : this.characterId,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      caption: data.caption.present ? data.caption.value : this.caption,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterPhoto(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('photoPath: $photoPath, ')
          ..write('caption: $caption, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, characterId, photoPath, caption, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterPhoto &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.photoPath == this.photoPath &&
          other.caption == this.caption &&
          other.createdAt == this.createdAt);
}

class CharacterPhotosCompanion extends UpdateCompanion<CharacterPhoto> {
  final Value<int> id;
  final Value<String> characterId;
  final Value<String> photoPath;
  final Value<String?> caption;
  final Value<DateTime> createdAt;
  const CharacterPhotosCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.caption = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CharacterPhotosCompanion.insert({
    this.id = const Value.absent(),
    required String characterId,
    required String photoPath,
    this.caption = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : characterId = Value(characterId),
        photoPath = Value(photoPath);
  static Insertable<CharacterPhoto> custom({
    Expression<int>? id,
    Expression<String>? characterId,
    Expression<String>? photoPath,
    Expression<String>? caption,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (photoPath != null) 'photo_path': photoPath,
      if (caption != null) 'caption': caption,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CharacterPhotosCompanion copyWith(
      {Value<int>? id,
      Value<String>? characterId,
      Value<String>? photoPath,
      Value<String?>? caption,
      Value<DateTime>? createdAt}) {
    return CharacterPhotosCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      photoPath: photoPath ?? this.photoPath,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterPhotosCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('photoPath: $photoPath, ')
          ..write('caption: $caption, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ThreadsTable extends Threads with TableInfo<$ThreadsTable, Thread> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ThreadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastMessageIdMeta =
      const VerificationMeta('lastMessageId');
  @override
  late final GeneratedColumn<int> lastMessageId = GeneratedColumn<int>(
      'last_message_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isLockedMeta =
      const VerificationMeta('isLocked');
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
      'is_locked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_locked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isTypingMeta =
      const VerificationMeta('isTyping');
  @override
  late final GeneratedColumn<bool> isTyping = GeneratedColumn<bool>(
      'is_typing', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_typing" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSecretMeta =
      const VerificationMeta('isSecret');
  @override
  late final GeneratedColumn<bool> isSecret = GeneratedColumn<bool>(
      'is_secret', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_secret" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _unreadCountMeta =
      const VerificationMeta('unreadCount');
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
      'unread_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _participantsMeta =
      const VerificationMeta('participants');
  @override
  late final GeneratedColumn<String> participants = GeneratedColumn<String>(
      'participants', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        lastMessageId,
        isLocked,
        isTyping,
        isSecret,
        unreadCount,
        participants
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'threads';
  @override
  VerificationContext validateIntegrity(Insertable<Thread> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('last_message_id')) {
      context.handle(
          _lastMessageIdMeta,
          lastMessageId.isAcceptableOrUnknown(
              data['last_message_id']!, _lastMessageIdMeta));
    }
    if (data.containsKey('is_locked')) {
      context.handle(_isLockedMeta,
          isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta));
    }
    if (data.containsKey('is_typing')) {
      context.handle(_isTypingMeta,
          isTyping.isAcceptableOrUnknown(data['is_typing']!, _isTypingMeta));
    }
    if (data.containsKey('is_secret')) {
      context.handle(_isSecretMeta,
          isSecret.isAcceptableOrUnknown(data['is_secret']!, _isSecretMeta));
    }
    if (data.containsKey('unread_count')) {
      context.handle(
          _unreadCountMeta,
          unreadCount.isAcceptableOrUnknown(
              data['unread_count']!, _unreadCountMeta));
    }
    if (data.containsKey('participants')) {
      context.handle(
          _participantsMeta,
          participants.isAcceptableOrUnknown(
              data['participants']!, _participantsMeta));
    } else if (isInserting) {
      context.missing(_participantsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Thread map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Thread(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      lastMessageId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_message_id']),
      isLocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_locked'])!,
      isTyping: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_typing'])!,
      isSecret: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_secret'])!,
      unreadCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unread_count'])!,
      participants: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}participants'])!,
    );
  }

  @override
  $ThreadsTable createAlias(String alias) {
    return $ThreadsTable(attachedDatabase, alias);
  }
}

class Thread extends DataClass implements Insertable<Thread> {
  final String id;
  final String title;
  final int? lastMessageId;
  final bool isLocked;
  final bool isTyping;
  final bool isSecret;
  final int unreadCount;
  final String participants;
  const Thread(
      {required this.id,
      required this.title,
      this.lastMessageId,
      required this.isLocked,
      required this.isTyping,
      required this.isSecret,
      required this.unreadCount,
      required this.participants});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || lastMessageId != null) {
      map['last_message_id'] = Variable<int>(lastMessageId);
    }
    map['is_locked'] = Variable<bool>(isLocked);
    map['is_typing'] = Variable<bool>(isTyping);
    map['is_secret'] = Variable<bool>(isSecret);
    map['unread_count'] = Variable<int>(unreadCount);
    map['participants'] = Variable<String>(participants);
    return map;
  }

  ThreadsCompanion toCompanion(bool nullToAbsent) {
    return ThreadsCompanion(
      id: Value(id),
      title: Value(title),
      lastMessageId: lastMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageId),
      isLocked: Value(isLocked),
      isTyping: Value(isTyping),
      isSecret: Value(isSecret),
      unreadCount: Value(unreadCount),
      participants: Value(participants),
    );
  }

  factory Thread.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Thread(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      lastMessageId: serializer.fromJson<int?>(json['lastMessageId']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      isTyping: serializer.fromJson<bool>(json['isTyping']),
      isSecret: serializer.fromJson<bool>(json['isSecret']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      participants: serializer.fromJson<String>(json['participants']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'lastMessageId': serializer.toJson<int?>(lastMessageId),
      'isLocked': serializer.toJson<bool>(isLocked),
      'isTyping': serializer.toJson<bool>(isTyping),
      'isSecret': serializer.toJson<bool>(isSecret),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'participants': serializer.toJson<String>(participants),
    };
  }

  Thread copyWith(
          {String? id,
          String? title,
          Value<int?> lastMessageId = const Value.absent(),
          bool? isLocked,
          bool? isTyping,
          bool? isSecret,
          int? unreadCount,
          String? participants}) =>
      Thread(
        id: id ?? this.id,
        title: title ?? this.title,
        lastMessageId:
            lastMessageId.present ? lastMessageId.value : this.lastMessageId,
        isLocked: isLocked ?? this.isLocked,
        isTyping: isTyping ?? this.isTyping,
        isSecret: isSecret ?? this.isSecret,
        unreadCount: unreadCount ?? this.unreadCount,
        participants: participants ?? this.participants,
      );
  Thread copyWithCompanion(ThreadsCompanion data) {
    return Thread(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      lastMessageId: data.lastMessageId.present
          ? data.lastMessageId.value
          : this.lastMessageId,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      isTyping: data.isTyping.present ? data.isTyping.value : this.isTyping,
      isSecret: data.isSecret.present ? data.isSecret.value : this.isSecret,
      unreadCount:
          data.unreadCount.present ? data.unreadCount.value : this.unreadCount,
      participants: data.participants.present
          ? data.participants.value
          : this.participants,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Thread(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('isLocked: $isLocked, ')
          ..write('isTyping: $isTyping, ')
          ..write('isSecret: $isSecret, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('participants: $participants')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, lastMessageId, isLocked, isTyping,
      isSecret, unreadCount, participants);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Thread &&
          other.id == this.id &&
          other.title == this.title &&
          other.lastMessageId == this.lastMessageId &&
          other.isLocked == this.isLocked &&
          other.isTyping == this.isTyping &&
          other.isSecret == this.isSecret &&
          other.unreadCount == this.unreadCount &&
          other.participants == this.participants);
}

class ThreadsCompanion extends UpdateCompanion<Thread> {
  final Value<String> id;
  final Value<String> title;
  final Value<int?> lastMessageId;
  final Value<bool> isLocked;
  final Value<bool> isTyping;
  final Value<bool> isSecret;
  final Value<int> unreadCount;
  final Value<String> participants;
  final Value<int> rowid;
  const ThreadsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.isTyping = const Value.absent(),
    this.isSecret = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.participants = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ThreadsCompanion.insert({
    required String id,
    required String title,
    this.lastMessageId = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.isTyping = const Value.absent(),
    this.isSecret = const Value.absent(),
    this.unreadCount = const Value.absent(),
    required String participants,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        participants = Value(participants);
  static Insertable<Thread> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? lastMessageId,
    Expression<bool>? isLocked,
    Expression<bool>? isTyping,
    Expression<bool>? isSecret,
    Expression<int>? unreadCount,
    Expression<String>? participants,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (lastMessageId != null) 'last_message_id': lastMessageId,
      if (isLocked != null) 'is_locked': isLocked,
      if (isTyping != null) 'is_typing': isTyping,
      if (isSecret != null) 'is_secret': isSecret,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (participants != null) 'participants': participants,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ThreadsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<int?>? lastMessageId,
      Value<bool>? isLocked,
      Value<bool>? isTyping,
      Value<bool>? isSecret,
      Value<int>? unreadCount,
      Value<String>? participants,
      Value<int>? rowid}) {
    return ThreadsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      isLocked: isLocked ?? this.isLocked,
      isTyping: isTyping ?? this.isTyping,
      isSecret: isSecret ?? this.isSecret,
      unreadCount: unreadCount ?? this.unreadCount,
      participants: participants ?? this.participants,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (lastMessageId.present) {
      map['last_message_id'] = Variable<int>(lastMessageId.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (isTyping.present) {
      map['is_typing'] = Variable<bool>(isTyping.value);
    }
    if (isSecret.present) {
      map['is_secret'] = Variable<bool>(isSecret.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (participants.present) {
      map['participants'] = Variable<String>(participants.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ThreadsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('isLocked: $isLocked, ')
          ..write('isTyping: $isTyping, ')
          ..write('isSecret: $isSecret, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('participants: $participants, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ThreadMembersTable extends ThreadMembers
    with TableInfo<$ThreadMembersTable, ThreadMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ThreadMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _threadIdMeta =
      const VerificationMeta('threadId');
  @override
  late final GeneratedColumn<String> threadId = GeneratedColumn<String>(
      'thread_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES threads (id)'));
  static const VerificationMeta _characterIdMeta =
      const VerificationMeta('characterId');
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
      'character_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES characters (id)'));
  @override
  List<GeneratedColumn> get $columns => [threadId, characterId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'thread_members';
  @override
  VerificationContext validateIntegrity(Insertable<ThreadMember> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('thread_id')) {
      context.handle(_threadIdMeta,
          threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta));
    } else if (isInserting) {
      context.missing(_threadIdMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
          _characterIdMeta,
          characterId.isAcceptableOrUnknown(
              data['character_id']!, _characterIdMeta));
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {threadId, characterId};
  @override
  ThreadMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ThreadMember(
      threadId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thread_id'])!,
      characterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}character_id'])!,
    );
  }

  @override
  $ThreadMembersTable createAlias(String alias) {
    return $ThreadMembersTable(attachedDatabase, alias);
  }
}

class ThreadMember extends DataClass implements Insertable<ThreadMember> {
  final String threadId;
  final String characterId;
  const ThreadMember({required this.threadId, required this.characterId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['thread_id'] = Variable<String>(threadId);
    map['character_id'] = Variable<String>(characterId);
    return map;
  }

  ThreadMembersCompanion toCompanion(bool nullToAbsent) {
    return ThreadMembersCompanion(
      threadId: Value(threadId),
      characterId: Value(characterId),
    );
  }

  factory ThreadMember.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ThreadMember(
      threadId: serializer.fromJson<String>(json['threadId']),
      characterId: serializer.fromJson<String>(json['characterId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'threadId': serializer.toJson<String>(threadId),
      'characterId': serializer.toJson<String>(characterId),
    };
  }

  ThreadMember copyWith({String? threadId, String? characterId}) =>
      ThreadMember(
        threadId: threadId ?? this.threadId,
        characterId: characterId ?? this.characterId,
      );
  ThreadMember copyWithCompanion(ThreadMembersCompanion data) {
    return ThreadMember(
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      characterId:
          data.characterId.present ? data.characterId.value : this.characterId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ThreadMember(')
          ..write('threadId: $threadId, ')
          ..write('characterId: $characterId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(threadId, characterId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThreadMember &&
          other.threadId == this.threadId &&
          other.characterId == this.characterId);
}

class ThreadMembersCompanion extends UpdateCompanion<ThreadMember> {
  final Value<String> threadId;
  final Value<String> characterId;
  final Value<int> rowid;
  const ThreadMembersCompanion({
    this.threadId = const Value.absent(),
    this.characterId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ThreadMembersCompanion.insert({
    required String threadId,
    required String characterId,
    this.rowid = const Value.absent(),
  })  : threadId = Value(threadId),
        characterId = Value(characterId);
  static Insertable<ThreadMember> custom({
    Expression<String>? threadId,
    Expression<String>? characterId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (threadId != null) 'thread_id': threadId,
      if (characterId != null) 'character_id': characterId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ThreadMembersCompanion copyWith(
      {Value<String>? threadId,
      Value<String>? characterId,
      Value<int>? rowid}) {
    return ThreadMembersCompanion(
      threadId: threadId ?? this.threadId,
      characterId: characterId ?? this.characterId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (threadId.present) {
      map['thread_id'] = Variable<String>(threadId.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ThreadMembersCompanion(')
          ..write('threadId: $threadId, ')
          ..write('characterId: $characterId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoryNodesTable extends StoryNodes
    with TableInfo<$StoryNodesTable, StoryNode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryNodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderIdMeta =
      const VerificationMeta('senderId');
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
      'sender_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES characters (id)'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nextNodeIdMeta =
      const VerificationMeta('nextNodeId');
  @override
  late final GeneratedColumn<String> nextNodeId = GeneratedColumn<String>(
      'next_node_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, type, senderId, content, nextNodeId, metadata];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_nodes';
  @override
  VerificationContext validateIntegrity(Insertable<StoryNode> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('next_node_id')) {
      context.handle(
          _nextNodeIdMeta,
          nextNodeId.isAcceptableOrUnknown(
              data['next_node_id']!, _nextNodeIdMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoryNode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryNode(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_id']),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      nextNodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}next_node_id']),
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
    );
  }

  @override
  $StoryNodesTable createAlias(String alias) {
    return $StoryNodesTable(attachedDatabase, alias);
  }
}

class StoryNode extends DataClass implements Insertable<StoryNode> {
  final String id;
  final String type;
  final String? senderId;
  final String? content;
  final String? nextNodeId;
  final String? metadata;
  const StoryNode(
      {required this.id,
      required this.type,
      this.senderId,
      this.content,
      this.nextNodeId,
      this.metadata});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || senderId != null) {
      map['sender_id'] = Variable<String>(senderId);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || nextNodeId != null) {
      map['next_node_id'] = Variable<String>(nextNodeId);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  StoryNodesCompanion toCompanion(bool nullToAbsent) {
    return StoryNodesCompanion(
      id: Value(id),
      type: Value(type),
      senderId: senderId == null && nullToAbsent
          ? const Value.absent()
          : Value(senderId),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      nextNodeId: nextNodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(nextNodeId),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory StoryNode.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryNode(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      senderId: serializer.fromJson<String?>(json['senderId']),
      content: serializer.fromJson<String?>(json['content']),
      nextNodeId: serializer.fromJson<String?>(json['nextNodeId']),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'senderId': serializer.toJson<String?>(senderId),
      'content': serializer.toJson<String?>(content),
      'nextNodeId': serializer.toJson<String?>(nextNodeId),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  StoryNode copyWith(
          {String? id,
          String? type,
          Value<String?> senderId = const Value.absent(),
          Value<String?> content = const Value.absent(),
          Value<String?> nextNodeId = const Value.absent(),
          Value<String?> metadata = const Value.absent()}) =>
      StoryNode(
        id: id ?? this.id,
        type: type ?? this.type,
        senderId: senderId.present ? senderId.value : this.senderId,
        content: content.present ? content.value : this.content,
        nextNodeId: nextNodeId.present ? nextNodeId.value : this.nextNodeId,
        metadata: metadata.present ? metadata.value : this.metadata,
      );
  StoryNode copyWithCompanion(StoryNodesCompanion data) {
    return StoryNode(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      content: data.content.present ? data.content.value : this.content,
      nextNodeId:
          data.nextNodeId.present ? data.nextNodeId.value : this.nextNodeId,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryNode(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('nextNodeId: $nextNodeId, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, senderId, content, nextNodeId, metadata);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryNode &&
          other.id == this.id &&
          other.type == this.type &&
          other.senderId == this.senderId &&
          other.content == this.content &&
          other.nextNodeId == this.nextNodeId &&
          other.metadata == this.metadata);
}

class StoryNodesCompanion extends UpdateCompanion<StoryNode> {
  final Value<String> id;
  final Value<String> type;
  final Value<String?> senderId;
  final Value<String?> content;
  final Value<String?> nextNodeId;
  final Value<String?> metadata;
  final Value<int> rowid;
  const StoryNodesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.senderId = const Value.absent(),
    this.content = const Value.absent(),
    this.nextNodeId = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoryNodesCompanion.insert({
    required String id,
    required String type,
    this.senderId = const Value.absent(),
    this.content = const Value.absent(),
    this.nextNodeId = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        type = Value(type);
  static Insertable<StoryNode> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? senderId,
    Expression<String>? content,
    Expression<String>? nextNodeId,
    Expression<String>? metadata,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (senderId != null) 'sender_id': senderId,
      if (content != null) 'content': content,
      if (nextNodeId != null) 'next_node_id': nextNodeId,
      if (metadata != null) 'metadata': metadata,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoryNodesCompanion copyWith(
      {Value<String>? id,
      Value<String>? type,
      Value<String?>? senderId,
      Value<String?>? content,
      Value<String?>? nextNodeId,
      Value<String?>? metadata,
      Value<int>? rowid}) {
    return StoryNodesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      nextNodeId: nextNodeId ?? this.nextNodeId,
      metadata: metadata ?? this.metadata,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (nextNodeId.present) {
      map['next_node_id'] = Variable<String>(nextNodeId.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryNodesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('nextNodeId: $nextNodeId, ')
          ..write('metadata: $metadata, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
      'node_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES story_nodes (id)'));
  static const VerificationMeta _threadIdMeta =
      const VerificationMeta('threadId');
  @override
  late final GeneratedColumn<String> threadId = GeneratedColumn<String>(
      'thread_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES threads (id) ON DELETE CASCADE'));
  static const VerificationMeta _senderIdMeta =
      const VerificationMeta('senderId');
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
      'sender_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('text'));
  static const VerificationMeta _mediaPathMeta =
      const VerificationMeta('mediaPath');
  @override
  late final GeneratedColumn<String> mediaPath = GeneratedColumn<String>(
      'media_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sequenceMeta =
      const VerificationMeta('sequence');
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
      'sequence', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isPlayerMessageMeta =
      const VerificationMeta('isPlayerMessage');
  @override
  late final GeneratedColumn<bool> isPlayerMessage = GeneratedColumn<bool>(
      'is_player_message', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_player_message" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSecretMeta =
      const VerificationMeta('isSecret');
  @override
  late final GeneratedColumn<bool> isSecret = GeneratedColumn<bool>(
      'is_secret', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_secret" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _metaMeta = const VerificationMeta('meta');
  @override
  late final GeneratedColumn<String> meta = GeneratedColumn<String>(
      'meta', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        nodeId,
        threadId,
        senderId,
        content,
        type,
        mediaPath,
        sequence,
        timestamp,
        isPlayerMessage,
        isSecret,
        isRead,
        meta
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(Insertable<Message> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('node_id')) {
      context.handle(_nodeIdMeta,
          nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta));
    }
    if (data.containsKey('thread_id')) {
      context.handle(_threadIdMeta,
          threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta));
    } else if (isInserting) {
      context.missing(_threadIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta));
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('media_path')) {
      context.handle(_mediaPathMeta,
          mediaPath.isAcceptableOrUnknown(data['media_path']!, _mediaPathMeta));
    }
    if (data.containsKey('sequence')) {
      context.handle(_sequenceMeta,
          sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta));
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    if (data.containsKey('is_player_message')) {
      context.handle(
          _isPlayerMessageMeta,
          isPlayerMessage.isAcceptableOrUnknown(
              data['is_player_message']!, _isPlayerMessageMeta));
    }
    if (data.containsKey('is_secret')) {
      context.handle(_isSecretMeta,
          isSecret.isAcceptableOrUnknown(data['is_secret']!, _isSecretMeta));
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('meta')) {
      context.handle(
          _metaMeta, meta.isAcceptableOrUnknown(data['meta']!, _metaMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}node_id']),
      threadId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thread_id'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      mediaPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_path']),
      sequence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sequence'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      isPlayerMessage: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_player_message'])!,
      isSecret: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_secret'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      meta: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meta']),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final int id;
  final String? nodeId;
  final String threadId;
  final String senderId;
  final String? content;
  final String type;
  final String? mediaPath;
  final int sequence;
  final DateTime timestamp;
  final bool isPlayerMessage;
  final bool isSecret;
  final bool isRead;
  final String? meta;
  const Message(
      {required this.id,
      this.nodeId,
      required this.threadId,
      required this.senderId,
      this.content,
      required this.type,
      this.mediaPath,
      required this.sequence,
      required this.timestamp,
      required this.isPlayerMessage,
      required this.isSecret,
      required this.isRead,
      this.meta});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || nodeId != null) {
      map['node_id'] = Variable<String>(nodeId);
    }
    map['thread_id'] = Variable<String>(threadId);
    map['sender_id'] = Variable<String>(senderId);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || mediaPath != null) {
      map['media_path'] = Variable<String>(mediaPath);
    }
    map['sequence'] = Variable<int>(sequence);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['is_player_message'] = Variable<bool>(isPlayerMessage);
    map['is_secret'] = Variable<bool>(isSecret);
    map['is_read'] = Variable<bool>(isRead);
    if (!nullToAbsent || meta != null) {
      map['meta'] = Variable<String>(meta);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      nodeId:
          nodeId == null && nullToAbsent ? const Value.absent() : Value(nodeId),
      threadId: Value(threadId),
      senderId: Value(senderId),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      type: Value(type),
      mediaPath: mediaPath == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaPath),
      sequence: Value(sequence),
      timestamp: Value(timestamp),
      isPlayerMessage: Value(isPlayerMessage),
      isSecret: Value(isSecret),
      isRead: Value(isRead),
      meta: meta == null && nullToAbsent ? const Value.absent() : Value(meta),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<int>(json['id']),
      nodeId: serializer.fromJson<String?>(json['nodeId']),
      threadId: serializer.fromJson<String>(json['threadId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      content: serializer.fromJson<String?>(json['content']),
      type: serializer.fromJson<String>(json['type']),
      mediaPath: serializer.fromJson<String?>(json['mediaPath']),
      sequence: serializer.fromJson<int>(json['sequence']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      isPlayerMessage: serializer.fromJson<bool>(json['isPlayerMessage']),
      isSecret: serializer.fromJson<bool>(json['isSecret']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      meta: serializer.fromJson<String?>(json['meta']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nodeId': serializer.toJson<String?>(nodeId),
      'threadId': serializer.toJson<String>(threadId),
      'senderId': serializer.toJson<String>(senderId),
      'content': serializer.toJson<String?>(content),
      'type': serializer.toJson<String>(type),
      'mediaPath': serializer.toJson<String?>(mediaPath),
      'sequence': serializer.toJson<int>(sequence),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'isPlayerMessage': serializer.toJson<bool>(isPlayerMessage),
      'isSecret': serializer.toJson<bool>(isSecret),
      'isRead': serializer.toJson<bool>(isRead),
      'meta': serializer.toJson<String?>(meta),
    };
  }

  Message copyWith(
          {int? id,
          Value<String?> nodeId = const Value.absent(),
          String? threadId,
          String? senderId,
          Value<String?> content = const Value.absent(),
          String? type,
          Value<String?> mediaPath = const Value.absent(),
          int? sequence,
          DateTime? timestamp,
          bool? isPlayerMessage,
          bool? isSecret,
          bool? isRead,
          Value<String?> meta = const Value.absent()}) =>
      Message(
        id: id ?? this.id,
        nodeId: nodeId.present ? nodeId.value : this.nodeId,
        threadId: threadId ?? this.threadId,
        senderId: senderId ?? this.senderId,
        content: content.present ? content.value : this.content,
        type: type ?? this.type,
        mediaPath: mediaPath.present ? mediaPath.value : this.mediaPath,
        sequence: sequence ?? this.sequence,
        timestamp: timestamp ?? this.timestamp,
        isPlayerMessage: isPlayerMessage ?? this.isPlayerMessage,
        isSecret: isSecret ?? this.isSecret,
        isRead: isRead ?? this.isRead,
        meta: meta.present ? meta.value : this.meta,
      );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      content: data.content.present ? data.content.value : this.content,
      type: data.type.present ? data.type.value : this.type,
      mediaPath: data.mediaPath.present ? data.mediaPath.value : this.mediaPath,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isPlayerMessage: data.isPlayerMessage.present
          ? data.isPlayerMessage.value
          : this.isPlayerMessage,
      isSecret: data.isSecret.present ? data.isSecret.value : this.isSecret,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      meta: data.meta.present ? data.meta.value : this.meta,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('nodeId: $nodeId, ')
          ..write('threadId: $threadId, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('type: $type, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('sequence: $sequence, ')
          ..write('timestamp: $timestamp, ')
          ..write('isPlayerMessage: $isPlayerMessage, ')
          ..write('isSecret: $isSecret, ')
          ..write('isRead: $isRead, ')
          ..write('meta: $meta')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nodeId, threadId, senderId, content, type,
      mediaPath, sequence, timestamp, isPlayerMessage, isSecret, isRead, meta);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.nodeId == this.nodeId &&
          other.threadId == this.threadId &&
          other.senderId == this.senderId &&
          other.content == this.content &&
          other.type == this.type &&
          other.mediaPath == this.mediaPath &&
          other.sequence == this.sequence &&
          other.timestamp == this.timestamp &&
          other.isPlayerMessage == this.isPlayerMessage &&
          other.isSecret == this.isSecret &&
          other.isRead == this.isRead &&
          other.meta == this.meta);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> id;
  final Value<String?> nodeId;
  final Value<String> threadId;
  final Value<String> senderId;
  final Value<String?> content;
  final Value<String> type;
  final Value<String?> mediaPath;
  final Value<int> sequence;
  final Value<DateTime> timestamp;
  final Value<bool> isPlayerMessage;
  final Value<bool> isSecret;
  final Value<bool> isRead;
  final Value<String?> meta;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.threadId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.content = const Value.absent(),
    this.type = const Value.absent(),
    this.mediaPath = const Value.absent(),
    this.sequence = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isPlayerMessage = const Value.absent(),
    this.isSecret = const Value.absent(),
    this.isRead = const Value.absent(),
    this.meta = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    this.nodeId = const Value.absent(),
    required String threadId,
    required String senderId,
    this.content = const Value.absent(),
    this.type = const Value.absent(),
    this.mediaPath = const Value.absent(),
    required int sequence,
    this.timestamp = const Value.absent(),
    this.isPlayerMessage = const Value.absent(),
    this.isSecret = const Value.absent(),
    this.isRead = const Value.absent(),
    this.meta = const Value.absent(),
  })  : threadId = Value(threadId),
        senderId = Value(senderId),
        sequence = Value(sequence);
  static Insertable<Message> custom({
    Expression<int>? id,
    Expression<String>? nodeId,
    Expression<String>? threadId,
    Expression<String>? senderId,
    Expression<String>? content,
    Expression<String>? type,
    Expression<String>? mediaPath,
    Expression<int>? sequence,
    Expression<DateTime>? timestamp,
    Expression<bool>? isPlayerMessage,
    Expression<bool>? isSecret,
    Expression<bool>? isRead,
    Expression<String>? meta,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nodeId != null) 'node_id': nodeId,
      if (threadId != null) 'thread_id': threadId,
      if (senderId != null) 'sender_id': senderId,
      if (content != null) 'content': content,
      if (type != null) 'type': type,
      if (mediaPath != null) 'media_path': mediaPath,
      if (sequence != null) 'sequence': sequence,
      if (timestamp != null) 'timestamp': timestamp,
      if (isPlayerMessage != null) 'is_player_message': isPlayerMessage,
      if (isSecret != null) 'is_secret': isSecret,
      if (isRead != null) 'is_read': isRead,
      if (meta != null) 'meta': meta,
    });
  }

  MessagesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? nodeId,
      Value<String>? threadId,
      Value<String>? senderId,
      Value<String?>? content,
      Value<String>? type,
      Value<String?>? mediaPath,
      Value<int>? sequence,
      Value<DateTime>? timestamp,
      Value<bool>? isPlayerMessage,
      Value<bool>? isSecret,
      Value<bool>? isRead,
      Value<String?>? meta}) {
    return MessagesCompanion(
      id: id ?? this.id,
      nodeId: nodeId ?? this.nodeId,
      threadId: threadId ?? this.threadId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      mediaPath: mediaPath ?? this.mediaPath,
      sequence: sequence ?? this.sequence,
      timestamp: timestamp ?? this.timestamp,
      isPlayerMessage: isPlayerMessage ?? this.isPlayerMessage,
      isSecret: isSecret ?? this.isSecret,
      isRead: isRead ?? this.isRead,
      meta: meta ?? this.meta,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<String>(threadId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (mediaPath.present) {
      map['media_path'] = Variable<String>(mediaPath.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (isPlayerMessage.present) {
      map['is_player_message'] = Variable<bool>(isPlayerMessage.value);
    }
    if (isSecret.present) {
      map['is_secret'] = Variable<bool>(isSecret.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (meta.present) {
      map['meta'] = Variable<String>(meta.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('nodeId: $nodeId, ')
          ..write('threadId: $threadId, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('type: $type, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('sequence: $sequence, ')
          ..write('timestamp: $timestamp, ')
          ..write('isPlayerMessage: $isPlayerMessage, ')
          ..write('isSecret: $isSecret, ')
          ..write('isRead: $isRead, ')
          ..write('meta: $meta')
          ..write(')'))
        .toString();
  }
}

class $NotificationsTable extends Notifications
    with TableInfo<$NotificationsTable, Notification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageMeta =
      const VerificationMeta('message');
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
      'message', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMinutesMeta =
      const VerificationMeta('createdAtMinutes');
  @override
  late final GeneratedColumn<int> createdAtMinutes = GeneratedColumn<int>(
      'created_at_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, type, title, message, createdAtMinutes, payload, isRead];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications';
  @override
  VerificationContext validateIntegrity(Insertable<Notification> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta,
          message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('created_at_minutes')) {
      context.handle(
          _createdAtMinutesMeta,
          createdAtMinutes.isAcceptableOrUnknown(
              data['created_at_minutes']!, _createdAtMinutesMeta));
    } else if (isInserting) {
      context.missing(_createdAtMinutesMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Notification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Notification(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      message: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message'])!,
      createdAtMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}created_at_minutes'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload']),
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
    );
  }

  @override
  $NotificationsTable createAlias(String alias) {
    return $NotificationsTable(attachedDatabase, alias);
  }
}

class Notification extends DataClass implements Insertable<Notification> {
  final String id;
  final String type;
  final String title;
  final String message;
  final int createdAtMinutes;
  final String? payload;
  final bool isRead;
  const Notification(
      {required this.id,
      required this.type,
      required this.title,
      required this.message,
      required this.createdAtMinutes,
      this.payload,
      required this.isRead});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['message'] = Variable<String>(message);
    map['created_at_minutes'] = Variable<int>(createdAtMinutes);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    map['is_read'] = Variable<bool>(isRead);
    return map;
  }

  NotificationsCompanion toCompanion(bool nullToAbsent) {
    return NotificationsCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      message: Value(message),
      createdAtMinutes: Value(createdAtMinutes),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      isRead: Value(isRead),
    );
  }

  factory Notification.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Notification(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      message: serializer.fromJson<String>(json['message']),
      createdAtMinutes: serializer.fromJson<int>(json['createdAtMinutes']),
      payload: serializer.fromJson<String?>(json['payload']),
      isRead: serializer.fromJson<bool>(json['isRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'message': serializer.toJson<String>(message),
      'createdAtMinutes': serializer.toJson<int>(createdAtMinutes),
      'payload': serializer.toJson<String?>(payload),
      'isRead': serializer.toJson<bool>(isRead),
    };
  }

  Notification copyWith(
          {String? id,
          String? type,
          String? title,
          String? message,
          int? createdAtMinutes,
          Value<String?> payload = const Value.absent(),
          bool? isRead}) =>
      Notification(
        id: id ?? this.id,
        type: type ?? this.type,
        title: title ?? this.title,
        message: message ?? this.message,
        createdAtMinutes: createdAtMinutes ?? this.createdAtMinutes,
        payload: payload.present ? payload.value : this.payload,
        isRead: isRead ?? this.isRead,
      );
  Notification copyWithCompanion(NotificationsCompanion data) {
    return Notification(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      message: data.message.present ? data.message.value : this.message,
      createdAtMinutes: data.createdAtMinutes.present
          ? data.createdAtMinutes.value
          : this.createdAtMinutes,
      payload: data.payload.present ? data.payload.value : this.payload,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Notification(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('createdAtMinutes: $createdAtMinutes, ')
          ..write('payload: $payload, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, title, message, createdAtMinutes, payload, isRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Notification &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.message == this.message &&
          other.createdAtMinutes == this.createdAtMinutes &&
          other.payload == this.payload &&
          other.isRead == this.isRead);
}

class NotificationsCompanion extends UpdateCompanion<Notification> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> title;
  final Value<String> message;
  final Value<int> createdAtMinutes;
  final Value<String?> payload;
  final Value<bool> isRead;
  final Value<int> rowid;
  const NotificationsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAtMinutes = const Value.absent(),
    this.payload = const Value.absent(),
    this.isRead = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationsCompanion.insert({
    required String id,
    required String type,
    required String title,
    required String message,
    required int createdAtMinutes,
    this.payload = const Value.absent(),
    this.isRead = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        type = Value(type),
        title = Value(title),
        message = Value(message),
        createdAtMinutes = Value(createdAtMinutes);
  static Insertable<Notification> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? message,
    Expression<int>? createdAtMinutes,
    Expression<String>? payload,
    Expression<bool>? isRead,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (createdAtMinutes != null) 'created_at_minutes': createdAtMinutes,
      if (payload != null) 'payload': payload,
      if (isRead != null) 'is_read': isRead,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? type,
      Value<String>? title,
      Value<String>? message,
      Value<int>? createdAtMinutes,
      Value<String?>? payload,
      Value<bool>? isRead,
      Value<int>? rowid}) {
    return NotificationsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAtMinutes: createdAtMinutes ?? this.createdAtMinutes,
      payload: payload ?? this.payload,
      isRead: isRead ?? this.isRead,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (createdAtMinutes.present) {
      map['created_at_minutes'] = Variable<int>(createdAtMinutes.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('createdAtMinutes: $createdAtMinutes, ')
          ..write('payload: $payload, ')
          ..write('isRead: $isRead, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoryStateTable extends StoryState
    with TableInfo<$StoryStateTable, StoryStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<bool> value = GeneratedColumn<bool>(
      'value', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("value" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _intValueMeta =
      const VerificationMeta('intValue');
  @override
  late final GeneratedColumn<int> intValue = GeneratedColumn<int>(
      'int_value', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _stringValueMeta =
      const VerificationMeta('stringValue');
  @override
  late final GeneratedColumn<String> stringValue = GeneratedColumn<String>(
      'string_value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [key, value, intValue, stringValue, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_state';
  @override
  VerificationContext validateIntegrity(Insertable<StoryStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('int_value')) {
      context.handle(_intValueMeta,
          intValue.isAcceptableOrUnknown(data['int_value']!, _intValueMeta));
    }
    if (data.containsKey('string_value')) {
      context.handle(
          _stringValueMeta,
          stringValue.isAcceptableOrUnknown(
              data['string_value']!, _stringValueMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  StoryStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryStateData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}value'])!,
      intValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}int_value'])!,
      stringValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}string_value']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $StoryStateTable createAlias(String alias) {
    return $StoryStateTable(attachedDatabase, alias);
  }
}

class StoryStateData extends DataClass implements Insertable<StoryStateData> {
  final String key;
  final bool value;
  final int intValue;
  final String? stringValue;
  final DateTime updatedAt;
  const StoryStateData(
      {required this.key,
      required this.value,
      required this.intValue,
      this.stringValue,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<bool>(value);
    map['int_value'] = Variable<int>(intValue);
    if (!nullToAbsent || stringValue != null) {
      map['string_value'] = Variable<String>(stringValue);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StoryStateCompanion toCompanion(bool nullToAbsent) {
    return StoryStateCompanion(
      key: Value(key),
      value: Value(value),
      intValue: Value(intValue),
      stringValue: stringValue == null && nullToAbsent
          ? const Value.absent()
          : Value(stringValue),
      updatedAt: Value(updatedAt),
    );
  }

  factory StoryStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryStateData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<bool>(json['value']),
      intValue: serializer.fromJson<int>(json['intValue']),
      stringValue: serializer.fromJson<String?>(json['stringValue']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<bool>(value),
      'intValue': serializer.toJson<int>(intValue),
      'stringValue': serializer.toJson<String?>(stringValue),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StoryStateData copyWith(
          {String? key,
          bool? value,
          int? intValue,
          Value<String?> stringValue = const Value.absent(),
          DateTime? updatedAt}) =>
      StoryStateData(
        key: key ?? this.key,
        value: value ?? this.value,
        intValue: intValue ?? this.intValue,
        stringValue: stringValue.present ? stringValue.value : this.stringValue,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  StoryStateData copyWithCompanion(StoryStateCompanion data) {
    return StoryStateData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      intValue: data.intValue.present ? data.intValue.value : this.intValue,
      stringValue:
          data.stringValue.present ? data.stringValue.value : this.stringValue,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryStateData(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('intValue: $intValue, ')
          ..write('stringValue: $stringValue, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, intValue, stringValue, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryStateData &&
          other.key == this.key &&
          other.value == this.value &&
          other.intValue == this.intValue &&
          other.stringValue == this.stringValue &&
          other.updatedAt == this.updatedAt);
}

class StoryStateCompanion extends UpdateCompanion<StoryStateData> {
  final Value<String> key;
  final Value<bool> value;
  final Value<int> intValue;
  final Value<String?> stringValue;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StoryStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.intValue = const Value.absent(),
    this.stringValue = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoryStateCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.intValue = const Value.absent(),
    this.stringValue = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<StoryStateData> custom({
    Expression<String>? key,
    Expression<bool>? value,
    Expression<int>? intValue,
    Expression<String>? stringValue,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (intValue != null) 'int_value': intValue,
      if (stringValue != null) 'string_value': stringValue,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoryStateCompanion copyWith(
      {Value<String>? key,
      Value<bool>? value,
      Value<int>? intValue,
      Value<String?>? stringValue,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return StoryStateCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      intValue: intValue ?? this.intValue,
      stringValue: stringValue ?? this.stringValue,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<bool>(value.value);
    }
    if (intValue.present) {
      map['int_value'] = Variable<int>(intValue.value);
    }
    if (stringValue.present) {
      map['string_value'] = Variable<String>(stringValue.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('intValue: $intValue, ')
          ..write('stringValue: $stringValue, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTable extends Episodes with TableInfo<$EpisodesTable, Episode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isUnlockedMeta =
      const VerificationMeta('isUnlocked');
  @override
  late final GeneratedColumn<bool> isUnlocked = GeneratedColumn<bool>(
      'is_unlocked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_unlocked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
      'progress', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [id, isUnlocked, progress, version];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(Insertable<Episode> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_unlocked')) {
      context.handle(
          _isUnlockedMeta,
          isUnlocked.isAcceptableOrUnknown(
              data['is_unlocked']!, _isUnlockedMeta));
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Episode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Episode(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      isUnlocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_unlocked'])!,
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }
}

class Episode extends DataClass implements Insertable<Episode> {
  final String id;
  final bool isUnlocked;
  final int progress;
  final int version;
  const Episode(
      {required this.id,
      required this.isUnlocked,
      required this.progress,
      required this.version});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_unlocked'] = Variable<bool>(isUnlocked);
    map['progress'] = Variable<int>(progress);
    map['version'] = Variable<int>(version);
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      id: Value(id),
      isUnlocked: Value(isUnlocked),
      progress: Value(progress),
      version: Value(version),
    );
  }

  factory Episode.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Episode(
      id: serializer.fromJson<String>(json['id']),
      isUnlocked: serializer.fromJson<bool>(json['isUnlocked']),
      progress: serializer.fromJson<int>(json['progress']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isUnlocked': serializer.toJson<bool>(isUnlocked),
      'progress': serializer.toJson<int>(progress),
      'version': serializer.toJson<int>(version),
    };
  }

  Episode copyWith(
          {String? id, bool? isUnlocked, int? progress, int? version}) =>
      Episode(
        id: id ?? this.id,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        progress: progress ?? this.progress,
        version: version ?? this.version,
      );
  Episode copyWithCompanion(EpisodesCompanion data) {
    return Episode(
      id: data.id.present ? data.id.value : this.id,
      isUnlocked:
          data.isUnlocked.present ? data.isUnlocked.value : this.isUnlocked,
      progress: data.progress.present ? data.progress.value : this.progress,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Episode(')
          ..write('id: $id, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('progress: $progress, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, isUnlocked, progress, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Episode &&
          other.id == this.id &&
          other.isUnlocked == this.isUnlocked &&
          other.progress == this.progress &&
          other.version == this.version);
}

class EpisodesCompanion extends UpdateCompanion<Episode> {
  final Value<String> id;
  final Value<bool> isUnlocked;
  final Value<int> progress;
  final Value<int> version;
  final Value<int> rowid;
  const EpisodesCompanion({
    this.id = const Value.absent(),
    this.isUnlocked = const Value.absent(),
    this.progress = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpisodesCompanion.insert({
    required String id,
    this.isUnlocked = const Value.absent(),
    this.progress = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Episode> custom({
    Expression<String>? id,
    Expression<bool>? isUnlocked,
    Expression<int>? progress,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isUnlocked != null) 'is_unlocked': isUnlocked,
      if (progress != null) 'progress': progress,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpisodesCompanion copyWith(
      {Value<String>? id,
      Value<bool>? isUnlocked,
      Value<int>? progress,
      Value<int>? version,
      Value<int>? rowid}) {
    return EpisodesCompanion(
      id: id ?? this.id,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isUnlocked.present) {
      map['is_unlocked'] = Variable<bool>(isUnlocked.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('id: $id, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('progress: $progress, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlayersTable players = $PlayersTable(this);
  late final $CharactersTable characters = $CharactersTable(this);
  late final $CharacterPhotosTable characterPhotos =
      $CharacterPhotosTable(this);
  late final $ThreadsTable threads = $ThreadsTable(this);
  late final $ThreadMembersTable threadMembers = $ThreadMembersTable(this);
  late final $StoryNodesTable storyNodes = $StoryNodesTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $NotificationsTable notifications = $NotificationsTable(this);
  late final $StoryStateTable storyState = $StoryStateTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        players,
        characters,
        characterPhotos,
        threads,
        threadMembers,
        storyNodes,
        messages,
        notifications,
        storyState,
        episodes
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('characters',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('character_photos', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('threads',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('messages', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$PlayersTableCreateCompanionBuilder = PlayersCompanion Function({
  Value<int> id,
  required String name,
  required String gender,
  Value<String?> profilePath,
  Value<String> phoneNumber,
  Value<DateTime> createdAt,
});
typedef $$PlayersTableUpdateCompanionBuilder = PlayersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> gender,
  Value<String?> profilePath,
  Value<String> phoneNumber,
  Value<DateTime> createdAt,
});

class $$PlayersTableFilterComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profilePath => $composableBuilder(
      column: $table.profilePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profilePath => $composableBuilder(
      column: $table.profilePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get profilePath => $composableBuilder(
      column: $table.profilePath, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlayersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlayersTable,
    Player,
    $$PlayersTableFilterComposer,
    $$PlayersTableOrderingComposer,
    $$PlayersTableAnnotationComposer,
    $$PlayersTableCreateCompanionBuilder,
    $$PlayersTableUpdateCompanionBuilder,
    (Player, BaseReferences<_$AppDatabase, $PlayersTable, Player>),
    Player,
    PrefetchHooks Function()> {
  $$PlayersTableTableManager(_$AppDatabase db, $PlayersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> gender = const Value.absent(),
            Value<String?> profilePath = const Value.absent(),
            Value<String> phoneNumber = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PlayersCompanion(
            id: id,
            name: name,
            gender: gender,
            profilePath: profilePath,
            phoneNumber: phoneNumber,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String gender,
            Value<String?> profilePath = const Value.absent(),
            Value<String> phoneNumber = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PlayersCompanion.insert(
            id: id,
            name: name,
            gender: gender,
            profilePath: profilePath,
            phoneNumber: phoneNumber,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlayersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlayersTable,
    Player,
    $$PlayersTableFilterComposer,
    $$PlayersTableOrderingComposer,
    $$PlayersTableAnnotationComposer,
    $$PlayersTableCreateCompanionBuilder,
    $$PlayersTableUpdateCompanionBuilder,
    (Player, BaseReferences<_$AppDatabase, $PlayersTable, Player>),
    Player,
    PrefetchHooks Function()>;
typedef $$CharactersTableCreateCompanionBuilder = CharactersCompanion Function({
  required String id,
  required String name,
  required String phoneNumber,
  Value<String?> avatarPath,
  Value<String?> bio,
  Value<String?> knownInfo,
  Value<String?> investigationNotes,
  Value<String> colorHex,
  Value<int> rowid,
});
typedef $$CharactersTableUpdateCompanionBuilder = CharactersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> phoneNumber,
  Value<String?> avatarPath,
  Value<String?> bio,
  Value<String?> knownInfo,
  Value<String?> investigationNotes,
  Value<String> colorHex,
  Value<int> rowid,
});

final class $$CharactersTableReferences
    extends BaseReferences<_$AppDatabase, $CharactersTable, Character> {
  $$CharactersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CharacterPhotosTable, List<CharacterPhoto>>
      _characterPhotosRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.characterPhotos,
              aliasName: $_aliasNameGenerator(
                  db.characters.id, db.characterPhotos.characterId));

  $$CharacterPhotosTableProcessedTableManager get characterPhotosRefs {
    final manager = $$CharacterPhotosTableTableManager(
            $_db, $_db.characterPhotos)
        .filter((f) => f.characterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_characterPhotosRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ThreadMembersTable, List<ThreadMember>>
      _threadMembersRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.threadMembers,
              aliasName: $_aliasNameGenerator(
                  db.characters.id, db.threadMembers.characterId));

  $$ThreadMembersTableProcessedTableManager get threadMembersRefs {
    final manager = $$ThreadMembersTableTableManager($_db, $_db.threadMembers)
        .filter((f) => f.characterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_threadMembersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StoryNodesTable, List<StoryNode>>
      _storyNodesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.storyNodes,
          aliasName:
              $_aliasNameGenerator(db.characters.id, db.storyNodes.senderId));

  $$StoryNodesTableProcessedTableManager get storyNodesRefs {
    final manager = $$StoryNodesTableTableManager($_db, $_db.storyNodes)
        .filter((f) => f.senderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_storyNodesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CharactersTableFilterComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bio => $composableBuilder(
      column: $table.bio, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get knownInfo => $composableBuilder(
      column: $table.knownInfo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get investigationNotes => $composableBuilder(
      column: $table.investigationNotes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  Expression<bool> characterPhotosRefs(
      Expression<bool> Function($$CharacterPhotosTableFilterComposer f) f) {
    final $$CharacterPhotosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.characterPhotos,
        getReferencedColumn: (t) => t.characterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CharacterPhotosTableFilterComposer(
              $db: $db,
              $table: $db.characterPhotos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> threadMembersRefs(
      Expression<bool> Function($$ThreadMembersTableFilterComposer f) f) {
    final $$ThreadMembersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.threadMembers,
        getReferencedColumn: (t) => t.characterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ThreadMembersTableFilterComposer(
              $db: $db,
              $table: $db.threadMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> storyNodesRefs(
      Expression<bool> Function($$StoryNodesTableFilterComposer f) f) {
    final $$StoryNodesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.storyNodes,
        getReferencedColumn: (t) => t.senderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoryNodesTableFilterComposer(
              $db: $db,
              $table: $db.storyNodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CharactersTableOrderingComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bio => $composableBuilder(
      column: $table.bio, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get knownInfo => $composableBuilder(
      column: $table.knownInfo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get investigationNotes => $composableBuilder(
      column: $table.investigationNotes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));
}

class $$CharactersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => column);

  GeneratedColumn<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => column);

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<String> get knownInfo =>
      $composableBuilder(column: $table.knownInfo, builder: (column) => column);

  GeneratedColumn<String> get investigationNotes => $composableBuilder(
      column: $table.investigationNotes, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  Expression<T> characterPhotosRefs<T extends Object>(
      Expression<T> Function($$CharacterPhotosTableAnnotationComposer a) f) {
    final $$CharacterPhotosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.characterPhotos,
        getReferencedColumn: (t) => t.characterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CharacterPhotosTableAnnotationComposer(
              $db: $db,
              $table: $db.characterPhotos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> threadMembersRefs<T extends Object>(
      Expression<T> Function($$ThreadMembersTableAnnotationComposer a) f) {
    final $$ThreadMembersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.threadMembers,
        getReferencedColumn: (t) => t.characterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ThreadMembersTableAnnotationComposer(
              $db: $db,
              $table: $db.threadMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> storyNodesRefs<T extends Object>(
      Expression<T> Function($$StoryNodesTableAnnotationComposer a) f) {
    final $$StoryNodesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.storyNodes,
        getReferencedColumn: (t) => t.senderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoryNodesTableAnnotationComposer(
              $db: $db,
              $table: $db.storyNodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CharactersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CharactersTable,
    Character,
    $$CharactersTableFilterComposer,
    $$CharactersTableOrderingComposer,
    $$CharactersTableAnnotationComposer,
    $$CharactersTableCreateCompanionBuilder,
    $$CharactersTableUpdateCompanionBuilder,
    (Character, $$CharactersTableReferences),
    Character,
    PrefetchHooks Function(
        {bool characterPhotosRefs,
        bool threadMembersRefs,
        bool storyNodesRefs})> {
  $$CharactersTableTableManager(_$AppDatabase db, $CharactersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> phoneNumber = const Value.absent(),
            Value<String?> avatarPath = const Value.absent(),
            Value<String?> bio = const Value.absent(),
            Value<String?> knownInfo = const Value.absent(),
            Value<String?> investigationNotes = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CharactersCompanion(
            id: id,
            name: name,
            phoneNumber: phoneNumber,
            avatarPath: avatarPath,
            bio: bio,
            knownInfo: knownInfo,
            investigationNotes: investigationNotes,
            colorHex: colorHex,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String phoneNumber,
            Value<String?> avatarPath = const Value.absent(),
            Value<String?> bio = const Value.absent(),
            Value<String?> knownInfo = const Value.absent(),
            Value<String?> investigationNotes = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CharactersCompanion.insert(
            id: id,
            name: name,
            phoneNumber: phoneNumber,
            avatarPath: avatarPath,
            bio: bio,
            knownInfo: knownInfo,
            investigationNotes: investigationNotes,
            colorHex: colorHex,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CharactersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {characterPhotosRefs = false,
              threadMembersRefs = false,
              storyNodesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (characterPhotosRefs) db.characterPhotos,
                if (threadMembersRefs) db.threadMembers,
                if (storyNodesRefs) db.storyNodes
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (characterPhotosRefs)
                    await $_getPrefetchedData<Character, $CharactersTable,
                            CharacterPhoto>(
                        currentTable: table,
                        referencedTable: $$CharactersTableReferences
                            ._characterPhotosRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CharactersTableReferences(db, table, p0)
                                .characterPhotosRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.characterId == item.id),
                        typedResults: items),
                  if (threadMembersRefs)
                    await $_getPrefetchedData<Character, $CharactersTable,
                            ThreadMember>(
                        currentTable: table,
                        referencedTable: $$CharactersTableReferences
                            ._threadMembersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CharactersTableReferences(db, table, p0)
                                .threadMembersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.characterId == item.id),
                        typedResults: items),
                  if (storyNodesRefs)
                    await $_getPrefetchedData<Character, $CharactersTable,
                            StoryNode>(
                        currentTable: table,
                        referencedTable: $$CharactersTableReferences
                            ._storyNodesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CharactersTableReferences(db, table, p0)
                                .storyNodesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.senderId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CharactersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CharactersTable,
    Character,
    $$CharactersTableFilterComposer,
    $$CharactersTableOrderingComposer,
    $$CharactersTableAnnotationComposer,
    $$CharactersTableCreateCompanionBuilder,
    $$CharactersTableUpdateCompanionBuilder,
    (Character, $$CharactersTableReferences),
    Character,
    PrefetchHooks Function(
        {bool characterPhotosRefs,
        bool threadMembersRefs,
        bool storyNodesRefs})>;
typedef $$CharacterPhotosTableCreateCompanionBuilder = CharacterPhotosCompanion
    Function({
  Value<int> id,
  required String characterId,
  required String photoPath,
  Value<String?> caption,
  Value<DateTime> createdAt,
});
typedef $$CharacterPhotosTableUpdateCompanionBuilder = CharacterPhotosCompanion
    Function({
  Value<int> id,
  Value<String> characterId,
  Value<String> photoPath,
  Value<String?> caption,
  Value<DateTime> createdAt,
});

final class $$CharacterPhotosTableReferences extends BaseReferences<
    _$AppDatabase, $CharacterPhotosTable, CharacterPhoto> {
  $$CharacterPhotosTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $CharactersTable _characterIdTable(_$AppDatabase db) =>
      db.characters.createAlias($_aliasNameGenerator(
          db.characterPhotos.characterId, db.characters.id));

  $$CharactersTableProcessedTableManager get characterId {
    final $_column = $_itemColumn<String>('character_id')!;

    final manager = $$CharactersTableTableManager($_db, $_db.characters)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_characterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CharacterPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $CharacterPhotosTable> {
  $$CharacterPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CharactersTableFilterComposer get characterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.characterId,
        referencedTable: $db.characters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CharactersTableFilterComposer(
              $db: $db,
              $table: $db.characters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CharacterPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $CharacterPhotosTable> {
  $$CharacterPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CharactersTableOrderingComposer get characterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.characterId,
        referencedTable: $db.characters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CharactersTableOrderingComposer(
              $db: $db,
              $table: $db.characters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CharacterPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharacterPhotosTable> {
  $$CharacterPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CharactersTableAnnotationComposer get characterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.characterId,
        referencedTable: $db.characters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CharactersTableAnnotationComposer(
              $db: $db,
              $table: $db.characters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CharacterPhotosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CharacterPhotosTable,
    CharacterPhoto,
    $$CharacterPhotosTableFilterComposer,
    $$CharacterPhotosTableOrderingComposer,
    $$CharacterPhotosTableAnnotationComposer,
    $$CharacterPhotosTableCreateCompanionBuilder,
    $$CharacterPhotosTableUpdateCompanionBuilder,
    (CharacterPhoto, $$CharacterPhotosTableReferences),
    CharacterPhoto,
    PrefetchHooks Function({bool characterId})> {
  $$CharacterPhotosTableTableManager(
      _$AppDatabase db, $CharacterPhotosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharacterPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> characterId = const Value.absent(),
            Value<String> photoPath = const Value.absent(),
            Value<String?> caption = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CharacterPhotosCompanion(
            id: id,
            characterId: characterId,
            photoPath: photoPath,
            caption: caption,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String characterId,
            required String photoPath,
            Value<String?> caption = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CharacterPhotosCompanion.insert(
            id: id,
            characterId: characterId,
            photoPath: photoPath,
            caption: caption,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CharacterPhotosTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({characterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (characterId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.characterId,
                    referencedTable:
                        $$CharacterPhotosTableReferences._characterIdTable(db),
                    referencedColumn: $$CharacterPhotosTableReferences
                        ._characterIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CharacterPhotosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CharacterPhotosTable,
    CharacterPhoto,
    $$CharacterPhotosTableFilterComposer,
    $$CharacterPhotosTableOrderingComposer,
    $$CharacterPhotosTableAnnotationComposer,
    $$CharacterPhotosTableCreateCompanionBuilder,
    $$CharacterPhotosTableUpdateCompanionBuilder,
    (CharacterPhoto, $$CharacterPhotosTableReferences),
    CharacterPhoto,
    PrefetchHooks Function({bool characterId})>;
typedef $$ThreadsTableCreateCompanionBuilder = ThreadsCompanion Function({
  required String id,
  required String title,
  Value<int?> lastMessageId,
  Value<bool> isLocked,
  Value<bool> isTyping,
  Value<bool> isSecret,
  Value<int> unreadCount,
  required String participants,
  Value<int> rowid,
});
typedef $$ThreadsTableUpdateCompanionBuilder = ThreadsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<int?> lastMessageId,
  Value<bool> isLocked,
  Value<bool> isTyping,
  Value<bool> isSecret,
  Value<int> unreadCount,
  Value<String> participants,
  Value<int> rowid,
});

final class $$ThreadsTableReferences
    extends BaseReferences<_$AppDatabase, $ThreadsTable, Thread> {
  $$ThreadsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ThreadMembersTable, List<ThreadMember>>
      _threadMembersRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.threadMembers,
              aliasName: $_aliasNameGenerator(
                  db.threads.id, db.threadMembers.threadId));

  $$ThreadMembersTableProcessedTableManager get threadMembersRefs {
    final manager = $$ThreadMembersTableTableManager($_db, $_db.threadMembers)
        .filter((f) => f.threadId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_threadMembersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$MessagesTable, List<Message>> _messagesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.messages,
          aliasName: $_aliasNameGenerator(db.threads.id, db.messages.threadId));

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager($_db, $_db.messages)
        .filter((f) => f.threadId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ThreadsTableFilterComposer
    extends Composer<_$AppDatabase, $ThreadsTable> {
  $$ThreadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastMessageId => $composableBuilder(
      column: $table.lastMessageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isLocked => $composableBuilder(
      column: $table.isLocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isTyping => $composableBuilder(
      column: $table.isTyping, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSecret => $composableBuilder(
      column: $table.isSecret, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unreadCount => $composableBuilder(
      column: $table.unreadCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get participants => $composableBuilder(
      column: $table.participants, builder: (column) => ColumnFilters(column));

  Expression<bool> threadMembersRefs(
      Expression<bool> Function($$ThreadMembersTableFilterComposer f) f) {
    final $$ThreadMembersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.threadMembers,
        getReferencedColumn: (t) => t.threadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ThreadMembersTableFilterComposer(
              $db: $db,
              $table: $db.threadMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> messagesRefs(
      Expression<bool> Function($$MessagesTableFilterComposer f) f) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.threadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableFilterComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ThreadsTableOrderingComposer
    extends Composer<_$AppDatabase, $ThreadsTable> {
  $$ThreadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastMessageId => $composableBuilder(
      column: $table.lastMessageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isLocked => $composableBuilder(
      column: $table.isLocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isTyping => $composableBuilder(
      column: $table.isTyping, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSecret => $composableBuilder(
      column: $table.isSecret, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unreadCount => $composableBuilder(
      column: $table.unreadCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get participants => $composableBuilder(
      column: $table.participants,
      builder: (column) => ColumnOrderings(column));
}

class $$ThreadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ThreadsTable> {
  $$ThreadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get lastMessageId => $composableBuilder(
      column: $table.lastMessageId, builder: (column) => column);

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<bool> get isTyping =>
      $composableBuilder(column: $table.isTyping, builder: (column) => column);

  GeneratedColumn<bool> get isSecret =>
      $composableBuilder(column: $table.isSecret, builder: (column) => column);

  GeneratedColumn<int> get unreadCount => $composableBuilder(
      column: $table.unreadCount, builder: (column) => column);

  GeneratedColumn<String> get participants => $composableBuilder(
      column: $table.participants, builder: (column) => column);

  Expression<T> threadMembersRefs<T extends Object>(
      Expression<T> Function($$ThreadMembersTableAnnotationComposer a) f) {
    final $$ThreadMembersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.threadMembers,
        getReferencedColumn: (t) => t.threadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ThreadMembersTableAnnotationComposer(
              $db: $db,
              $table: $db.threadMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> messagesRefs<T extends Object>(
      Expression<T> Function($$MessagesTableAnnotationComposer a) f) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.threadId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ThreadsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ThreadsTable,
    Thread,
    $$ThreadsTableFilterComposer,
    $$ThreadsTableOrderingComposer,
    $$ThreadsTableAnnotationComposer,
    $$ThreadsTableCreateCompanionBuilder,
    $$ThreadsTableUpdateCompanionBuilder,
    (Thread, $$ThreadsTableReferences),
    Thread,
    PrefetchHooks Function({bool threadMembersRefs, bool messagesRefs})> {
  $$ThreadsTableTableManager(_$AppDatabase db, $ThreadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ThreadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ThreadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ThreadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int?> lastMessageId = const Value.absent(),
            Value<bool> isLocked = const Value.absent(),
            Value<bool> isTyping = const Value.absent(),
            Value<bool> isSecret = const Value.absent(),
            Value<int> unreadCount = const Value.absent(),
            Value<String> participants = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ThreadsCompanion(
            id: id,
            title: title,
            lastMessageId: lastMessageId,
            isLocked: isLocked,
            isTyping: isTyping,
            isSecret: isSecret,
            unreadCount: unreadCount,
            participants: participants,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<int?> lastMessageId = const Value.absent(),
            Value<bool> isLocked = const Value.absent(),
            Value<bool> isTyping = const Value.absent(),
            Value<bool> isSecret = const Value.absent(),
            Value<int> unreadCount = const Value.absent(),
            required String participants,
            Value<int> rowid = const Value.absent(),
          }) =>
              ThreadsCompanion.insert(
            id: id,
            title: title,
            lastMessageId: lastMessageId,
            isLocked: isLocked,
            isTyping: isTyping,
            isSecret: isSecret,
            unreadCount: unreadCount,
            participants: participants,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ThreadsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {threadMembersRefs = false, messagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (threadMembersRefs) db.threadMembers,
                if (messagesRefs) db.messages
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (threadMembersRefs)
                    await $_getPrefetchedData<Thread, $ThreadsTable,
                            ThreadMember>(
                        currentTable: table,
                        referencedTable: $$ThreadsTableReferences
                            ._threadMembersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ThreadsTableReferences(db, table, p0)
                                .threadMembersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.threadId == item.id),
                        typedResults: items),
                  if (messagesRefs)
                    await $_getPrefetchedData<Thread, $ThreadsTable, Message>(
                        currentTable: table,
                        referencedTable:
                            $$ThreadsTableReferences._messagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ThreadsTableReferences(db, table, p0)
                                .messagesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.threadId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ThreadsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ThreadsTable,
    Thread,
    $$ThreadsTableFilterComposer,
    $$ThreadsTableOrderingComposer,
    $$ThreadsTableAnnotationComposer,
    $$ThreadsTableCreateCompanionBuilder,
    $$ThreadsTableUpdateCompanionBuilder,
    (Thread, $$ThreadsTableReferences),
    Thread,
    PrefetchHooks Function({bool threadMembersRefs, bool messagesRefs})>;
typedef $$ThreadMembersTableCreateCompanionBuilder = ThreadMembersCompanion
    Function({
  required String threadId,
  required String characterId,
  Value<int> rowid,
});
typedef $$ThreadMembersTableUpdateCompanionBuilder = ThreadMembersCompanion
    Function({
  Value<String> threadId,
  Value<String> characterId,
  Value<int> rowid,
});

final class $$ThreadMembersTableReferences
    extends BaseReferences<_$AppDatabase, $ThreadMembersTable, ThreadMember> {
  $$ThreadMembersTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ThreadsTable _threadIdTable(_$AppDatabase db) =>
      db.threads.createAlias(
          $_aliasNameGenerator(db.threadMembers.threadId, db.threads.id));

  $$ThreadsTableProcessedTableManager get threadId {
    final $_column = $_itemColumn<String>('thread_id')!;

    final manager = $$ThreadsTableTableManager($_db, $_db.threads)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_threadIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CharactersTable _characterIdTable(_$AppDatabase db) =>
      db.characters.createAlias(
          $_aliasNameGenerator(db.threadMembers.characterId, db.characters.id));

  $$CharactersTableProcessedTableManager get characterId {
    final $_column = $_itemColumn<String>('character_id')!;

    final manager = $$CharactersTableTableManager($_db, $_db.characters)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_characterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ThreadMembersTableFilterComposer
    extends Composer<_$AppDatabase, $ThreadMembersTable> {
  $$ThreadMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ThreadsTableFilterComposer get threadId {
    final $$ThreadsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.threadId,
        referencedTable: $db.threads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ThreadsTableFilterComposer(
              $db: $db,
              $table: $db.threads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CharactersTableFilterComposer get characterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.characterId,
        referencedTable: $db.characters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CharactersTableFilterComposer(
              $db: $db,
              $table: $db.characters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ThreadMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $ThreadMembersTable> {
  $$ThreadMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ThreadsTableOrderingComposer get threadId {
    final $$ThreadsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.threadId,
        referencedTable: $db.threads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ThreadsTableOrderingComposer(
              $db: $db,
              $table: $db.threads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CharactersTableOrderingComposer get characterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.characterId,
        referencedTable: $db.characters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CharactersTableOrderingComposer(
              $db: $db,
              $table: $db.characters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ThreadMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ThreadMembersTable> {
  $$ThreadMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ThreadsTableAnnotationComposer get threadId {
    final $$ThreadsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.threadId,
        referencedTable: $db.threads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ThreadsTableAnnotationComposer(
              $db: $db,
              $table: $db.threads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CharactersTableAnnotationComposer get characterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.characterId,
        referencedTable: $db.characters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CharactersTableAnnotationComposer(
              $db: $db,
              $table: $db.characters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ThreadMembersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ThreadMembersTable,
    ThreadMember,
    $$ThreadMembersTableFilterComposer,
    $$ThreadMembersTableOrderingComposer,
    $$ThreadMembersTableAnnotationComposer,
    $$ThreadMembersTableCreateCompanionBuilder,
    $$ThreadMembersTableUpdateCompanionBuilder,
    (ThreadMember, $$ThreadMembersTableReferences),
    ThreadMember,
    PrefetchHooks Function({bool threadId, bool characterId})> {
  $$ThreadMembersTableTableManager(_$AppDatabase db, $ThreadMembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ThreadMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ThreadMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ThreadMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> threadId = const Value.absent(),
            Value<String> characterId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ThreadMembersCompanion(
            threadId: threadId,
            characterId: characterId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String threadId,
            required String characterId,
            Value<int> rowid = const Value.absent(),
          }) =>
              ThreadMembersCompanion.insert(
            threadId: threadId,
            characterId: characterId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ThreadMembersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({threadId = false, characterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (threadId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.threadId,
                    referencedTable:
                        $$ThreadMembersTableReferences._threadIdTable(db),
                    referencedColumn:
                        $$ThreadMembersTableReferences._threadIdTable(db).id,
                  ) as T;
                }
                if (characterId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.characterId,
                    referencedTable:
                        $$ThreadMembersTableReferences._characterIdTable(db),
                    referencedColumn:
                        $$ThreadMembersTableReferences._characterIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ThreadMembersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ThreadMembersTable,
    ThreadMember,
    $$ThreadMembersTableFilterComposer,
    $$ThreadMembersTableOrderingComposer,
    $$ThreadMembersTableAnnotationComposer,
    $$ThreadMembersTableCreateCompanionBuilder,
    $$ThreadMembersTableUpdateCompanionBuilder,
    (ThreadMember, $$ThreadMembersTableReferences),
    ThreadMember,
    PrefetchHooks Function({bool threadId, bool characterId})>;
typedef $$StoryNodesTableCreateCompanionBuilder = StoryNodesCompanion Function({
  required String id,
  required String type,
  Value<String?> senderId,
  Value<String?> content,
  Value<String?> nextNodeId,
  Value<String?> metadata,
  Value<int> rowid,
});
typedef $$StoryNodesTableUpdateCompanionBuilder = StoryNodesCompanion Function({
  Value<String> id,
  Value<String> type,
  Value<String?> senderId,
  Value<String?> content,
  Value<String?> nextNodeId,
  Value<String?> metadata,
  Value<int> rowid,
});

final class $$StoryNodesTableReferences
    extends BaseReferences<_$AppDatabase, $StoryNodesTable, StoryNode> {
  $$StoryNodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CharactersTable _senderIdTable(_$AppDatabase db) =>
      db.characters.createAlias(
          $_aliasNameGenerator(db.storyNodes.senderId, db.characters.id));

  $$CharactersTableProcessedTableManager? get senderId {
    final $_column = $_itemColumn<String>('sender_id');
    if ($_column == null) return null;
    final manager = $$CharactersTableTableManager($_db, $_db.characters)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_senderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$MessagesTable, List<Message>> _messagesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.messages,
          aliasName:
              $_aliasNameGenerator(db.storyNodes.id, db.messages.nodeId));

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager($_db, $_db.messages)
        .filter((f) => f.nodeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$StoryNodesTableFilterComposer
    extends Composer<_$AppDatabase, $StoryNodesTable> {
  $$StoryNodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nextNodeId => $composableBuilder(
      column: $table.nextNodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  $$CharactersTableFilterComposer get senderId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.senderId,
        referencedTable: $db.characters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CharactersTableFilterComposer(
              $db: $db,
              $table: $db.characters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> messagesRefs(
      Expression<bool> Function($$MessagesTableFilterComposer f) f) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.nodeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableFilterComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$StoryNodesTableOrderingComposer
    extends Composer<_$AppDatabase, $StoryNodesTable> {
  $$StoryNodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nextNodeId => $composableBuilder(
      column: $table.nextNodeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  $$CharactersTableOrderingComposer get senderId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.senderId,
        referencedTable: $db.characters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CharactersTableOrderingComposer(
              $db: $db,
              $table: $db.characters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StoryNodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoryNodesTable> {
  $$StoryNodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get nextNodeId => $composableBuilder(
      column: $table.nextNodeId, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  $$CharactersTableAnnotationComposer get senderId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.senderId,
        referencedTable: $db.characters,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CharactersTableAnnotationComposer(
              $db: $db,
              $table: $db.characters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> messagesRefs<T extends Object>(
      Expression<T> Function($$MessagesTableAnnotationComposer a) f) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.nodeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$StoryNodesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StoryNodesTable,
    StoryNode,
    $$StoryNodesTableFilterComposer,
    $$StoryNodesTableOrderingComposer,
    $$StoryNodesTableAnnotationComposer,
    $$StoryNodesTableCreateCompanionBuilder,
    $$StoryNodesTableUpdateCompanionBuilder,
    (StoryNode, $$StoryNodesTableReferences),
    StoryNode,
    PrefetchHooks Function({bool senderId, bool messagesRefs})> {
  $$StoryNodesTableTableManager(_$AppDatabase db, $StoryNodesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoryNodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoryNodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoryNodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> senderId = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<String?> nextNodeId = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoryNodesCompanion(
            id: id,
            type: type,
            senderId: senderId,
            content: content,
            nextNodeId: nextNodeId,
            metadata: metadata,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String type,
            Value<String?> senderId = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<String?> nextNodeId = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoryNodesCompanion.insert(
            id: id,
            type: type,
            senderId: senderId,
            content: content,
            nextNodeId: nextNodeId,
            metadata: metadata,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StoryNodesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({senderId = false, messagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (messagesRefs) db.messages],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (senderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.senderId,
                    referencedTable:
                        $$StoryNodesTableReferences._senderIdTable(db),
                    referencedColumn:
                        $$StoryNodesTableReferences._senderIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (messagesRefs)
                    await $_getPrefetchedData<StoryNode, $StoryNodesTable,
                            Message>(
                        currentTable: table,
                        referencedTable:
                            $$StoryNodesTableReferences._messagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$StoryNodesTableReferences(db, table, p0)
                                .messagesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.nodeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$StoryNodesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StoryNodesTable,
    StoryNode,
    $$StoryNodesTableFilterComposer,
    $$StoryNodesTableOrderingComposer,
    $$StoryNodesTableAnnotationComposer,
    $$StoryNodesTableCreateCompanionBuilder,
    $$StoryNodesTableUpdateCompanionBuilder,
    (StoryNode, $$StoryNodesTableReferences),
    StoryNode,
    PrefetchHooks Function({bool senderId, bool messagesRefs})>;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  Value<int> id,
  Value<String?> nodeId,
  required String threadId,
  required String senderId,
  Value<String?> content,
  Value<String> type,
  Value<String?> mediaPath,
  required int sequence,
  Value<DateTime> timestamp,
  Value<bool> isPlayerMessage,
  Value<bool> isSecret,
  Value<bool> isRead,
  Value<String?> meta,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<int> id,
  Value<String?> nodeId,
  Value<String> threadId,
  Value<String> senderId,
  Value<String?> content,
  Value<String> type,
  Value<String?> mediaPath,
  Value<int> sequence,
  Value<DateTime> timestamp,
  Value<bool> isPlayerMessage,
  Value<bool> isSecret,
  Value<bool> isRead,
  Value<String?> meta,
});

final class $$MessagesTableReferences
    extends BaseReferences<_$AppDatabase, $MessagesTable, Message> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StoryNodesTable _nodeIdTable(_$AppDatabase db) => db.storyNodes
      .createAlias($_aliasNameGenerator(db.messages.nodeId, db.storyNodes.id));

  $$StoryNodesTableProcessedTableManager? get nodeId {
    final $_column = $_itemColumn<String>('node_id');
    if ($_column == null) return null;
    final manager = $$StoryNodesTableTableManager($_db, $_db.storyNodes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ThreadsTable _threadIdTable(_$AppDatabase db) => db.threads
      .createAlias($_aliasNameGenerator(db.messages.threadId, db.threads.id));

  $$ThreadsTableProcessedTableManager get threadId {
    final $_column = $_itemColumn<String>('thread_id')!;

    final manager = $$ThreadsTableTableManager($_db, $_db.threads)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_threadIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get senderId => $composableBuilder(
      column: $table.senderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaPath => $composableBuilder(
      column: $table.mediaPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPlayerMessage => $composableBuilder(
      column: $table.isPlayerMessage,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSecret => $composableBuilder(
      column: $table.isSecret, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meta => $composableBuilder(
      column: $table.meta, builder: (column) => ColumnFilters(column));

  $$StoryNodesTableFilterComposer get nodeId {
    final $$StoryNodesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.nodeId,
        referencedTable: $db.storyNodes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoryNodesTableFilterComposer(
              $db: $db,
              $table: $db.storyNodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ThreadsTableFilterComposer get threadId {
    final $$ThreadsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.threadId,
        referencedTable: $db.threads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ThreadsTableFilterComposer(
              $db: $db,
              $table: $db.threads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderId => $composableBuilder(
      column: $table.senderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaPath => $composableBuilder(
      column: $table.mediaPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPlayerMessage => $composableBuilder(
      column: $table.isPlayerMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSecret => $composableBuilder(
      column: $table.isSecret, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meta => $composableBuilder(
      column: $table.meta, builder: (column) => ColumnOrderings(column));

  $$StoryNodesTableOrderingComposer get nodeId {
    final $$StoryNodesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.nodeId,
        referencedTable: $db.storyNodes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoryNodesTableOrderingComposer(
              $db: $db,
              $table: $db.storyNodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ThreadsTableOrderingComposer get threadId {
    final $$ThreadsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.threadId,
        referencedTable: $db.threads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ThreadsTableOrderingComposer(
              $db: $db,
              $table: $db.threads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get mediaPath =>
      $composableBuilder(column: $table.mediaPath, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isPlayerMessage => $composableBuilder(
      column: $table.isPlayerMessage, builder: (column) => column);

  GeneratedColumn<bool> get isSecret =>
      $composableBuilder(column: $table.isSecret, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<String> get meta =>
      $composableBuilder(column: $table.meta, builder: (column) => column);

  $$StoryNodesTableAnnotationComposer get nodeId {
    final $$StoryNodesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.nodeId,
        referencedTable: $db.storyNodes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StoryNodesTableAnnotationComposer(
              $db: $db,
              $table: $db.storyNodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ThreadsTableAnnotationComposer get threadId {
    final $$ThreadsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.threadId,
        referencedTable: $db.threads,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ThreadsTableAnnotationComposer(
              $db: $db,
              $table: $db.threads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, $$MessagesTableReferences),
    Message,
    PrefetchHooks Function({bool nodeId, bool threadId})> {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> nodeId = const Value.absent(),
            Value<String> threadId = const Value.absent(),
            Value<String> senderId = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> mediaPath = const Value.absent(),
            Value<int> sequence = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<bool> isPlayerMessage = const Value.absent(),
            Value<bool> isSecret = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<String?> meta = const Value.absent(),
          }) =>
              MessagesCompanion(
            id: id,
            nodeId: nodeId,
            threadId: threadId,
            senderId: senderId,
            content: content,
            type: type,
            mediaPath: mediaPath,
            sequence: sequence,
            timestamp: timestamp,
            isPlayerMessage: isPlayerMessage,
            isSecret: isSecret,
            isRead: isRead,
            meta: meta,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> nodeId = const Value.absent(),
            required String threadId,
            required String senderId,
            Value<String?> content = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> mediaPath = const Value.absent(),
            required int sequence,
            Value<DateTime> timestamp = const Value.absent(),
            Value<bool> isPlayerMessage = const Value.absent(),
            Value<bool> isSecret = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<String?> meta = const Value.absent(),
          }) =>
              MessagesCompanion.insert(
            id: id,
            nodeId: nodeId,
            threadId: threadId,
            senderId: senderId,
            content: content,
            type: type,
            mediaPath: mediaPath,
            sequence: sequence,
            timestamp: timestamp,
            isPlayerMessage: isPlayerMessage,
            isSecret: isSecret,
            isRead: isRead,
            meta: meta,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$MessagesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({nodeId = false, threadId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (nodeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.nodeId,
                    referencedTable: $$MessagesTableReferences._nodeIdTable(db),
                    referencedColumn:
                        $$MessagesTableReferences._nodeIdTable(db).id,
                  ) as T;
                }
                if (threadId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.threadId,
                    referencedTable:
                        $$MessagesTableReferences._threadIdTable(db),
                    referencedColumn:
                        $$MessagesTableReferences._threadIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, $$MessagesTableReferences),
    Message,
    PrefetchHooks Function({bool nodeId, bool threadId})>;
typedef $$NotificationsTableCreateCompanionBuilder = NotificationsCompanion
    Function({
  required String id,
  required String type,
  required String title,
  required String message,
  required int createdAtMinutes,
  Value<String?> payload,
  Value<bool> isRead,
  Value<int> rowid,
});
typedef $$NotificationsTableUpdateCompanionBuilder = NotificationsCompanion
    Function({
  Value<String> id,
  Value<String> type,
  Value<String> title,
  Value<String> message,
  Value<int> createdAtMinutes,
  Value<String?> payload,
  Value<bool> isRead,
  Value<int> rowid,
});

class $$NotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAtMinutes => $composableBuilder(
      column: $table.createdAtMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));
}

class $$NotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAtMinutes => $composableBuilder(
      column: $table.createdAtMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));
}

class $$NotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get createdAtMinutes => $composableBuilder(
      column: $table.createdAtMinutes, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);
}

class $$NotificationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotificationsTable,
    Notification,
    $$NotificationsTableFilterComposer,
    $$NotificationsTableOrderingComposer,
    $$NotificationsTableAnnotationComposer,
    $$NotificationsTableCreateCompanionBuilder,
    $$NotificationsTableUpdateCompanionBuilder,
    (
      Notification,
      BaseReferences<_$AppDatabase, $NotificationsTable, Notification>
    ),
    Notification,
    PrefetchHooks Function()> {
  $$NotificationsTableTableManager(_$AppDatabase db, $NotificationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> message = const Value.absent(),
            Value<int> createdAtMinutes = const Value.absent(),
            Value<String?> payload = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotificationsCompanion(
            id: id,
            type: type,
            title: title,
            message: message,
            createdAtMinutes: createdAtMinutes,
            payload: payload,
            isRead: isRead,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String type,
            required String title,
            required String message,
            required int createdAtMinutes,
            Value<String?> payload = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotificationsCompanion.insert(
            id: id,
            type: type,
            title: title,
            message: message,
            createdAtMinutes: createdAtMinutes,
            payload: payload,
            isRead: isRead,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NotificationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotificationsTable,
    Notification,
    $$NotificationsTableFilterComposer,
    $$NotificationsTableOrderingComposer,
    $$NotificationsTableAnnotationComposer,
    $$NotificationsTableCreateCompanionBuilder,
    $$NotificationsTableUpdateCompanionBuilder,
    (
      Notification,
      BaseReferences<_$AppDatabase, $NotificationsTable, Notification>
    ),
    Notification,
    PrefetchHooks Function()>;
typedef $$StoryStateTableCreateCompanionBuilder = StoryStateCompanion Function({
  required String key,
  Value<bool> value,
  Value<int> intValue,
  Value<String?> stringValue,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$StoryStateTableUpdateCompanionBuilder = StoryStateCompanion Function({
  Value<String> key,
  Value<bool> value,
  Value<int> intValue,
  Value<String?> stringValue,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$StoryStateTableFilterComposer
    extends Composer<_$AppDatabase, $StoryStateTable> {
  $$StoryStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get intValue => $composableBuilder(
      column: $table.intValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stringValue => $composableBuilder(
      column: $table.stringValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$StoryStateTableOrderingComposer
    extends Composer<_$AppDatabase, $StoryStateTable> {
  $$StoryStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get intValue => $composableBuilder(
      column: $table.intValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stringValue => $composableBuilder(
      column: $table.stringValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$StoryStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoryStateTable> {
  $$StoryStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<bool> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get intValue =>
      $composableBuilder(column: $table.intValue, builder: (column) => column);

  GeneratedColumn<String> get stringValue => $composableBuilder(
      column: $table.stringValue, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StoryStateTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StoryStateTable,
    StoryStateData,
    $$StoryStateTableFilterComposer,
    $$StoryStateTableOrderingComposer,
    $$StoryStateTableAnnotationComposer,
    $$StoryStateTableCreateCompanionBuilder,
    $$StoryStateTableUpdateCompanionBuilder,
    (
      StoryStateData,
      BaseReferences<_$AppDatabase, $StoryStateTable, StoryStateData>
    ),
    StoryStateData,
    PrefetchHooks Function()> {
  $$StoryStateTableTableManager(_$AppDatabase db, $StoryStateTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoryStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoryStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoryStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<bool> value = const Value.absent(),
            Value<int> intValue = const Value.absent(),
            Value<String?> stringValue = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoryStateCompanion(
            key: key,
            value: value,
            intValue: intValue,
            stringValue: stringValue,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<bool> value = const Value.absent(),
            Value<int> intValue = const Value.absent(),
            Value<String?> stringValue = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoryStateCompanion.insert(
            key: key,
            value: value,
            intValue: intValue,
            stringValue: stringValue,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StoryStateTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StoryStateTable,
    StoryStateData,
    $$StoryStateTableFilterComposer,
    $$StoryStateTableOrderingComposer,
    $$StoryStateTableAnnotationComposer,
    $$StoryStateTableCreateCompanionBuilder,
    $$StoryStateTableUpdateCompanionBuilder,
    (
      StoryStateData,
      BaseReferences<_$AppDatabase, $StoryStateTable, StoryStateData>
    ),
    StoryStateData,
    PrefetchHooks Function()>;
typedef $$EpisodesTableCreateCompanionBuilder = EpisodesCompanion Function({
  required String id,
  Value<bool> isUnlocked,
  Value<int> progress,
  Value<int> version,
  Value<int> rowid,
});
typedef $$EpisodesTableUpdateCompanionBuilder = EpisodesCompanion Function({
  Value<String> id,
  Value<bool> isUnlocked,
  Value<int> progress,
  Value<int> version,
  Value<int> rowid,
});

class $$EpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isUnlocked => $composableBuilder(
      column: $table.isUnlocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));
}

class $$EpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isUnlocked => $composableBuilder(
      column: $table.isUnlocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));
}

class $$EpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isUnlocked => $composableBuilder(
      column: $table.isUnlocked, builder: (column) => column);

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$EpisodesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EpisodesTable,
    Episode,
    $$EpisodesTableFilterComposer,
    $$EpisodesTableOrderingComposer,
    $$EpisodesTableAnnotationComposer,
    $$EpisodesTableCreateCompanionBuilder,
    $$EpisodesTableUpdateCompanionBuilder,
    (Episode, BaseReferences<_$AppDatabase, $EpisodesTable, Episode>),
    Episode,
    PrefetchHooks Function()> {
  $$EpisodesTableTableManager(_$AppDatabase db, $EpisodesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<bool> isUnlocked = const Value.absent(),
            Value<int> progress = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EpisodesCompanion(
            id: id,
            isUnlocked: isUnlocked,
            progress: progress,
            version: version,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<bool> isUnlocked = const Value.absent(),
            Value<int> progress = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EpisodesCompanion.insert(
            id: id,
            isUnlocked: isUnlocked,
            progress: progress,
            version: version,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EpisodesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EpisodesTable,
    Episode,
    $$EpisodesTableFilterComposer,
    $$EpisodesTableOrderingComposer,
    $$EpisodesTableAnnotationComposer,
    $$EpisodesTableCreateCompanionBuilder,
    $$EpisodesTableUpdateCompanionBuilder,
    (Episode, BaseReferences<_$AppDatabase, $EpisodesTable, Episode>),
    Episode,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db, _db.players);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db, _db.characters);
  $$CharacterPhotosTableTableManager get characterPhotos =>
      $$CharacterPhotosTableTableManager(_db, _db.characterPhotos);
  $$ThreadsTableTableManager get threads =>
      $$ThreadsTableTableManager(_db, _db.threads);
  $$ThreadMembersTableTableManager get threadMembers =>
      $$ThreadMembersTableTableManager(_db, _db.threadMembers);
  $$StoryNodesTableTableManager get storyNodes =>
      $$StoryNodesTableTableManager(_db, _db.storyNodes);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$NotificationsTableTableManager get notifications =>
      $$NotificationsTableTableManager(_db, _db.notifications);
  $$StoryStateTableTableManager get storyState =>
      $$StoryStateTableTableManager(_db, _db.storyState);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db, _db.episodes);
}
