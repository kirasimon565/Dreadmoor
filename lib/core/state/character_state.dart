import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/drift_database.dart';
import 'game_state.dart';

class CharacterProfile {
  final String id;
  final String name;
  final String? phoneNumber;

  final String avatar;
  final String headerImage;

  final List<String> photos;

  final String? bio;

  final Map<String, String> info;

  final List<String> notes;

  const CharacterProfile({
    required this.id,
    required this.name,
    this.phoneNumber,
    required this.avatar,
    required this.headerImage,
    required this.photos,
    this.bio,
    required this.info,
    required this.notes,
  });
}

/// ------------------------------------------------------------
/// CHARACTER PROFILE PROVIDER
/// ------------------------------------------------------------

final characterProvider = FutureProvider.family<CharacterProfile?, String>((
  ref,
  characterId,
) async {
  final db = ref.watch(databaseProvider);

  final thread = await (db.select(
    db.threads,
  )..where((t) => t.id.equals(characterId))).getSingleOrNull();

  if (thread == null) return null;

  return _mapThreadToProfile(thread);
});

/// ------------------------------------------------------------
/// ALL CHARACTERS
/// ------------------------------------------------------------

final charactersProvider = FutureProvider<List<CharacterProfile>>((ref) async {
  final db = ref.watch(databaseProvider);

  final threads = await db.select(db.threads).get();

  return threads.map(_mapThreadToProfile).toList();
});

/// ------------------------------------------------------------
/// HELPERS
/// ------------------------------------------------------------

CharacterProfile _mapThreadToProfile(Thread thread) {
  final characterId = thread.id;

  /// Participants list stored as CSV
  final participants = thread.participants.split(',');

  final name = participants.isNotEmpty ? participants.first : characterId;

  /// Default assets (can be replaced later with DB-driven values)
  final avatar = "assets/characters/$characterId/avatar.png";
  final header = "assets/characters/$characterId/header.jpg";

  /// Placeholder dynamic content
  /// Later these can come from JSON / DB
  final photos = <String>[
    "assets/characters/$characterId/p1.jpg",
    "assets/characters/$characterId/p2.jpg",
    "assets/characters/$characterId/p3.jpg",
    "assets/characters/$characterId/p4.jpg",
    "assets/characters/$characterId/p5.jpg",
    "assets/characters/$characterId/p6.jpg",
  ];

  final info = <String, String>{
    "Occupation": "Unknown",
    "Location": "Dreadmoor",
  };

  final notes = <String>["Profile discovered during investigation."];

  return CharacterProfile(
    id: characterId,
    name: name,
    phoneNumber: null,
    avatar: avatar,
    headerImage: header,
    photos: photos,
    bio: null,
    info: info,
    notes: notes,
  );
});

/// ------------------------------------------------------------
/// ALL CHARACTERS
/// ------------------------------------------------------------

final charactersProvider = FutureProvider<List<CharacterProfile>>((ref) async {
  final db = ref.watch(databaseProvider);

  final threads = await db.select(db.threads).get();

  final profiles = <CharacterProfile>[];

  for (final thread in threads) {
    final character = await ref.read(characterProvider(thread.id).future);

    if (character != null) {
      profiles.add(character);
    }
  }

  return profiles;
});
}
