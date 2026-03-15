import 'package:drift/drift.dart';
import 'drift_database.dart';

// FIX: was insertOrReplace — ran on every processNode() call and wiped
// the 'player' row each time (setting avatarPath back to null).
// Now insertOrIgnore: existing rows are NEVER touched.
Future<void> seedCharacters(AppDatabase db) async {
  final characters = [
    CharactersCompanion.insert(id: 'unknown', name: 'Unknown', phoneNumber: 'private/hidden',
      avatarPath: const Value('assets/characters/unknown.png'),
      bio: const Value('I see more than you think.'), colorHex: const Value('#746fbc')),
    CharactersCompanion.insert(id: 'amelia', name: 'Amelia Stone', phoneNumber: '+1 251 396',
      avatarPath: const Value('assets/characters/amelia.png'),
      bio: const Value("Working late again at Joy's Diner."), colorHex: const Value('#08025c')),
    CharactersCompanion.insert(id: 'chris', name: 'Chris Brown', phoneNumber: '+1 978 726',
      avatarPath: const Value('assets/characters/chris.png'),
      bio: const Value('Night shifts and bad coffee.'), colorHex: const Value('#becc00')),
    CharactersCompanion.insert(id: 'abigail', name: 'Abigail Ronalds', phoneNumber: '+1 466 098',
      avatarPath: const Value('assets/characters/abigail.png'),
      bio: const Value('If you know, you know.'), colorHex: const Value('#00290a')),
    CharactersCompanion.insert(id: 'michael', name: 'Michael Jones', phoneNumber: '+1 689 140',
      avatarPath: const Value('assets/characters/michael.png'),
      bio: const Value('Reporter at Dreadmoor Daily.'), colorHex: const Value('#9b0000')),
    CharactersCompanion.insert(id: 'system', name: 'System', phoneNumber: '0000',
      avatarPath: const Value(null), bio: const Value('System notifications'),
      colorHex: const Value('#FFFFFF')),
    CharactersCompanion.insert(id: 'player', name: 'Investigator', phoneNumber: 'Me',
      avatarPath: const Value('assets/characters/player_default.png'),
      bio: const Value('My internal notes and findings.'), colorHex: const Value('#4A9EBF')),
  ];

  final galleryPhotos = [
    CharacterPhotosCompanion.insert(characterId: 'amelia',
      photoPath: 'assets/characters/amelia/gallery_1.png', caption: const Value('At the diner.')),
    CharacterPhotosCompanion.insert(characterId: 'amelia',
      photoPath: 'assets/characters/amelia/gallery_2.png', caption: const Value('Selfie.')),
    CharacterPhotosCompanion.insert(characterId: 'michael',
      photoPath: 'assets/characters/michael/work_desk.png', caption: const Value('Dreadmoor Daily office.')),
    CharacterPhotosCompanion.insert(characterId: 'chris',
      photoPath: 'assets/characters/chris/gallery_1.png', caption: const Value("Joy's Diner")),
    CharacterPhotosCompanion.insert(characterId: 'abigail',
      photoPath: 'assets/characters/abigail/gallery_1.png', caption: const Value('bestie...')),
  ];

  await db.batch((batch) {
    batch.insertAll(db.characters,     characters,    mode: InsertMode.insertOrIgnore);
    batch.insertAll(db.characterPhotos, galleryPhotos, mode: InsertMode.insertOrIgnore);
  });
}
