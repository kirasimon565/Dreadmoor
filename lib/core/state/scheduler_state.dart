import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single source of truth for all scheduler state.
/// Replaces five separate providers that had to stay in sync manually.
class SchedulerState {
  final bool isPaused;
  final bool waitingForChoice;
  final bool waitingForPuzzle;
  final bool isSubmittingChoice;
  final String? activeNodeId;
  final String? activeThreadId;

  const SchedulerState({
    this.isPaused = false,
    this.waitingForChoice = false,
    this.waitingForPuzzle = false,
    this.isSubmittingChoice = false,
    this.activeNodeId,
    this.activeThreadId,
  });

  SchedulerState copyWith({
    bool? isPaused,
    bool? waitingForChoice,
    bool? waitingForPuzzle,
    bool? isSubmittingChoice,
    String? activeNodeId,
    String? activeThreadId,
    bool clearActiveNodeId = false,
    bool clearActiveThreadId = false,
  }) {
    return SchedulerState(
      isPaused: isPaused ?? this.isPaused,
      waitingForChoice: waitingForChoice ?? this.waitingForChoice,
      waitingForPuzzle: waitingForPuzzle ?? this.waitingForPuzzle,
      isSubmittingChoice: isSubmittingChoice ?? this.isSubmittingChoice,
      activeNodeId:
          clearActiveNodeId ? null : (activeNodeId ?? this.activeNodeId),
      activeThreadId:
          clearActiveThreadId ? null : (activeThreadId ?? this.activeThreadId),
    );
  }
}

class SchedulerStateNotifier extends Notifier<SchedulerState> {
  @override
  SchedulerState build() => const SchedulerState();

  /// Atomic update — all fields change in one frame.
  /// No widget can rebuild with half-updated state.
  void update(SchedulerState Function(SchedulerState) transform) {
    state = transform(state);
  }

  // ── Convenience methods for common transitions ────────────────────────

  void pauseAt(String nodeId) => update((s) => s.copyWith(
        isPaused: true,
        activeNodeId: nodeId,
      ));

  void resumeFrom(String nodeId) => update((s) => s.copyWith(
        isPaused: false,
        activeNodeId: nodeId,
      ));

  void startChoice(String nodeId, String threadId) => update((s) => s.copyWith(
        waitingForChoice: true,
        isPaused: true,
        activeNodeId: nodeId,
        activeThreadId: threadId,
      ));

  void completeChoice(String nextNodeId) => update((s) => s.copyWith(
        waitingForChoice: false,
        isPaused: false,
        isSubmittingChoice: false,
        activeNodeId: nextNodeId,
      ));

  void startPuzzle(String nextNodeId) => update((s) => s.copyWith(
        waitingForPuzzle: true,
        isPaused: true,
        activeNodeId: nextNodeId,
      ));

  void completePuzzle() => update((s) => s.copyWith(
        waitingForPuzzle: false,
        isPaused: false,
      ));

  void switchThread(String threadId) => update((s) => s.copyWith(
        activeThreadId: threadId,
      ));

  void clearThread() => update((s) => s.copyWith(
        clearActiveThreadId: true,
      ));

  void setSubmitting(bool submitting) => update((s) => s.copyWith(
        isSubmittingChoice: submitting,
      ));
}

/// The one provider for all scheduler state.
/// Use .select() for individual fields in widgets.
final schedulerStateProvider =
    NotifierProvider<SchedulerStateNotifier, SchedulerState>(
  SchedulerStateNotifier.new,
);
