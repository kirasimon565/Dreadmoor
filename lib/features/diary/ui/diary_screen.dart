import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/features/diary/models/diary_page_meta.dart';
import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/features/diary/diary_providers.dart';
import 'widgets/diary_tile.dart';
import 'diary_page_view.dart';
import 'diary_lock_overlay.dart';

class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(diaryPagesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1B14),
        title: const Text("Diary", style: TextStyle(fontFamily: 'serif', color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            ref.read(activeAppProvider.notifier).setApp(PhoneApp.messenger);
          },
        ),
      ),
      body: pagesAsync.when(
        data: (pages) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "A collection of my experiences, thoughts, and secrets.\nEvery page is safe guarded by a riddle.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'serif', fontSize: 16, color: Colors.black87),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    final pageMeta = pages[index];
                    return _DiaryGridItem(meta: pageMeta);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2D1B14))),
        error: (err, st) => Center(child: Text('Error loading diary: $err')),
      ),
    );
  }
}

class _DiaryGridItem extends ConsumerWidget {
  final DiaryPageMeta meta;

  const _DiaryGridItem({required this.meta});

  void _openLockedPage(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) => DiaryLockOverlay(
          pageId: meta.id,
          targetWord: meta.word,
        ),
        transitionsBuilder: (___, Animation<double> animation, ____, Widget child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  void _openUnlockedPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryPageView(
          pageId: meta.id,
          pageNumber: meta.page,
          dateStr: "Entry ${meta.page}",
          contentList: meta.content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(diaryPageStateProvider(meta.id));

    return stateAsync.when(
      data: (state) {
        final isUnlocked = state?.isUnlocked == true;

        return DiaryPageTile(
          pageNumber: meta.page,
          dateStr: isUnlocked ? "Entry ${meta.page}" : "Locked",
          isLocked: !isUnlocked,
          onTap: () {
            if (isUnlocked) {
              _openUnlockedPage(context);
            } else {
              _openLockedPage(context);
            }
          },
        );
      },
      loading: () => const Card(
        color: Color(0xFFF0EAD6),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF2D1B14))),
      ),
      error: (_, __) => const Card(
        color: Colors.redAccent,
        child: Center(child: Icon(Icons.error)),
      ),
    );
  }
}
