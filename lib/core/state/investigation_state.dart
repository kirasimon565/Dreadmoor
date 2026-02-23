import 'package:collection/collection.dart'; // FIX 4: firstWhereOrNull
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persistence/drift_database.dart';
import 'game_state.dart';

// ─────────────────────────────────────────────────────────────
// Base evidence model — static data only, no DB state
// ─────────────────────────────────────────────────────────────

class EvidenceItem {
  final String id;
  final String title;
  final String? subtitle; // optional secondary line shown in evidence detail
  final String type; // 'diary' | 'photo' | 'document'
  final String content;
  final String imagePath;
  final String requiredFlag;

  // FIX 3: Added isLocked and recoveryPercent.
  // These cannot be set on the static allEvidence list (no DB access there),
  // so they default to safe values. The enriched provider below overrides them.
  // isLocked: true = player has not found this item yet
  // recoveryPercent: 0.0–1.0 progress through a diary entry (null if not applicable)
  final bool isLocked;
  final double? recoveryPercent;

  const EvidenceItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    required this.content,
    required this.imagePath,
    required this.requiredFlag,
    this.isLocked = true,
    this.recoveryPercent,
  });

  // Produces a copy with DB-resolved status fields
  EvidenceItem withStatus({
    required bool isLocked,
    double? recoveryPercent,
  }) {
    return EvidenceItem(
      id: id,
      title: title,
      subtitle: subtitle,
      type: type,
      content: content,
      imagePath: imagePath,
      requiredFlag: requiredFlag,
      isLocked: isLocked,
      recoveryPercent: recoveryPercent,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Static master list — no DB references here
// ─────────────────────────────────────────────────────────────

const allEvidence = <EvidenceItem>[
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

// ─────────────────────────────────────────────────────────────
// All evidence enriched with lock status from DB
//
// FIX 3: This is the provider detective_board_screen.dart should watch.
// Returns ALL evidence items (locked + unlocked) with isLocked and
// recoveryPercent correctly set from DB flags.
//
// FIX 1: ref.read, not ref.watch, inside async provider body
// ─────────────────────────────────────────────────────────────

final allEvidenceProvider = FutureProvider<List<EvidenceItem>>((ref) async {
  // FIX 1: ref.read — not ref.watch — inside async FutureProvider body
  final db = ref.read(databaseProvider);
  final flagRows = await db.select(db.storyState).get();
  final unlockedKeys = flagRows.where((f) => f.value).map((f) => f.key).toSet();

  return allEvidence.map((item) {
    final locked = !unlockedKeys.contains(item.requiredFlag);

    // recoveryPercent: for diary items, derive from a 'diary_read_{id}' flag
    // or a dedicated float stored elsewhere. For now we use a binary:
    // unlocked-but-unread = 0.0, unlocked = 1.0, locked = null.
    // Extend this logic when partial-read tracking is added.
    final recovery = locked ? null : 1.0;

    return item.withStatus(isLocked: locked, recoveryPercent: recovery);
  }).toList();
});

// ─────────────────────────────────────────────────────────────
// Unlocked-only evidence — for recap, evidence detail etc.
// ─────────────────────────────────────────────────────────────

final unlockedEvidenceProvider = FutureProvider<List<EvidenceItem>>((ref) async {
  // FIX 1: ref.read inside async body
  final all = await ref.read(allEvidenceProvider.future);
  return all.where((e) => !e.isLocked).toList();
});

// ─────────────────────────────────────────────────────────────
// Diary progress provider
//
// FIX 2: Changed from FutureProvider<double> to
//         FutureProvider.family<double, String> so it can be
//         called as diaryProgressProvider(diaryId) in screens.
//
// The diaryId argument lets callers get progress for a specific
// diary entry rather than an aggregate across all diaries.
//
// FIX 1: ref.read inside async body
// ─────────────────────────────────────────────────────────────

final diaryProgressProvider =
    FutureProvider.family<double, String>((ref, diaryId) async {
  // FIX 1: ref.read, not ref.watch
  final all = await ref.read(allEvidenceProvider.future);

  // If called for a specific diary ID, return its individual progress
  final item = all.firstWhereOrNull((e) => e.id == diaryId);
  if (item != null) {
    if (item.isLocked) return 0.0;
    return item.recoveryPercent ?? 1.0;
  }

  // Fallback: aggregate progress across all diary-type items
  final diaryItems = all.where((e) => e.type == 'diary');
  final total = diaryItems.length;
  if (total == 0) return 0.0;
  final unlocked = diaryItems.where((e) => !e.isLocked).length;
  return unlocked / total;
});
