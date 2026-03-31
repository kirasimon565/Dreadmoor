// lib/features/minigame/tracecore/data/tracecore_demo_data.dart
//
// Predefined, deterministic puzzle used exclusively by the Guided Demo.
// Never randomised. Always the same target and clues.

import '../models/tracecore_target.dart';
import '../models/tracecore_clue.dart';

abstract final class TraceCoreDemoData {
  static const target = TracecoreTarget(
    ip:       '192.168.43.21',
    name:     'Rebecca',
    tag:      'RB-A9F2',
    location: 'Downtown hotspot',
  );

  static const clues = <TracecoreClue>[
    // Chat clue — behavioural/location hint
    TracecoreClue(
      panel:   CluePanel.chat,
      content: 'UserX: same café again?\nUserY: yeah, that downtown place',
    ),

    // Network clue — correct IP + location
    TracecoreClue(
      panel:   CluePanel.network,
      content: 'IP: 192.168.43.21\nLocation: Downtown hotspot\nTime: 23:41',
    ),

    // Database clue — identity confirmation
    TracecoreClue(
      panel:   CluePanel.database,
      content: 'Name: Rebecca\nFrequent Location: Downtown café\nTag: RB-A9F2',
    ),
  ];
}
