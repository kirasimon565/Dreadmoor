import 'package:drift/drift.dart';
import 'drift_database.dart';

Future<void> seedCharacters(AppDatabase db) async {
  // 1. Define Character Profiles
  final characters = [
    CharactersCompanion.insert(
      id: 'unknown',
      name: 'Unknown',
      phoneNumber: 'private/hidden',
      avatarPath: const Value('assets/characters/unknown.png'),
      bio: const Value("I see more than you think."),
      colorHex: const Value('#746fbc'),
    ),
    CharactersCompanion.insert(
      id: 'amelia',
      name: 'Amelia Stone',
      phoneNumber: '+1 251 396',
      avatarPath: const Value('assets/characters/amelia.png'),
      bio: const Value("Working late again at Joy's Dinner."),
      colorHex: const Value('#08025c'),
    ),
    CharactersCompanion.insert(
      id: 'chris',
      name: 'Chris Brown',
      phoneNumber: '+1 978 726',
      avatarPath: const Value('assets/characters/chris.png'),
      bio: const Value("Night shifts and bad coffee."),
      colorHex: const Value('#becc00'),
    ),
    CharactersCompanion.insert(
      id: 'abigail',
      name: 'Abigail Ronalds',
      phoneNumber: '+1 466 098',
      avatarPath: const Value('assets/characters/abigail.png'),
      bio: const Value("If you know, you know."),
      colorHex: const Value('#00290a'),
    ),
    CharactersCompanion.insert(
      id: 'michael',
      name: 'Michael Jones',
      phoneNumber: '+1 689 140',
      avatarPath: const Value('assets/characters/michael.png'),
      bio: const Value("Reporter at Dreadmoor Daily."),
      colorHex: const Value('#9b0000'),
    ),
    CharactersCompanion.insert(
      id: 'system',
      name: 'System',
      phoneNumber: '0000',
      avatarPath: const Value(null),
      bio: const Value("System notifications"),
      colorHex: const Value('#FFFFFF'),
    ),
  ];

  // 2. Define Character Gallery Photos
  final galleryPhotos = [
    // Photos for Amelia
    CharacterPhotosCompanion.insert(
      characterId: 'amelia',
      photoPath: 'assets/characters/amelia/gallery_1.png',
      caption: const Value('At the diner.'),
    ),
    CharacterPhotosCompanion.insert(
      characterId: 'amelia',
      photoPath: 'assets/characters/amelia/gallery_2.png',
      caption: const Value('Selfie.'),
    ),
    // Photos for Michael
    CharacterPhotosCompanion.insert(
      characterId: 'michael',
      photoPath: 'assets/characters/michael/work_desk.png',
      caption: const Value('Dreadmoor Daily office.'),
    ),

    // Photos for Chris
    CharacterPhotosCompanion.insert(
      characterId: 'chris',
      photoPath: 'assets/characters/chris/gallery_1.png',
      caption: const Value('Joys Dinner'),
    ),

    // Photos for Abigail
    CharacterPhotosCompanion.insert(
      characterId: 'abigail',
      photoPath: 'assets/characters/abigail/gallery_1.png',
      caption: const Value('bestie...'),
    ),
    // Add more photos as needed for other characters...
  ];

  await db.batch((batch) {
    // Insert characters
    batch.insertAll(db.characters, characters, mode: InsertMode.insertOrReplace);
    // Insert gallery photos
    batch.insertAll(db.characterPhotos, galleryPhotos, mode: InsertMode.insertOrReplace);
  });
}
