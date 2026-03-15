import 'dart:convert';

class DreadmoorNode {
  final String id;
  final String type;
  final String? senderId;
  final String? content;
  final String? nextNodeId;
  final Map<String, dynamic> metadata;

  DreadmoorNode({
    required this.id,
    required this.type,
    this.senderId,
    this.content,
    this.nextNodeId,
    this.metadata = const {},
  });

  factory DreadmoorNode.fromDb(dynamic row) {
    return DreadmoorNode(
      id:         row.id,
      type:       row.type,
      senderId:   row.senderId,
      content:    row.content,
      nextNodeId: row.nextNodeId,
      metadata:   row.metadata != null
          ? (jsonDecode(row.metadata!) as Map<String, dynamic>)
          : {},
    );
  }

  /// Returns choices for Player_Choice nodes.
  ///
  /// FIX: was reading map['target'] but every JSON option uses "next".
  ///   {"text": "...", "next": "S2_Unknown_Rebuttal"}
  /// DreadmoorChoice.fromMap now reads map['next'] ?? map['target'].
  /// That single missing fallback was why the story stopped after
  /// every choice — target was always '', _executeNode('') returned
  /// immediately, nothing ever followed a player selection.
  List<DreadmoorChoice> get choices {
    if (type != 'Player_Choice') return [];
    final raw = metadata['options'];
    if (raw == null || raw is! List) return [];
    return (raw as List)
        .map((o) => DreadmoorChoice.fromMap(o as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic>? get nextOnDecline =>
      metadata['next_on_decline'] as Map<String, dynamic>?;
}

class DreadmoorChoice {
  final String text;
  final String target; // the next node ID

  DreadmoorChoice({required this.text, required this.target});

  factory DreadmoorChoice.fromMap(Map<String, dynamic> map) {
    return DreadmoorChoice(
      text: (map['text'] as String?) ?? '',
      // JSON uses "next"; keep "target" as fallback for back-compat.
      target: (map['next'] as String?)
          ?? (map['target'] as String?)
          ?? '',
    );
  }
}

class DreadmoorNodeTypes {
  static const String chatEvent          = 'Chat_Event';
  static const String playerChoice       = 'Player_Choice';
  static const String videoMessage       = 'Video_Message';
  static const String newsModule         = 'News_Module';
  static const String phoneCall          = 'Phone_Call_Event';
  static const String systemNotification = 'System_Notification';
}

class DreadmoorActions {
  static const String typing       = 'Typing';
  static const String pause        = 'Pause';
  static const String notification = 'Notification';
}
