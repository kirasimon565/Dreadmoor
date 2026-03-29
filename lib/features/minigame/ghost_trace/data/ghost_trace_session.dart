import 'dart:convert';
import 'package:dreadmoor/features/minigame/ghost_trace/data/target_generator.dart';
import 'package:dreadmoor/features/minigame/ghost_trace/state/ghost_trace_state.dart';

class GhostTraceSession {
  final NetworkTarget target;
  final GhostTracePhase phase;
  final int currentHopIdx;
  final List<String> correctHops;
  final List<String> scrambledIpTiles;
  final List<String> scrambledTagTiles;
  final List<String?> ipSlots;
  final List<String?> tagSlots;
  final DateTime timerEndTimestamp;

  const GhostTraceSession({
    required this.target,
    required this.phase,
    required this.currentHopIdx,
    required this.correctHops,
    required this.scrambledIpTiles,
    required this.scrambledTagTiles,
    required this.ipSlots,
    required this.tagSlots,
    required this.timerEndTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'target': {
        'nodeId': target.nodeId,
        'ip': target.ip,
        'tag': target.tag,
        'relayChain': target.relayChain,
      },
      'phase': phase.name,
      'currentHopIdx': currentHopIdx,
      'correctHops': correctHops,
      'scrambledIpTiles': scrambledIpTiles,
      'scrambledTagTiles': scrambledTagTiles,
      'ipSlots': ipSlots,
      'tagSlots': tagSlots,
      'timerEndTimestamp': timerEndTimestamp.toIso8601String(),
    };
  }

  factory GhostTraceSession.fromJson(Map<String, dynamic> json) {
    final targetMap = json['target'] as Map<String, dynamic>;
    final target = NetworkTarget(
      nodeId: targetMap['nodeId'] as String,
      ip: targetMap['ip'] as String,
      tag: targetMap['tag'] as String,
      relayChain: List<String>.from(targetMap['relayChain'] as List),
    );

    return GhostTraceSession(
      target: target,
      phase: GhostTracePhase.values.firstWhere((e) => e.name == json['phase'],
          orElse: () => GhostTracePhase.scan),
      currentHopIdx: json['currentHopIdx'] as int,
      correctHops: List<String>.from(json['correctHops'] as List),
      scrambledIpTiles: List<String>.from(json['scrambledIpTiles'] as List),
      scrambledTagTiles: List<String>.from(json['scrambledTagTiles'] as List),
      ipSlots: List<String?>.from(json['ipSlots'] as List),
      tagSlots: List<String?>.from(json['tagSlots'] as List),
      timerEndTimestamp: DateTime.parse(json['timerEndTimestamp'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory GhostTraceSession.fromJsonString(String str) =>
      GhostTraceSession.fromJson(jsonDecode(str) as Map<String, dynamic>);
}