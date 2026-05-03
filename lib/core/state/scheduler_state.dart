import 'package:flutter_riverpod/flutter_riverpod.dart';

// Single state object instead of five separate providers
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
      activeNodeId: clearActiveNodeId ? null : (activeNodeId ?? this.activeNodeId),
      activeThreadId: clearActiveThreadId ? null : (activeThreadId ?? this.activeThreadId),
    );
  }
}

class SchedulerStateNotifier extends Notifier<SchedulerState> {
  @override
  SchedulerState build() => const SchedulerState();

  // Atomic: all fields update in ONE frame. No widget rebuilds between calls.
  void update(SchedulerState Function(SchedulerState) transform) {
    state = transform(state);
  }

  // ── Convenience methods ──────────────────────────────────────────────

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

  void setSubmitting(bool submitting) => update((s) => s.copyWith(
        isSubmittingChoice: submitting,
      ));
}

final schedulerStateProvider =
    NotifierProvider<SchedulerStateNotifier, SchedulerState>(
  SchedulerStateNotifier.new,
);

// Convenience selectors for widgets that only need one field
final activeThreadIdProvider = Provider<String?>((ref) {
  return ref.watch(schedulerStateProvider.select((s) => s.activeThreadId));
});

final isSchedulerPausedProvider = Provider<bool>((ref) {
  return ref.watch(schedulerStateProvider.select((s) => s.isPaused));
});

final waitingForChoiceProvider = Provider<bool>((ref) {
  return ref.watch(schedulerStateProvider.select((s) => s.waitingForChoice));
});

final waitingForPuzzleProvider = Provider<bool>((ref) {
  return ref.watch(schedulerStateProvider.select((s) => s.waitingForPuzzle));
});

final activeNodeIdProvider = Provider<String?>((ref) {
  return ref.watch(schedulerStateProvider.select((s) => s.activeNodeId));
});
