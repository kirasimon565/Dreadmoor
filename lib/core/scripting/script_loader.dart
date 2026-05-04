import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import '../persistence/drift_database.dart';
import '../persistence/seed_characters.dart';
import 'episode_manifest.dart';

class ScriptLoader {
  final AppDatabase db;
  ScriptLoader(this.db);

  Future<void> importPendingEpisodes() async {
    await seedCharacters(db);
    for (final episode in EpisodeManifest.all) {
      await _importIfNeeded(episode);
    }

    // Set the starting node if not already configured.
    // This is the story entry point — change when a new episode becomes
    // the active starting episode.
    final existingStart = await (db.select(db.storyState)
          ..where((t) => t.key.equals('start_node_id')))
        .getSingleOrNull();

    if (existingStart == null || existingStart.stringValue == null) {
      await db.into(db.storyState).insertOnConflictUpdate(
            StoryStateCompanion(
              key: const drift.Value('start_node_id'),
              stringValue: const drift.Value('SCENE_1_NEWS_ARTICLE'),
            ),
          );
      print("DreadmoorOS ✓ start_node_id set to 'SCENE_1_NEWS_ARTICLE'");
    }
  }

  Future<void> importEpisode(String episodeId) async {
    await seedCharacters(db);
    final manifest = EpisodeManifest.get(episodeId);
    if (manifest == null) {
      print("DreadmoorOS: No manifest for '$episodeId'.");
      return;
    }
    await _importIfNeeded(manifest);
  }

  Future<void> _importIfNeeded(EpisodeManifest episode) async {
    final existing = await (db.select(db.episodes)
          ..where((e) => e.id.equals(episode.id)))
        .getSingleOrNull();
    if (existing != null && existing.progress > 0) {
      print("DreadmoorOS: '${episode.id}' already imported, skipping.");
      return;
    }
    print("DreadmoorOS: Importing '${episode.id}'...");
    try {
      int count = 0;
      for (final path in episode.scenePaths) {
        String raw;
        try {
          raw = await rootBundle.loadString(path);
        } catch (_) {
          print("DreadmoorOS: Scene not found, skipping: $path");
          continue;
        }
        final nodes =
            (jsonDecode(raw) as Map<String, dynamic>)['scenes'] as List<dynamic>;
        for (final node in nodes) {
          await _parseAndInsertNode(node as Map<String, dynamic>);
          count++;
        }
      }
      await db.into(db.episodes).insertOnConflictUpdate(
            EpisodesCompanion.insert(
              id: episode.id,
              isUnlocked: const drift.Value(true),
              progress: drift.Value(count),
            ),
          );
      print("DreadmoorOS: '${episode.id}' done — $count nodes.");
    } catch (e, st) {
      print("DreadmoorOS: Import failed for '${episode.id}': $e\n$st");
    }
  }

  Future<void> _parseAndInsertNode(Map<String, dynamic> nodeData) async {
    final nodeId = nodeData['id'] as String;
    final type = nodeData['type'] as String;
    final senderId = (nodeData['sender'] as String?)?.toLowerCase().trim();
    const coreKeys = {'id', 'type', 'sender', 'text', 'next'};
    final metadata = <String, dynamic>{};
    for (final key in nodeData.keys) {
      if (!coreKeys.contains(key)) metadata[key] = nodeData[key];
    }
    await db.into(db.storyNodes).insertOnConflictUpdate(
          StoryNodesCompanion.insert(
            id: nodeId,
            type: type,
            senderId: drift.Value(senderId),
            content: drift.Value(nodeData['text'] as String?),
            nextNodeId: drift.Value(nodeData['next'] as String?),
            metadata: drift.Value(jsonEncode(metadata)),
          ),
        );
  }
}
