import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../persistence/drift_database.dart';
import 'game_state.dart';

class CharacterProfile {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? avatar;
  final String? headerImage;
  final List<CharacterPhoto> gallery;
  final String? bio;
  final Map<String, String> info;
  final List<String> notes; // ← plain strings, from CharacterNotes table
  final String? gameNumber;

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
    this.gameNumber,
  });
}

/// StreamProvider so profile rebuilds automatically whenever
/// the character row, gallery, or notes change.
final characterProvider =
    StreamProvider.family<CharacterProfile?, String>(
        (ref, characterId) async* {
  final db = ref.watch(databaseProvider);

  // Watch the character row — re-emits on any insert/update/delete
  final charStream = (db.select(db.characters)
        ..where((c) => c.id.equals(characterId)))
      .watchSingleOrNull();

  await for (final charRow in charStream) {
    if (charRow == null) {
      yield null;
      continue;
    }

    // Gallery photos
    final photos = await db.getCharacterGallery(characterId);

    // FIX: fetch notes from CharacterNotes table.
    // Previously characterProvider only read investigationNotes from
    // the Characters row (a single text column). Notes saved via the
    // bottom sheet write to the CharacterNotes table, which was never
    // queried here — so saved notes never appeared on the profile.
    final noteRows = await db.getCharacterNotes(characterId);
    final noteTexts = noteRows
        .map((n) => n.noteText.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final info = <String, String>{
      if (charRow.id == 'michael') 'Occupation': 'Journalist',
      'Status': 'Active',
    };

    yield CharacterProfile(
      id:          charRow.id,
      name:        charRow.name,
      phoneNumber: charRow.phoneNumber,
      avatar:      charRow.avatarPath,
      headerImage: charRow.id == 'player'
          ? 'assets/headers/default_header.jpg'
          : 'assets/characters/${charRow.id}/header.jpg',
      gallery:     photos,
      bio:         charRow.bio,
      info:        info,
      notes:       noteTexts,  // ← from CharacterNotes, not Characters.investigationNotes
    );
  }
});

/// All discovered characters (Contacts App).
final charactersProvider =
    StreamProvider<List<CharacterProfile>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final charRowsStream = db.select(db.characters).watch();

  await for (final rows in charRowsStream) {
    final profiles = <CharacterProfile>[];

    for (final row in rows) {
      if (row.id == 'system') continue;
      final photos = await db.getCharacterGallery(row.id);
      final noteRows = await db.getCharacterNotes(row.id);
      final notes = noteRows
          .map((n) => n.noteText.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      profiles.add(CharacterProfile(
        id:          row.id,
        name:        row.name,
        phoneNumber: row.phoneNumber,
        avatar:      row.avatarPath,
        headerImage: row.id == 'player'
            ? 'assets/headers/default_header.jpg'
            : 'assets/characters/${row.id}/header.jpg',
        gallery:     photos,
        bio:         row.bio,
        info:        {},
        notes:       notes,
      ));
    }

    profiles.sort((a, b) => a.name.compareTo(b.name));
    yield profiles;
  }
});
