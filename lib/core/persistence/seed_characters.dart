import 'package:drift/drift.dart';
import 'drift_database.dart';

Future<void> seedCharacters(AppDatabase db) async {
  final characters = [
    CharactersCompanion.insert(
      id: 'unknown',
      name: 'Unknown',
      phoneNumber: '+1 (555) 000-0000',
      avatarPath: const Value('assets/characters/unknown.png'),
    ),
    CharactersCompanion.insert(
      id: 'michael',
      name: 'Michael',
      phoneNumber: '+1 (555) 000-0001',
      avatarPath: const Value('assets/characters/michael.png'),
    ),
    CharactersCompanion.insert(
      id: 'chris',
      name: 'Chris',
      phoneNumber: '+1 (555) 000-0002',
      avatarPath: const Value('assets/characters/chris.png'),
    ),
    CharactersCompanion.insert(
      id: 'amelia',
      name: 'Amelia',
      phoneNumber: '+1 (555) 000-0003',
      avatarPath: const Value('assets/characters/amelia.png'),
    ),
    CharactersCompanion.insert(
      id: 'abigail',
      name: 'Abigail',
      phoneNumber: '+1 (555) 000-0004',
      avatarPath: const Value('assets/characters/abigail.png'),
    ),
    CharactersCompanion.insert(
      id: 'system',
      name: 'System',
      phoneNumber: '0000',
      avatarPath: const Value(null),
    ),
  ];

  await db.batch((batch) {
    batch.insertAll(db.characters, characters, mode: InsertMode.insertOrReplace);
  });
}
