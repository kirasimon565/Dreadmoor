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
      // JSON-based approach for EP_01
      final List<String> scenes = [
        'assets/story/ep01/scene_01.json',
        'assets/story/ep01/scene_02.json',
        'assets/story/ep01/scene_03.json',
        'assets/story/ep01/scene_04.json',
        'assets/story/ep01/scene_05.json',
        'assets/story/ep01/scene_06.json',
      ];

      for (var path in scenes) {
        final String rawContent = await rootBundle.loadString(path);
        final Map<String, dynamic> data = jsonDecode(rawContent);
        final List<dynamic> nodesList = data['scenes'];

        for (var node in nodesList) {
          await _parseAndInsertNode(node);
        }
      }

      print("DreadmoorOS: Episode $episodeId imported successfully.");
    } catch (e) {
      print("DreadmoorOS Critical Error: Failed to import episode $episodeId: $e");
    }
  }

  /// Parses a single JSON node and inserts it into the Database
  Future<void> _parseAndInsertNode(Map<String, dynamic> nodeData) async {
    final String nodeId = nodeData['id'];
    final String type = nodeData['type'];

    // Map metadata (all extra keys not directly supported by schema)
    final Map<String, dynamic> metadata = {};
    for (var key in nodeData.keys) {
      if (!['id', 'type', 'sender', 'text', 'next'].contains(key)) {
        metadata[key] = nodeData[key];
      }
    }

    // Insert into StoryNodes Table
    await db.into(db.storyNodes).insertOnConflictUpdate(
      StoryNodesCompanion.insert(
        id: nodeId,
        type: type,
        senderId: drift.Value(nodeData['sender']),
        content: drift.Value(nodeData['text']),
        nextNodeId: drift.Value(nodeData['next']),
        metadata: drift.Value(jsonEncode(metadata)),
      ),
    );
  }
}
