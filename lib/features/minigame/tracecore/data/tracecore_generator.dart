// lib/features/minigame/tracecore/data/tracecore_generator.dart

import 'dart:math';
import '../models/tracecore_target.dart';
import '../models/tracecore_clue.dart';
import '../data/tracecore_difficulty.dart';
import '../utils/fake_data_builder.dart';

class TracecoreGenerator {
  static final _rng = Random();

  /// Generates a puzzle: one correct target + clue list (real + distractors).
  static ({TracecoreTarget target, List<TracecoreClue> clues}) generate({
    required TraceCoreDifficulty difficulty,
  }) {
    // ── Correct target ───────────────────────────────────────────────
    final target = TracecoreTarget(
      ip:       FakeDataBuilder.randomIp(),
      name:     FakeDataBuilder.randomName(),
      tag:      FakeDataBuilder.randomTag(
          FakeDataBuilder.randomName().substring(0, 2).toUpperCase()),
      location: FakeDataBuilder.randomLocation(),
    );

    final clues = <TracecoreClue>[];

    // ── Real clues (always solvable) ─────────────────────────────────
    // Chat panel: behavioral/location hint
    clues.add(TracecoreClue(
      panel:   CluePanel.chat,
      content: _chatClue(target, difficulty.clueClarity),
    ));

    // Network panel: correct IP with location
    clues.add(TracecoreClue(
      panel:   CluePanel.network,
      content: 'IP: ${target.ip}\n'
               'Location: ${target.location}\n'
               'Time: ${_randomTime()}',
    ));

    // Database panel: name + tag confirmation
    clues.add(TracecoreClue(
      panel:   CluePanel.database,
      content: 'Name: ${target.name}\n'
               'Frequent Location: ${target.location}\n'
               'Tag: ${target.tag}',
    ));

    // ── Distractor clues ─────────────────────────────────────────────
    for (int i = 0; i < difficulty.distractorCount; i++) {
      final panel = CluePanel.values[_rng.nextInt(CluePanel.values.length)];
      clues.add(TracecoreClue(
        panel:        panel,
        content:      _distractorClue(panel, target),
        isDistractor: true,
      ));
    }

    // Shuffle so distractors don't always appear at the end
    clues.shuffle(_rng);

    return (target: target, clues: clues);
  }

  static String _chatClue(TracecoreTarget t, double clarity) {
    if (clarity >= 0.8) {
      return 'UserA: heading to ${t.location} again?\n'
             'UserB: yeah, same spot';
    } else if (clarity >= 0.5) {
      return 'UserA: usual place?\n'
             'UserB: somewhere central. you know.';
    } else {
      return 'UserA: ???\n'
             'UserB: same as always';
    }
  }

  static String _distractorClue(CluePanel panel, TracecoreTarget real) {
    switch (panel) {
      case CluePanel.chat:
        final fakeName = FakeDataBuilder.randomName(exclude: real.name);
        final fakeLoc  = FakeDataBuilder.randomLocation(exclude: real.location);
        return 'UserA: meet at $fakeLoc?\n'
               'UserB: sure, $fakeName will be there';
      case CluePanel.network:
        return 'IP: ${FakeDataBuilder.randomIp()}\n'
               'Location: ${FakeDataBuilder.randomLocation(exclude: real.location)}\n'
               'Time: ${_randomTime()}';
      case CluePanel.database:
        final fakeName = FakeDataBuilder.randomName(exclude: real.name);
        return 'Name: $fakeName\n'
               'Frequent Location: ${FakeDataBuilder.randomLocation(exclude: real.location)}\n'
               'Tag: ${FakeDataBuilder.randomTag(fakeName.substring(0, 2).toUpperCase())}';
    }
  }

  static String _randomTime() {
    final h = _rng.nextInt(24).toString().padLeft(2, '0');
    final m = (_rng.nextInt(12) * 5).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
