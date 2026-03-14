import 'dart:convert';

/// ------------------------------------------------------------
/// DREADMOOR NODE MODEL
/// This replaces the old Episode/Scene script models.
/// It represents a single logic block from your Obsidian files.
/// ------------------------------------------------------------

class DreadmoorNode {
  final String id;          // e.g., [[SCENE_1_START]]
  final String type;        // Chat_Event, Player_Choice, Video_Message, etc.
  final String? senderId;   // unknown, amelia, michael, etc.
  final String? content;    // The actual text/message body
  final String? nextNodeId; // The ID linked via Next: [[ID]]
  
  /// Metadata holds temporary instructions like Action: Typing, 
  /// Duration: 2000, or File_Asset paths.
  final Map<String, dynamic> metadata;

  DreadmoorNode({
    required this.id,
    required this.type,
    this.senderId,
    this.content,
    this.nextNodeId,
    this.metadata = const {},
  });

  /// Converts a Drift database row (StoryNode) into this working model
  factory DreadmoorNode.fromDb(dynamic row) {
    return DreadmoorNode(
      id: row.id,
      type: row.type,
      senderId: row.senderId,
      content: row.content,
      nextNodeId: row.nextNodeId,
      metadata: row.metadata != null 
          ? jsonDecode(row.metadata!) 
          : {},
    );
  }

  /// Helper to get choices if this is a Player_Choice node
  List<DreadmoorChoice> get choices {
    if (type != 'Player_Choice' || !metadata.containsKey('options')) {
      return [];
    }
    final List<dynamic> options = metadata['options'];
    return options.map((o) => DreadmoorChoice.fromMap(o)).toList();
  }

  /// Helper to get decline actions for Phone_Call_Event
  Map<String, dynamic>? get nextOnDecline {
    return metadata['next_on_decline'] as Map<String, dynamic>?;
  }
}

/// ------------------------------------------------------------
/// DREADMOOR CHOICE MODEL
/// Represents a single branching button for the player.
/// ------------------------------------------------------------

class DreadmoorChoice {
  final String text;    // What the button says
  final String target;  // Where it goes (Next Node ID)

  DreadmoorChoice({
    required this.text,
    required this.target,
  });

  factory DreadmoorChoice.fromMap(Map<String, dynamic> map) {
    return DreadmoorChoice(
      text: map['text'] ?? '',
      target: map['target'] ?? '',
    );
  }
}

/// ------------------------------------------------------------
/// PARSER CONSTANTS
/// Use these strings in your code to avoid typos.
/// ------------------------------------------------------------

class DreadmoorNodeTypes {
  static const String chatEvent = 'Chat_Event';
  static const String playerChoice = 'Player_Choice';
  static const String videoMessage = 'Video_Message';
  static const String newsModule = 'News_Module';
  static const String phoneCall = 'Phone_Call_Event';
  static const String systemNotification = 'System_Notification';
}

class DreadmoorActions {
  static const String typing = 'Typing';
  static const String pause = 'Pause';
  static const String notification = 'Notification';
}
