import 'dart:io';
import 'dart:convert';
import 'lib/core/models/script_models.dart';

void main() {
  final file = File('content/episodes/ep01.json');
  final jsonString = file.readAsStringSync();
  final jsonData = jsonDecode(jsonString);
  final episode = EpisodeScript.fromJson(jsonData);

  print('Successfully parsed episode: ${episode.title}');
  print('Total scenes: ${episode.scenes.length}');
  int totalEvents = 0;
  for (var scene in episode.scenes) {
    totalEvents += scene.events.length;
  }
  print('Total events: $totalEvents');

  // Find all event types
  final Set<String> eventTypes = {};
  for (var scene in episode.scenes) {
    for (var event in scene.events) {
      eventTypes.add(event.type);
      if (event.type == 'news') {
         print('News event parsed. Headline: ${event.headline}');
      }
    }
  }
  print('Event types found: $eventTypes');
}
