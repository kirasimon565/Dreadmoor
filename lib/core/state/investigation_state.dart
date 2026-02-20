import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/persistence/drift_database.dart';
import '../../core/persistence/tables.dart';
import 'game_state.dart';

class EvidenceItem {
  final String id;
  final String title;
  final String type; // 'diary', 'photo', 'document'
  final String content;
  final String imagePath;
  final String requiredFlag;

  EvidenceItem({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.imagePath,
    required this.requiredFlag,
  });
}

// Hardcoded registry of all possible evidence
final allEvidence = [
  EvidenceItem(
    id: 'diary_01',
    title: 'October 12th',
    type: 'diary',
    content: 'I saw him again today. The man with the scar...',
    imagePath: 'assets/ui/neon_group_square.png', // Placeholder
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
  // Add more items
];

final unlockedEvidenceProvider = FutureProvider<List<EvidenceItem>>((ref) async {
  final db = ref.watch(databaseProvider);
  final allFlags = await db.select(db.storyState).get();
  final unlockedFlags = allFlags.map((s) => s.key).toSet();

  // For prototype, let's assume some flags are set or just return all for testing
  // return allEvidence.where((e) => unlockedFlags.contains(e.requiredFlag)).toList();

  return allEvidence; // Return all for now to verify UI
});

final diaryProgressProvider = FutureProvider<double>((ref) async {
  final evidence = await ref.watch(unlockedEvidenceProvider.future);
  final diaryItems = evidence.where((e) => e.type == 'diary').length;
  final totalDiary = allEvidence.where((e) => e.type == 'diary').length;
  if (totalDiary == 0) return 0.0;
  return diaryItems / totalDiary;
});
