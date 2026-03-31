// lib/features/minigame/tracecore/models/tracecore_session.dart

import 'tracecore_target.dart';

class TracecoreSession {
  final TracecoreTarget target;
  final String?         selectedIp;
  final String?         selectedName;
  final int             startTimestamp; // epoch ms
  final int             durationSeconds;
  final int             hearts;
  final String          phase; // 'active' | 'complete' | 'failed'

  const TracecoreSession({
    required this.target,
    required this.startTimestamp,
    required this.durationSeconds,
    required this.hearts,
    required this.phase,
    this.selectedIp,
    this.selectedName,
  });

  factory TracecoreSession.fromJson(Map<String, dynamic> j) {
    return TracecoreSession(
      target:          TracecoreTarget.fromJson(
          j['target'] as Map<String, dynamic>),
      selectedIp:      j['selected']?['ip']   as String?,
      selectedName:    j['selected']?['name'] as String?,
      startTimestamp:  j['startTime']         as int,
      durationSeconds: j['duration']          as int,
      hearts:          j['hearts']            as int,
      phase:           j['phase']             as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'target':    target.toJson(),
        'selected': {'ip': selectedIp, 'name': selectedName},
        'startTime': startTimestamp,
        'duration':  durationSeconds,
        'hearts':    hearts,
        'phase':     phase,
      };

  TracecoreSession copyWith({
    String? selectedIp,
    String? selectedName,
    int?    hearts,
    String? phase,
  }) {
    return TracecoreSession(
      target:          target,
      startTimestamp:  startTimestamp,
      durationSeconds: durationSeconds,
      selectedIp:      selectedIp   ?? this.selectedIp,
      selectedName:    selectedName ?? this.selectedName,
      hearts:          hearts       ?? this.hearts,
      phase:           phase        ?? this.phase,
    );
  }

  /// Seconds elapsed since the session started (real-world clock).
  int get elapsedSeconds =>
      ((DateTime.now().millisecondsSinceEpoch - startTimestamp) / 1000)
          .floor();

  int get secondsLeft =>
      (durationSeconds - elapsedSeconds).clamp(0, durationSeconds);
}
