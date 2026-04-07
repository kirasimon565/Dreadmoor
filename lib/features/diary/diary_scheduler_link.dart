import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/features/diary/diary_controller.dart';

Future<bool> handleDiary(Ref ref, String word, String pageId) async {
  final controller = ref.read(diaryProvider.notifier);
  final state = await controller.dao.loadState(pageId);

  return state == null || !state.isCompleted;
}
