import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/features/diary/diary_state.dart';
import 'package:dreadmoor/features/diary/persistence/diary_dao.dart';

final diaryProvider = NotifierProvider<DiaryController, DiaryState?>(DiaryController.new);

class DiaryController extends Notifier<DiaryState?> {
  late DiaryDao _dao;

  @override
  DiaryState? build() {
    _dao = DiaryDao(ref.read(databaseProvider));
    // Provide a default state to avoid null issues in the UI until init completes.
    // However, it will realistically be initialized by the scheduler.
    return null;
  }

  Future<void> init(String word) async {
    final savedState = await _dao.loadState();

    if (savedState != null) {
      if (savedState.targetWord.toUpperCase() != word.toUpperCase()) {
        // Word mismatch - reset
        final newState = DiaryState(
          targetWord: word.toUpperCase(),
          enteredLetters: List.filled(word.length, null),
          isUnlocked: false,
          isCompleted: false,
        );
        state = newState;
        await _dao.saveState(newState);
      } else {
        state = savedState;
      }
    } else {
      // First time
      final newState = DiaryState(
        targetWord: word.toUpperCase(),
        enteredLetters: List.filled(word.length, null),
        isUnlocked: false,
        isCompleted: false,
      );
      state = newState;
      await _dao.saveState(newState);
    }
  }

  Future<void> enterLetter(int index, String? letter) async {
    if (state == null || state!.isUnlocked) return;

    final newLetters = List<String?>.from(state!.enteredLetters);
    newLetters[index] = letter?.toUpperCase();

    final newState = state!.copyWith(enteredLetters: newLetters);
    state = newState;
    await _dao.saveState(newState);

    _checkCompletion();
  }

  void _checkCompletion() {
    if (state == null) return;

    final enteredStr = state!.enteredLetters.map((l) => l ?? '').join();
    if (enteredStr == state!.targetWord) {
      _unlockDiary();
    }
  }

  Future<void> _unlockDiary() async {
    if (state == null) return;

    final newState = state!.copyWith(isUnlocked: true, isCompleted: true);
    state = newState;
    await _dao.saveState(newState);

    // Notify scheduler
    ref.read(globalSchedulerProvider).completePuzzle();
  }
}
