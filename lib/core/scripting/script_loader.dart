import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import '../persistence/drift_database.dart';
import '../persistence/seed_characters.dart';
import 'episode_manifest.dart';

class ScriptLoader {
  final AppDatabase db;
  ScriptLoader(this.db);

  /// Imports ALL episodes that haven't been imported yet.
  /// Safe to call on every launch — already-imported episodes are skipped.
  /// When ep02 ships, it imports automatically on next launch with no code change.
  Future<void> importPendingEpisodes() async {
    await seedCharacters(db);
    for (final episode in EpisodeManifest.all) {
      await _importIfNeeded(episode);
    }
  }

  /// Force-import a single episode by ID. Used by initializeDefaultData.
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
    // Check Episodes table — progress > 0 means already imported.
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

        final nodes = (jsonDecode(raw) as Map<String, dynamic>)['scenes'] as List<dynamic>;
        for (final node in nodes) {
          await _parseAndInsertNode(node as Map<String, dynamic>);
          count++;
        }
      }

      // Record import in Episodes table so it never runs again.
      await db.into(db.episodes).insertOnConflictUpdate(
        EpisodesCompanion.insert(
          id:         episode.id,
          isUnlocked: const drift.Value(true),
          progress:   drift.Value(count),
        ),
      );

      print("DreadmoorOS: '${episode.id}' done — $count nodes.");
    } catch (e, st) {
      print("DreadmoorOS: Import failed for '${episode.id}': $e\n$st");
    }
  }

  Future<void> _parseAndInsertNode(Map<String, dynamic> nodeData) async {
    final nodeId   = nodeData['id'] as String;
    final type     = nodeData['type'] as String;
    final senderId = (nodeData['sender'] as String?)?.toLowerCase().trim();

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
