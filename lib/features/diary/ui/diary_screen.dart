import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/features/diary/diary_controller.dart';
import 'widgets/diary_tile.dart';
import 'diary_page_view.dart';
import 'diary_lock_overlay.dart';

class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diaryProvider);

    if (state == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFE0E0E0),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2D1B14))),
      );
    }

    if (!state.isUnlocked) {
      return const DiaryLockedView();
    }

    // Pass the appropriate text for the unlocked page view
    return const DiaryPageView(
      pageNumber: 12,
      dateStr: "Oct 21",
      content: "The passcode was the key. Now everything is starting to fall into place. The truth is much darker than I thought.",
    );
  }
}

class DiaryLockedView extends StatelessWidget {
  const DiaryLockedView({super.key});

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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1B14),
        title: const Text("Diary"),
        automaticallyImplyLeading: false, // OS handles back/nav
      ),
      body: Center(
        child: GestureDetector(
          onTap: () => _openLockedPage(context),
          child: Container(
            width: 200,
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EAD6),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                )
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.lock,
                size: 64,
                color: Color(0xFF2D1B14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
