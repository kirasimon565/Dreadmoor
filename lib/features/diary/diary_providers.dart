import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/features/diary/models/diary_page_meta.dart';
import 'package:dreadmoor/features/diary/persistence/diary_dao.dart';
import 'package:dreadmoor/features/diary/diary_state.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

final diaryPagesProvider = FutureProvider.autoDispose<List<DiaryPageMeta>>((ref) async {
  final episodeId = ref.watch(currentEpisodeIdProvider) ?? 'ep01';
  final List<DiaryPageMeta> pages = [];

  // Sequentially try loading pages page_01.json, page_02.json, etc.
  int i = 1;
  while (true) {
    final pageNumStr = i.toString().padLeft(2, '0');
    final path = 'assets/story/$episodeId/diary/page_$pageNumStr.json';

    try {
      final jsonStr = await rootBundle.loadString(path);
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;

      pages.add(DiaryPageMeta.fromJson(jsonMap));
      i++;
    } catch (e) {
      // File not found, end of list
      break;
    }
  }

  return pages;
});

final diaryPageStateProvider = FutureProvider.family<DiaryState?, String>((ref, pageId) async {
  final db = ref.watch(databaseProvider);
  final dao = DiaryDao(db);
  return await dao.loadState(pageId);
});
