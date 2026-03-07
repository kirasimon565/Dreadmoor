import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/script_models.dart';

class ScriptLoader {

  /// Load full episode script (ep01.json, ep02.json, etc.)
  Future<EpisodeScript> loadEpisode(String episodeId) async {
    final String response =
        await rootBundle.loadString('content/episodes/$episodeId.json');

    final data = json.decode(response);

    return EpisodeScript.fromJson(data);
  }

  /// Optional: preload episodes if needed later
  static Future<void> loadAll() async {
    // Reserved for future: caching, indexing episodes, etc.
  }
}
