import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/persistence/drift_database.dart';
import 'game_state.dart';

final recapProvider = FutureProvider<List<String>>((ref) async {
  final db = ref.watch(databaseProvider);

  final flags = await db.select(db.storyState).get();
  final messages = await (db.select(db.messages)
        ..orderBy([(m) => OrderingTerm(expression: m.timestamp, mode: OrderingMode.desc)])
        ..limit(1))
      .getSingleOrNull();

  final evidence = await db.select(db.storyState).get();

  final lines = <String>[];

  lines.add("Previously on Dreadmoor...");
  lines.add("");

  if (flags.any((f) => f.key == 'found_factory_phone')) {
    lines.add("Rebecca’s phone was recovered near the abandoned factory.");
  }

  if (flags.any((f) => f.key == 'confronted_amelia')) {
    lines.add("You confronted Amelia about the lies in her story.");
  }

  if (flags.any((f) => f.key == 'saw_highway_crash')) {
    lines.add("Evidence from the highway crash raised new questions.");
  }

  if (evidence.any((e) => e.key.startsWith('found_diary'))) {
    lines.add("Fragments of Rebecca’s diary revealed disturbing details.");
  }

  if (messages != null) {
    lines.add("");
    lines.add("The last message ended in silence.");
  }

  lines.add("");
  lines.add("Now, the investigation continues...");

  return lines;
});
