import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/features/diary/diary_state.dart';
import 'package:dreadmoor/features/diary/persistence/diary_dao.dart';

final diaryProvider = NotifierProvider<DiaryController, DiaryState?>(DiaryController.new);

class DiaryController extends Notifier<DiaryState?> {
  late DiaryDao _dao;

  DiaryDao get dao => _dao;

  @override
  DiaryState? build() {
    _dao = DiaryDao(ref.read(databaseProvider));
    return null;
  }

  Future<void> init(String word, String pageId) async {
    final saved = await _dao.loadState(pageId);

    if (saved == null || saved.targetWord != word || saved.pageId != pageId) {
      final newState = DiaryState.initial(word, pageId);
      state = newState;
      await _dao.saveState(newState);
      return;
    }

    state = saved;
  }

  Future<void> enterLetter(int index, String? letter) async {
    // ✅ FIX 1: use isCompleted instead of isUnlocked
    if (state == null || state!.isCompleted) return;

    final input = letter?.trim().toUpperCase();

    final newLetters = List<String?>.from(state!.enteredLetters);
    newLetters[index] = input;

    final newState = state!.copyWith(enteredLetters: newLetters);
    state = newState;
    await _dao.saveState(newState);

    _checkCompletion();
  }

  void _checkCompletion() {
    if (state == null) return;

    // ✅ FIX 2: normalize input and compare safely
    final enteredStr = state!.enteredLetters
        .map((l) => (l ?? '').trim().toUpperCase())
        .join();

    final target = state!.targetWord.trim().toUpperCase();

    print("ENTERED: '$enteredStr'");
    print("TARGET:  '$target'");

    if (enteredStr.length != target.length) return;

    if (enteredStr == target) {
      _unlockDiary();
    }
  }

  Future<void> _unlockDiary() async {
    final current = state;
    if (current == null || current.isCompleted) return;

    final newState = current.copyWith(
      isUnlocked: true,
      isCompleted: true,
    );

    state = newState;

    await _dao.saveState(newState);

    ref.read(globalSchedulerProvider).completePuzzle();
  }
}
