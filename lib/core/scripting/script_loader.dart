import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import '../persistence/drift_database.dart';

class ScriptLoader {
  final AppDatabase db;

  ScriptLoader(this.db);

  /// Main entry point: Scans the assets/story folder and imports into DB
  Future<void> importEpisode(String episodeId) async {
    try {
      // 1. Load the markdown file from the new path
      final String rawContent = await rootBundle.loadString(
        'assets/story/$episodeId/script.md',
      );

      // 2. Split the file into individual Node blocks using the "# " delimiter
      final List<String> blocks = rawContent.split(RegExp(r'\n(?=# )'));

      for (var block in blocks) {
        if (block.trim().isEmpty) continue;
        await _parseAndInsertNode(block.trim());
      }
      
      print("DreadmoorOS: Episode $episodeId imported successfully.");
    } catch (e) {
      print("DreadmoorOS Critical Error: Failed to import episode $episodeId: $e");
    }
  }

  /// The Regex Engine: Turns plain text into a Database Row
  Future<void> _parseAndInsertNode(String block) async {
    // Regex Patterns for Obsidian Protocol
    final idMatch = RegExp(r'# ([\w_]+)').firstMatch(block);
    final typeMatch = RegExp(r'Type: ([\w_]+)').firstMatch(block);
    final chatMatch = RegExp(r'Chat: ([\w_]+)').firstMatch(block);
    final senderMatch = RegExp(r'Sender: ([\w_]+)').firstMatch(block);
    final nextMatch = RegExp(r'Next: \[\[([\w_]+)\]\]').firstMatch(block);
    
    // Extract Text (handles multi-line content)
    final textMatch = RegExp(r'Text: ([\s\S]*?)(?=\n\w+:|$)').firstMatch(block);

    // Extract Metadata (Typing, Pauses, Files)
    final actionMatch = RegExp(r'Action: ([\w_]+)').firstMatch(block);
    final durationMatch = RegExp(r'Duration: (\d+)').firstMatch(block);
    final assetMatch = RegExp(r'File_Asset: ([\/\w\.-]+)').firstMatch(block);

    // Extract Choices (Only for Player_Choice nodes)
    final List<Map<String, String>> options = [];
    final optionMatches = RegExp(r'- Option: "(.*?)" -> \[\[([\w_]+)\]\]').allMatches(block);
    for (final m in optionMatches) {
      options.add({'text': m.group(1)!, 'target': m.group(2)!});
    }

    if (idMatch != null) {
      final nodeId = idMatch.group(1)!;
      
      // Build metadata map
      final Map<String, dynamic> metadata = {
        if (actionMatch != null) 'action': actionMatch.group(1),
        if (durationMatch != null) 'duration': int.parse(durationMatch.group(1)!),
        if (assetMatch != null) 'file_asset': assetMatch.group(1),
        if (options.isNotEmpty) 'options': options,
      };

      // Insert into StoryNodes Table
      await db.into(db.storyNodes).insertOnConflictUpdate(
        StoryNodesCompanion.insert(
          id: nodeId,
          type: typeMatch?.group(1) ?? 'Chat_Event',
          senderId: drift.Value(senderMatch?.group(1)),
          content: drift.Value(textMatch?.group(1)?.trim()),
          nextNodeId: drift.Value(nextMatch?.group(1)),
          metadata: drift.Value(jsonEncode(metadata)),
        ),
      );
    }
  }
}
