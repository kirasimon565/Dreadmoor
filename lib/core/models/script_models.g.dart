// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpisodeScript _$EpisodeScriptFromJson(Map<String, dynamic> json) =>
    EpisodeScript(
      episodeId: json['episodeId'] as String,
      title: json['title'] as String,
      version: (json['version'] as num).toInt(),
      format: json['format'] as String,
      scenes: (json['scenes'] as List<dynamic>)
          .map((e) => SceneScript.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EpisodeScriptToJson(EpisodeScript instance) =>
    <String, dynamic>{
      'episodeId': instance.episodeId,
      'title': instance.title,
      'version': instance.version,
      'format': instance.format,
      'scenes': instance.scenes,
    };

SceneScript _$SceneScriptFromJson(Map<String, dynamic> json) => SceneScript(
      sceneId: json['sceneId'] as String,
      events: (json['events'] as List<dynamic>)
          .map((e) => EventScript.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SceneScriptToJson(SceneScript instance) =>
    <String, dynamic>{
      'sceneId': instance.sceneId,
      'events': instance.events,
    };

EventScript _$EventScriptFromJson(Map<String, dynamic> json) => EventScript(
      id: json['id'] as String,
      type: json['type'] as String,
      threadId: json['threadId'] as String?,
      sender: json['sender'] as String?,
      text: json['text'] as String?,
      choiceId: json['choiceId'] as String?,
      options:
          (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
      duration: (json['duration'] as num?)?.toInt(),
      meta: json['meta'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$EventScriptToJson(EventScript instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'threadId': instance.threadId,
      'sender': instance.sender,
      'text': instance.text,
      'choiceId': instance.choiceId,
      'options': instance.options,
      'duration': instance.duration,
      'meta': instance.meta,
    };
