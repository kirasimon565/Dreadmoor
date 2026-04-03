import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/features/diary/diary_controller.dart';
import 'widgets/diary_tile.dart';
import 'diary_page_view.dart';
import 'diary_lock_overlay.dart';

class DiaryScreen extends ConsumerStatefulWidget {
  final String targetWord;

  const DiaryScreen({super.key, required this.targetWord});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initDiary();
  }

  Future<void> _initDiary() async {
    await ref.read(diaryProvider.notifier).init(widget.targetWord);
    setState(() {
      _initialized = true;
    });
  }

  void _openPage(BuildContext context, int pageNumber, String date, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryPageView(
          pageNumber: pageNumber,
          dateStr: date,
          content: content,
        ),
      ),
    );
  }

  void _openLockedPage(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) => const DiaryLockOverlay(),
        transitionsBuilder: (___, Animation<double> animation, ____, Widget child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    ).then((_) {
      // Re-evaluate state when coming back from the overlay.
      // If completed, we should pop the DiaryScreen to return to the story.
      final state = ref.read(diaryProvider);
      if (state != null && state.isCompleted) {
        if (mounted) {
           Navigator.pop(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diaryProvider);

    if (!_initialized || state == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFE0E0E0),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2D1B14))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  height: 60,
                  color: const Color(0xFF2D1B14),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Center(
                        child: Text(
                          "Diary",
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "A collection of my experiences...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  delegate: SliverChildListDelegate([
                    DiaryPageTile(
                      pageNumber: 9,
                      dateStr: "Oct 12",
                      onTap: () => _openPage(context, 9, "Oct 12", "Things have been quiet lately. Too quiet. I can't shake the feeling that someone is watching me, but maybe I'm just being paranoid."),
                    ),
                    DiaryPageTile(
                      pageNumber: 10,
                      dateStr: "Oct 14",
                      onTap: () => _openPage(context, 10, "Oct 14", "I found something strange near the woods today. It looked like an old pendant. I'm going to look into it tomorrow."),
                    ),
                    DiaryPageTile(
                      pageNumber: 11,
                      dateStr: "Oct 18",
                      onTap: () => _openPage(context, 11, "Oct 18", "They are lying. All of them. The timeline doesn't make sense. I need to keep digging."),
                    ),
                    DiaryPageTile(
                      pageNumber: 12,
                      dateStr: "Oct 21",
                      isLocked: !state.isUnlocked,
                      onTap: () {
                        if (state.isUnlocked) {
                          _openPage(context, 12, "Oct 21", "The passcode was the key. Now everything is starting to fall into place. The truth is much darker than I thought.");
                        } else {
                          _openLockedPage(context);
                        }
                      },
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
