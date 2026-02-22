// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpisodeMeta _$EpisodeMetaFromJson(Map<String, dynamic> json) => EpisodeMeta(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isLocked: json['isLocked'] as bool? ?? true,
      threads:
          (json['threads'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$EpisodeMetaToJson(EpisodeMeta instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'isLocked': instance.isLocked,
      'threads': instance.threads,
    };

ThreadScript _$ThreadScriptFromJson(Map<String, dynamic> json) => ThreadScript(
      id: json['id'] as String,
      title: json['title'] as String,
      participants: (json['participants'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      script: (json['script'] as List<dynamic>)
          .map((e) => ScriptLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ThreadScriptToJson(ThreadScript instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'participants': instance.participants,
      'script': instance.script,
    };

ScriptLine _$ScriptLineFromJson(Map<String, dynamic> json) => ScriptLine(
      id: json['id'] as String,
      type: json['type'] as String,
      senderId: json['senderId'] as String?,
      content: json['content'] as String?,
      delay: (json['delay'] as num?)?.toInt(),
      next: json['next'] as String?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => ChoiceOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      jumpto: json['jumpto'] as String?,
    );

Map<String, dynamic> _$ScriptLineToJson(ScriptLine instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'senderId': instance.senderId,
      'content': instance.content,
      'delay': instance.delay,
      'next': instance.next,
      'options': instance.options,
      'jumpto': instance.jumpto,
    };

ChoiceOption _$ChoiceOptionFromJson(Map<String, dynamic> json) => ChoiceOption(
      text: json['text'] as String,
      jumpto: json['jumpto'] as String,
    );

Map<String, dynamic> _$ChoiceOptionToJson(ChoiceOption instance) =>
    <String, dynamic>{
      'text': instance.text,
      'jumpto': instance.jumpto,
    };
