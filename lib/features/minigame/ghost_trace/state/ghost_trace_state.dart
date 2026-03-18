class GhostTraceState {
  final String targetIp;
  final String targetTag;
  final String scrambledString;
  final int timeRemaining;
  final int hearts;
  final double traceConfidence;
  final DateTime? cooldownUntil;
  final bool isExposePhase;
  final bool isCompleted;

  const GhostTraceState({
    this.targetIp = '',
    this.targetTag = '',
    this.scrambledString = '',
    this.timeRemaining = 60,
    this.hearts = 5,
    this.traceConfidence = 0.0,
    this.cooldownUntil,
    this.isExposePhase = false,
    this.isCompleted = false,
  });

  GhostTraceState copyWith({
    String? targetIp,
    String? targetTag,
    String? scrambledString,
    int? timeRemaining,
    int? hearts,
    double? traceConfidence,
    DateTime? cooldownUntil,
    bool? isExposePhase,
    bool? isCompleted,
  }) {
    return GhostTraceState(
      targetIp: targetIp ?? this.targetIp,
      targetTag: targetTag ?? this.targetTag,
      scrambledString: scrambledString ?? this.scrambledString,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      hearts: hearts ?? this.hearts,
      traceConfidence: traceConfidence ?? this.traceConfidence,
      cooldownUntil: cooldownUntil ?? this.cooldownUntil,
      isExposePhase: isExposePhase ?? this.isExposePhase,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
