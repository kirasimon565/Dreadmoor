import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/features/diary/diary_controller.dart';
import 'package:dreadmoor/features/diary/diary_state.dart';

// keyboard_input.dart and letter_slot.dart imports removed —
// no longer used now that input is stepper-based.

class DiaryLockOverlay extends ConsumerStatefulWidget {
  final String pageId;
  final String targetWord;

  const DiaryLockOverlay({
    super.key,
    required this.pageId,
    required this.targetWord,
  });

  @override
  ConsumerState<DiaryLockOverlay> createState() => _DiaryLockOverlayState();
}

class _DiaryLockOverlayState extends ConsumerState<DiaryLockOverlay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(diaryProvider.notifier).init(widget.targetWord, widget.pageId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Single listener: when the diary is unlocked, pop the overlay and
    // signal the scheduler to resume story progression.
    // The scheduler already stored node.nextNodeId before pausing, so
    // completePuzzle() → resume() → _executeNode(nextNodeId) works correctly.
    ref.listen<DiaryState?>(diaryProvider, (previous, next) {
      if (next?.isUnlocked == true) {
        if (context.mounted) {
          ref.read(globalSchedulerProvider).completePuzzle();
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    });

    final state      = ref.watch(diaryProvider);
    final wordLength = state?.targetWord.length ?? 4;

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'LOCKED PAGE',
              style: TextStyle(
                color:         Colors.white,
                fontSize:      24,
                letterSpacing: 4,
                fontWeight:    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter the passcode.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),

            // ── STEPPER INPUT ─────────────────────────────────────────
            Wrap(
              spacing:       12,
              runSpacing:    16,
              alignment:     WrapAlignment.center,
              children: List.generate(wordLength, (index) {
                return LetterStepper(index: index);
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── LETTER STEPPER ────────────────────────────────────────────────────────────

class LetterStepper extends ConsumerWidget {
  final int index;

  const LetterStepper({super.key, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state   = ref.watch(diaryProvider);
    final letters = state?.enteredLetters ?? [];

    final currentLetter = (index < letters.length ? letters[index] : null) ?? 'A';

    String next(String l) {
      final code = l.codeUnitAt(0);
      return String.fromCharCode(code == 90 ? 65 : code + 1);
    }

    String prev(String l) {
      final code = l.codeUnitAt(0);
      return String.fromCharCode(code == 65 ? 90 : code - 1);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
          onPressed: () {
            ref.read(diaryProvider.notifier)
                .enterLetter(index, next(currentLetter));
          },
        ),

        Container(
          width:     60,
          height:    60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:        const Color(0xFFF0EAD6),
            borderRadius: BorderRadius.circular(8),
            border:       Border.all(color: Colors.black26),
          ),
          child: Text(
            currentLetter,
            style: const TextStyle(
              fontSize:   24,
              fontWeight: FontWeight.bold,
              color:      Colors.black87,
            ),
          ),
        ),

        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () {
            ref.read(diaryProvider.notifier)
                .enterLetter(index, prev(currentLetter));
          },
        ),
      ],
    );
  }
}
