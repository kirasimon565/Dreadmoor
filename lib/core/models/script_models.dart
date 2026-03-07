import 'package:json_annotation/json_annotation.dart';

part 'script_models.g.dart';


/// ------------------------------------------------------------
/// EPISODE
/// ------------------------------------------------------------

@JsonSerializable()
class EpisodeScript {
  final String episodeId;
  final String title;
  final int version;
  final String format;
  final List<SceneScript> scenes;

  EpisodeScript({
    required this.episodeId,
    required this.title,
    required this.version,
    required this.format,
    required this.scenes,
  });

  factory EpisodeScript.fromJson(Map<String, dynamic> json) =>
      _$EpisodeScriptFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodeScriptToJson(this);
}



/// ------------------------------------------------------------
/// SCENE
/// ------------------------------------------------------------

@JsonSerializable()
class SceneScript {
  final String sceneId;
  final List<EventScript> events;

  SceneScript({
    required this.sceneId,
    required this.events,
  });

  factory SceneScript.fromJson(Map<String, dynamic> json) =>
      _$SceneScriptFromJson(json);

  Map<String, dynamic> toJson() => _$SceneScriptToJson(this);
}



/// ------------------------------------------------------------
/// EVENT
/// ------------------------------------------------------------

@JsonSerializable()
class EventScript {
  final String id;
  final String type;

  final String? sender;
  final String? text;

  final String? choiceId;
  final List<String>? options;

  final int? duration;

  final Map<String, dynamic>? meta;

  EventScript({
    required this.id,
    required this.type,
    this.sender,
    this.text,
    this.choiceId,
    this.options,
    this.duration,
    this.meta,
  });

  factory EventScript.fromJson(Map<String, dynamic> json) =>
      _$EventScriptFromJson(json);

  Map<String, dynamic> toJson() => _$EventScriptToJson(this);
}
