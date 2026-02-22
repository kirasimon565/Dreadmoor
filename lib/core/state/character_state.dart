import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../persistence/drift_database.dart';
import 'game_state.dart';

class CharacterProfileData {
  final String id;
  final String name;
  final String imagePath;
  final String age;
  final String job;
  final String relationToRebecca;
  final List<String> facts;
  final List<String> contradictions;
  final String requiredFlag; // unlock gate

  const CharacterProfileData({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.age,
    required this.job,
    required this.relationToRebecca,
    required this.facts,
    required this.contradictions,
    required this.requiredFlag,
  });
}

// Registry (expand later)
final allCharacters = <CharacterProfileData>[
  CharacterProfileData(
    id: 'amelia',
    name: 'AMELIA VANCE',
    imagePath: 'assets/characters/amelia.png',
    age: '24',
    job: 'Journalist',
    relationToRebecca: 'Childhood Friend',
    facts: [
      'Last person to see Rebecca alive.',
      'Avoids the factory district.',
      'Deleted chat logs from the night of disappearance.',
    ],
    contradictions: [
      'Claims she never went to the factory after midnight.',
      'Security footage places her nearby at 02:47 AM.',
    ],
    requiredFlag: 'profile_amelia_unlocked',
  ),
];

final unlockedCharactersProvider =
    FutureProvider.family<CharacterProfileData?, String>((ref, characterId) async {
  final db = ref.watch(databaseProvider);
  final flags = await db.select(db.storyState).get();
  final unlockedFlags = flags.map((f) => f.key).toSet();

  final profile =
      allCharacters.where((c) => c.id == characterId).firstOrNull;

  if (profile == null) return null;
  if (!unlockedFlags.contains(profile.requiredFlag)) return null;

  return profile;
});
