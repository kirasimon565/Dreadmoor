import 'package:json_annotation/json_annotation.dart';

part 'script_models.g.dart';


/// ------------------------------------------------------------
/// EPISODE
/// ------------------------------------------------------------

@JsonSerializable(explicitToJson: true)
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

@JsonSerializable(explicitToJson: true)
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

@JsonSerializable(explicitToJson: true)
class EventScript {
  final String id;
  final String type;

  final String? threadId;
  final String? sender;
  final String? text;

  final String? choiceId;
  final List<ChoiceOption>? options;

  final int? duration;

  final EventMeta? meta;

  EventScript({
    required this.id,
    required this.type,
    this.threadId,
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

@JsonSerializable(explicitToJson: true)
class EventMeta {
  final int? delayAfter;

  EventMeta({this.delayAfter});

  factory EventMeta.fromJson(Map<String, dynamic> json) =>
      _$EventMetaFromJson(json);

  Map<String, dynamic> toJson() => _$EventMetaToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ChoiceOption {
  final String text;
  final String jumpto;

  ChoiceOption({
    required this.text,
    required this.jumpto,
  });

  factory ChoiceOption.fromJson(Map<String, dynamic> json) =>
      _$ChoiceOptionFromJson(json);

  Map<String, dynamic> toJson() => _$ChoiceOptionToJson(this);
}
