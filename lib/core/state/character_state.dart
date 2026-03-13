import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../persistence/drift_database.dart';
import 'game_state.dart';

/// ------------------------------------------------------------
/// CHARACTER PROFILE MODEL
/// Refactored to map directly from our Relational Database
/// ------------------------------------------------------------
class CharacterProfile {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? avatar;
  final String? headerImage;
  final List<CharacterPhoto> gallery; // Real photos from DB
  final String? bio;
  final Map<String, String> info; // Dynamic metadata
  final List<String> notes;

  const CharacterProfile({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.avatar,
    this.headerImage,
    required this.gallery,
    this.bio,
    required this.info,
    required this.notes,
  });
}

/// ------------------------------------------------------------
/// SINGLE CHARACTER PROVIDER (REACTIVE)
/// ------------------------------------------------------------
final characterProvider = FutureProvider.family<CharacterProfile?, String>((
  ref,
  characterId,
) async {
  final db = ref.watch(databaseProvider);

  // 1. Fetch character core data
  final charRow = await (db.select(db.characters)
        ..where((c) => c.id.equals(characterId)))
      .getSingleOrNull();

  if (charRow == null) return null;

  // 2. Fetch all gallery photos from our new table
  final photos = await db.getCharacterGallery(characterId);

  // 3. Parse dynamic info from the DB strings
  // We can expand this logic as the investigation deepens
  final info = <String, String>{
    "Occupation": charRow.id == 'michael' ? "Journalist" : "Unknown",
    "Status": "Active",
    "Clearance": "Level 4", // Matching your Natalie screenshot
  };

  final notes = <String>[
    charRow.investigationNotes ?? "No notes collected yet."
  ];

  return CharacterProfile(
    id: charRow.id,
    name: charRow.name,
    phoneNumber: charRow.phoneNumber,
    avatar: charRow.avatarPath,
    headerImage: "assets/characters/${charRow.id}/header.jpg", // Themed header
    gallery: photos,
    bio: charRow.bio,
    info: info,
    notes: notes,
  );
});

/// ------------------------------------------------------------
/// ALL DISCOVERED CHARACTERS (Used for Contacts App)
/// ------------------------------------------------------------
final charactersProvider = FutureProvider<List<CharacterProfile>>((ref) async {
  final db = ref.watch(databaseProvider);

  // Fetch all characters who are actually in our database
  final charRows = await db.select(db.characters).get();

  final profiles = <CharacterProfile>[];

  for (final row in charRows) {
    // We skip the 'system' character from the contact list
    if (row.id == 'system') continue;

    final profile = await ref.read(characterProvider(row.id).future);
    if (profile != null) {
      profiles.add(profile);
    }
  }

  // Sort by name for the Contacts App
  profiles.sort((a, b) => a.name.compareTo(b.name));
  
  return profiles;
});
