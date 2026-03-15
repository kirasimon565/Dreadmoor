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

// FIX: was FutureProvider — ran once, cached null forever if the row didn't
// exist at that exact millisecond, and NEVER retried.
// Now StreamProvider using watchSingleOrNull(). Re-emits the moment
// _ensurePlayerCharacter() or seedCharacters() inserts/updates the row.
final characterProvider =
    StreamProvider.family<CharacterProfile?, String>((ref, characterId) async* {
  final db = ref.watch(databaseProvider);

  final charStream = (db.select(db.characters)
        ..where((c) => c.id.equals(characterId)))
      .watchSingleOrNull();

  await for (final charRow in charStream) {
    if (charRow == null) {
      yield null;
      continue;
    }

    final photos = await db.getCharacterGallery(characterId);

    final info = <String, String>{
      if (charRow.id == 'michael') 'Occupation': 'Journalist',
      'Status': 'Active',
    };

    final notes = <String>[
      if (charRow.investigationNotes != null &&
          charRow.investigationNotes!.isNotEmpty)
        charRow.investigationNotes!
      else
        'No notes collected yet.',
    ];

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
      notes:       notes,
    );
  }
});

final charactersProvider =
    StreamProvider<List<CharacterProfile>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final charRowsStream = db.select(db.characters).watch();

  await for (final rows in charRowsStream) {
    final profiles = <CharacterProfile>[];

    for (final row in rows) {
      if (row.id == 'system') continue;
      final photos = await db.getCharacterGallery(row.id);
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
        notes:       [row.investigationNotes ?? 'No notes collected yet.'],
      ));
    }

    profiles.sort((a, b) => a.name.compareTo(b.name));
    yield profiles;
  }
});
