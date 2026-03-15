import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import '../persistence/drift_database.dart';
import '../persistence/seed_characters.dart';

class ScriptLoader {
  final AppDatabase db;
  ScriptLoader(this.db);

  Future<void> importEpisode(String episodeId) async {
    // FIX: seed characters BEFORE importing nodes.
    // StoryNodes.senderId FK-references Characters.id.
    // If FK enforcement is active, nodes with an unknown senderId fail silently
    // inside this try/catch — leaving them permanently absent from the DB.
    // Seeding first guarantees all referenced character IDs exist.
    await seedCharacters(db);

    try {
      final scenes = [
        'assets/story/ep01/scene_01.json',
        'assets/story/ep01/scene_02.json',
        'assets/story/ep01/scene_03.json',
        'assets/story/ep01/scene_04.json',
        'assets/story/ep01/scene_05.json',
        'assets/story/ep01/scene_06.json',
      ];

      int count = 0;
      for (final path in scenes) {
        final raw   = await rootBundle.loadString(path);
        final data  = jsonDecode(raw) as Map<String, dynamic>;
        final nodes = data['scenes'] as List<dynamic>;
        for (final node in nodes) {
          await _parseAndInsertNode(node as Map<String, dynamic>);
          count++;
        }
      }
      print('DreadmoorOS: Episode $episodeId — $count nodes imported.');
    } catch (e, stack) {
      print('DreadmoorOS: importEpisode($episodeId) failed: $e');
      print(stack);
    }
  }

  Future<void> _parseAndInsertNode(Map<String, dynamic> nodeData) async {
    final nodeId = nodeData['id'] as String;
    final type   = nodeData['type'] as String;

    // FIX: lowercase senderId to match Characters.id casing.
    // JSON: "sender": "Unknown"  →  Characters.id: 'unknown'
    final rawSender = nodeData['sender'] as String?;
    final senderId  = rawSender?.toLowerCase().trim();

    const coreKeys = {'id', 'type', 'sender', 'text', 'next'};
    final metadata  = <String, dynamic>{};
    for (final key in nodeData.keys) {
      if (!coreKeys.contains(key)) metadata[key] = nodeData[key];
    }

    await db.into(db.storyNodes).insertOnConflictUpdate(
      StoryNodesCompanion.insert(
        id:         nodeId,
        type:       type,
        senderId:   drift.Value(senderId),
        content:    drift.Value(nodeData['text'] as String?),
        nextNodeId: drift.Value(nodeData['next'] as String?),
        metadata:   drift.Value(jsonEncode(metadata)),
      ),
    );
  }
}
