import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/features/diary/diary_controller.dart';
import 'widgets/letter_slot.dart';
import 'widgets/keyboard_input.dart';

class DiaryLockOverlay extends ConsumerStatefulWidget {
  const DiaryLockOverlay({super.key});

  @override
  ConsumerState<DiaryLockOverlay> createState() => _DiaryLockOverlayState();
}

class _DiaryLockOverlayState extends ConsumerState<DiaryLockOverlay> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diaryProvider);

    // Provide safe defaults if state happens to be null
    final wordLength = state?.targetWord.length ?? 4;
    final letters = state?.enteredLetters ?? List.filled(wordLength, null);

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
              "LOCKED PAGE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Enter the passcode.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(wordLength, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: LetterSlot(
                    letter: letters[index],
                    isSelected: _selectedIndex == index,
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 60),
            KeyboardInput(
              onLetterTap: (letter) async {
                await ref.read(diaryProvider.notifier).enterLetter(_selectedIndex, letter);

                // Read fresh state after entering a letter to check completion immediately
                final newState = ref.read(diaryProvider);
                if (newState != null && newState.isCompleted) {
                   if (mounted) Navigator.pop(context); // Close the modal
                } else if (_selectedIndex < wordLength - 1) {
                   setState(() {
                     _selectedIndex++;
                   });
                }
              },
              onBackspace: () async {
                ref.read(diaryProvider.notifier).enterLetter(_selectedIndex, null);
                if (_selectedIndex > 0) {
                  setState(() {
                    _selectedIndex--;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
