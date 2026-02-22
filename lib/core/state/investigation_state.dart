import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/persistence/drift_database.dart';
import 'game_state.dart';

class EvidenceItem {
  final String id;
  final String title;
  final String type; // diary, photo, document
  final String content;
  final String imagePath;
  final String requiredFlag;

  const EvidenceItem({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.imagePath,
    required this.requiredFlag,
  });
}

final allEvidence = <EvidenceItem>[
  EvidenceItem(
    id: 'diary_01',
    title: 'October 12th',
    type: 'diary',
    content: 'I saw him again today. The man with the scar...',
    imagePath: 'assets/map/locations/factory.png',
    requiredFlag: 'found_diary_01',
  ),
  EvidenceItem(
    id: 'photo_factory',
    title: 'Factory Entrance',
    type: 'photo',
    content: 'Security cam footage from the abandoned factory.',
    imagePath: 'assets/map/locations/factory.png',
    requiredFlag: 'visited_factory',
  ),
];

final unlockedEvidenceProvider = FutureProvider<List<EvidenceItem>>((ref) async {
  final db = ref.watch(databaseProvider);
  final flags = await db.select(db.storyState).get();
  final unlocked = flags.map((s) => s.key).toSet();

  return allEvidence.where((e) => unlocked.contains(e.requiredFlag)).toList();
});

final diaryProgressProvider = FutureProvider<double>((ref) async {
  final evidence = await ref.watch(unlockedEvidenceProvider.future);
  final diaryItems = evidence.where((e) => e.type == 'diary').length;
  final totalDiary = allEvidence.where((e) => e.type == 'diary').length;

  if (totalDiary == 0) return 0.0;
  return diaryItems / totalDiary;
});
