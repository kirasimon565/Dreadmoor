// lib/features/minigame/tracecore/models/tracecore_clue.dart

enum CluePanel { chat, network, database }

class TracecoreClue {
  final CluePanel panel;
  final String    content;
  final bool      isDistractor; // true → misleads, false → correct trail

  const TracecoreClue({
    required this.panel,
    required this.content,
    this.isDistractor = false,
  });

  factory TracecoreClue.fromJson(Map<String, dynamic> j) => TracecoreClue(
        panel:        CluePanel.values.firstWhere(
            (e) => e.name == (j['panel'] as String)),
        content:      j['content'] as String,
        isDistractor: j['isDistractor'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'panel':        panel.name,
        'content':      content,
        'isDistractor': isDistractor,
      };
}
