import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'game_state.dart';

enum RecapLineType {
  category,    // Section Header
  cliffhanger, // Emotional Punch
  choice,      // Cyan Arrow (Decision)
  evidence,    // Bordered Box (Clue)
  body,        // Narrative Prose
}

class RecapLine {
  final RecapLineType type;
  final String text;
  const RecapLine({required this.type, required this.text});
}

/// The recap provider: Analyzes the DB state and generates a "Previously On" summary
final recapProvider = FutureProvider.family<List<RecapLine>, String>((ref, episodeId) async {
  final db = ref.read(databaseProvider);

  // Fetch all flags triggered by the player's choices in Obsidian
  final flagRows = await db.select(db.storyState).get();
  final flags = {for (final f in flagRows) f.key: f.value};

  // Check if any messages exist to determine the cliffhanger
  final lastMessage = await (db.select(db.messages)
        ..orderBy([(m) => OrderingTerm(expression: m.timestamp, mode: OrderingMode.desc)])
        ..limit(1))
      .getSingleOrNull();

  return _buildLines(
    episodeId: episodeId,
    flags: flags,
    hasLastMessage: lastMessage != null,
  );
});

List<RecapLine> _buildLines({
  required String episodeId,
  required Map<String, bool> flags,
  required bool hasLastMessage,
}) {
  final lines = <RecapLine>[];

  switch (episodeId) {
    case 'ep01':
      lines.addAll(_ep01Lines(flags));
      break;
    default:
      lines.add(const RecapLine(type: RecapLineType.body, text: 'The investigation remains cold.'));
  }

  // Evidence Block (Dynamic based on DB flags)
  final evidenceLines = _buildEvidenceLines(flags);
  if (evidenceLines.isNotEmpty) {
    lines.add(const RecapLine(type: RecapLineType.category, text: 'Evidence On File'));
    lines.addAll(evidenceLines);
  }

  // Cliffhanger Logic
  if (hasLastMessage) {
    lines.add(const RecapLine(type: RecapLineType.category, text: 'Current Status'));
    lines.add(const RecapLine(
      type: RecapLineType.cliffhanger, 
      text: 'The line went dead. You are being watched.'
    ));
  }

  return lines;
}

List<RecapLine> _buildEvidenceLines(Map<String, bool> flags) {
  final lines = <RecapLine>[];
  
  // These keys correspond to the 'Action: Set_Flag' nodes in your script
  if (flags['found_factory_clip'] == true) {
    lines.add(const RecapLine(type: RecapLineType.evidence, text: "Party Footage — Proof that the midnight timeline was faked."));
  }
  if (flags['intercepted_chat'] == true) {
    lines.add(const RecapLine(type: RecapLineType.evidence, text: "Leaked Intercept — Amelia and Michael are coordinating their stories."));
  }
  return lines;
}

List<RecapLine> _ep01Lines(Map<String, bool> flags) {
  return [
    const RecapLine(type: RecapLineType.category, text: 'The Disappearance'),
    const RecapLine(
      type: RecapLineType.body, 
      text: "Rebecca Stone vanished after a party at the abandoned factory. The official story says she left at midnight."
    ),
    if (flags['confronted_chris'] == true)
      const RecapLine(type: RecapLineType.choice, text: 'You forced Chris to admit he didn\'t see her leave.'),
    if (flags['trusted_unknown'] == true)
      const RecapLine(type: RecapLineType.choice, text: 'You followed the Hacker\'s lead into the group chat.')
    else
      const RecapLine(type: RecapLineType.choice, text: 'You entered the investigation with deep suspicion.'),
  ];
}
