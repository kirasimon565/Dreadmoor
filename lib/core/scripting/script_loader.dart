import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/script_models.dart';

class ScriptLoader {
  Future<EpisodeMeta> loadEpisodeMeta(String episodeId) async {
    final String response = await rootBundle.loadString('content/episodes/$episodeId/episode_meta.json');
    final data = await json.decode(response);
    return EpisodeMeta.fromJson(data);
  }

  Future<ThreadScript> loadThreadScript(String episodeId, String threadId) async {
    final String response = await rootBundle.loadString('content/episodes/$episodeId/threads/$threadId.json');
    final data = await json.decode(response);
    return ThreadScript.fromJson(data);
  }
}
