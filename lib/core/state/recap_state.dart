import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persistence/drift_database.dart';
import 'game_state.dart';

// ─────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────

enum RecapLineType {
  /// Small all-caps section label (e.g. "LAST KNOWN POSITION")
  category,

  /// Large dramatic text — the cliffhanger moment
  cliffhanger,

  /// A choice the player made, shown with a cyan arrow
  choice,

  /// A piece of evidence collected, shown in a bordered box
  evidence,

  /// Standard narrative recap paragraph
  body,
}

class RecapLine {
  final RecapLineType type;
  final String text;

  const RecapLine({required this.type, required this.text});
}

// ─────────────────────────────────────────────────────────────
// Provider
//
// FIX 1: Was FutureProvider<List<String>> with no episodeId —
//         now FutureProvider.family so the screen can pass its
//         episodeId and get episode-specific content.
//
// FIX 2: `evidence` was a duplicate select of storyState
//         (identical query to `flags`). Removed — flags already
//         covers all StoryState rows.
//
// FIX 3: Was using ref.watch() inside an async FutureProvider —
//         this can cause provider rebuild loops. Changed to
//         ref.read() since the DB reference never changes.
//
// FIX 4: Empty string lines used as spacers — these would render
//         as blank Text() widgets. Spacing is now handled by
//         the UI layer (padding between RecapLineWidgets).
// ─────────────────────────────────────────────────────────────

final recapProvider = FutureProvider.family<List<RecapLine>, String>(
  (ref, episodeId) async {
    // FIX 3: ref.read, not ref.watch, inside async provider body
    final db = ref.read(databaseProvider);

    // All story flags as a flat map for easy lookup
    final flagRows = await db.select(db.storyState).get();
    final flags = {for (final f in flagRows) f.key: f.value};

    // FIX 2: Removed duplicate `evidence` select — flags covers all StoryState rows.
    // Evidence keys are distinguished by their key prefix (e.g. 'found_').

    // Last message in the thread — used for the closing line
    final lastMessage = await (db.select(db.messages)
          ..orderBy([
            (m) => OrderingTerm(
                  expression: m.timestamp,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();

    return _buildLines(
      episodeId: episodeId,
      flags: flags,
      hasLastMessage: lastMessage != null,
    );
  },
);

// ─────────────────────────────────────────────────────────────
// Line builder — typed output consumed by the redesigned screen
// ─────────────────────────────────────────────────────────────

List<RecapLine> _buildLines({
  required String episodeId,
  required Map<String, bool> flags,
  required bool hasLastMessage,
}) {
  final lines = <RecapLine>[];

  // ── Episode-specific narrative ─────────────────────────────
  switch (episodeId) {
    case 'ep01':
      lines.addAll(_ep01Lines(flags));
    case 'ep02':
      lines.addAll(_ep02Lines(flags));
    case 'ep03':
      lines.addAll(_ep03Lines(flags));
    default:
      lines.add(const RecapLine(
        type: RecapLineType.body,
        text: 'You returned to Dreadmoor. The city remembers everything.',
      ));
  }

  // ── Evidence block (shared across episodes, flag-driven) ───
  final evidenceLines = _buildEvidenceLines(flags);
  if (evidenceLines.isNotEmpty) {
    lines.add(const RecapLine(
      type: RecapLineType.category,
      text: 'Evidence On File',
    ));
    lines.addAll(evidenceLines);
  }

  // ── Closing line ───────────────────────────────────────────
  if (hasLastMessage) {
    lines.add(const RecapLine(
      type: RecapLineType.category,
      text: 'Last Transmission',
    ));
    lines.add(const RecapLine(
      type: RecapLineType.cliffhanger,
      text: 'The last message ended in silence.',
    ));
  }

  lines.add(const RecapLine(
    type: RecapLineType.body,
    text: 'Now, the investigation continues...',
  ));

  return lines;
}

// ─────────────────────────────────────────────────────────────
// Evidence lines — flag-driven, shared across episodes
// ─────────────────────────────────────────────────────────────

List<RecapLine> _buildEvidenceLines(Map<String, bool> flags) {
  final lines = <RecapLine>[];

  if (flags['found_factory_phone'] == true) {
    lines.add(const RecapLine(
      type: RecapLineType.evidence,
      text: "Rebecca's phone — recovered near the abandoned factory.",
    ));
  }

  if (flags['saw_highway_crash'] == true) {
    lines.add(const RecapLine(
      type: RecapLineType.evidence,
      text: 'Highway crash scene — evidence raised new questions.',
    ));
  }

  // Diary fragments — any key starting with 'found_diary'
  final hasDiary = flags.keys.any((k) => k.startsWith('found_diary'));
  if (hasDiary) {
    lines.add(const RecapLine(
      type: RecapLineType.evidence,
      text: "Rebecca's diary — fragments revealed disturbing details.",
    ));
  }

  return lines;
}

// ─────────────────────────────────────────────────────────────
// Episode-specific narrative lines
// ─────────────────────────────────────────────────────────────

List<RecapLine> _ep01Lines(Map<String, bool> flags) {
  return [
    const RecapLine(
      type: RecapLineType.category,
      text: 'The Vanishing',
    ),
    const RecapLine(
      type: RecapLineType.body,
      text:
          "Rebecca Stone disappeared without a trace. Her last known location: the Dreadmoor Docks, 11:47 PM.",
    ),
    if (flags['confronted_amelia'] == true)
      const RecapLine(
        type: RecapLineType.choice,
        text: 'You confronted Amelia about the lies in her story.',
      ),
    if (flags['trusted_detective'] == true)
      const RecapLine(
        type: RecapLineType.choice,
        text: 'You trusted Detective Voss with what you found.',
      )
    else
      const RecapLine(
        type: RecapLineType.choice,
        text: 'You kept your findings private.',
      ),
  ];
}

List<RecapLine> _ep02Lines(Map<String, bool> flags) {
  return [
    const RecapLine(
      type: RecapLineType.category,
      text: 'Silent Echoes',
    ),
    const RecapLine(
      type: RecapLineType.body,
      text:
          "The investigation led deeper into Dreadmoor's shadows. Old debts surfaced.",
    ),
    if (flags['contacted_informant'] == true)
      const RecapLine(
        type: RecapLineType.choice,
        text: 'You made contact with the informant known only as "Ash."',
      ),
    if (flags['found_recording'] == true)
      const RecapLine(
        type: RecapLineType.choice,
        text: "The audio recording contained voices that couldn't be placed.",
      ),
  ];
}

List<RecapLine> _ep03Lines(Map<String, bool> flags) {
  return [
    const RecapLine(
      type: RecapLineType.category,
      text: 'Broken Glass',
    ),
    const RecapLine(
      type: RecapLineType.body,
      text: 'Every lead fractured into more questions. The city was lying.',
    ),
    if (flags['confronted_mayor'] == true)
      const RecapLine(
        type: RecapLineType.choice,
        text: 'You confronted Mayor Holt. He denied everything.',
      ),
  ];
}
