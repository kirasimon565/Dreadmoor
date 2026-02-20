import 'package:json_annotation/json_annotation.dart';

part 'script_models.g.dart';

@JsonSerializable()
class EpisodeMeta {
  final String id;
  final String title;
  final String description;
  final bool isLocked;
  final List<String> threads;

  EpisodeMeta({
    required this.id,
    required this.title,
    required this.description,
    this.isLocked = true,
    required this.threads,
  });

  factory EpisodeMeta.fromJson(Map<String, dynamic> json) => _$EpisodeMetaFromJson(json);
  Map<String, dynamic> toJson() => _$EpisodeMetaToJson(this);
}

@JsonSerializable()
class ThreadScript {
  final String id;
  final String title;
  final List<String> participants;
  final List<ScriptLine> script;

  ThreadScript({
    required this.id,
    required this.title,
    required this.participants,
    required this.script,
  });

  factory ThreadScript.fromJson(Map<String, dynamic> json) => _$ThreadScriptFromJson(json);
  Map<String, dynamic> toJson() => _$ThreadScriptToJson(this);
}

@JsonSerializable()
class ScriptLine {
  final String id;
  final String type; // text, choice, player_text
  final String? senderId;
  final String? content;
  final int? delay;
  final String? next;
  final List<ChoiceOption>? options;
  final String? jumpto; // For jumping to another line ID

  ScriptLine({
    required this.id,
    required this.type,
    this.senderId,
    this.content,
    this.delay,
    this.next,
    this.options,
    this.jumpto,
  });

  factory ScriptLine.fromJson(Map<String, dynamic> json) => _$ScriptLineFromJson(json);
  Map<String, dynamic> toJson() => _$ScriptLineToJson(this);
}

@JsonSerializable()
class ChoiceOption {
  final String text;
  final String jumpto;

  ChoiceOption({required this.text, required this.jumpto});

  factory ChoiceOption.fromJson(Map<String, dynamic> json) => _$ChoiceOptionFromJson(json);
  Map<String, dynamic> toJson() => _$ChoiceOptionToJson(this);
}
