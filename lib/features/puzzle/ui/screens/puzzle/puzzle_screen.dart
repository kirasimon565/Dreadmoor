import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/os/components/os_header.dart';
import 'package:dreadmoor/features/puzzle/puzzle_state.dart';
import 'package:dreadmoor/core/scheduler/global_scheduler.dart';
import 'package:dreadmoor/core/state/game_state.dart';

class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({super.key});

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  bool _isGlitching = false;

  void _handleWin() {
    setState(() => _isGlitching = true);
    HapticFeedback.heavyImpact();

    // Simulate glitch and restore access
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isGlitching = false);
        ref.read(globalSchedulerProvider).completePuzzle();
        // Return to messenger automatically to continue the story
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = ref.watch(puzzleProvider);
    final notifier = ref.read(puzzleProvider.notifier);

    // Watch for state changes to trigger win animation
    ref.listen<PuzzleState>(puzzleProvider, (previous, next) {
      if (previous?.isSolved != true && next.isSolved) {
        _handleWin();
      }
    });

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const OSHeader(
                  title: "SYSTEM OVERRIDE",
                  subtitle: "MAINFRAME ACCESS",
                  trailing: Icon(Icons.security, color: DreadmoorColors.accentRed, size: 20),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // --- 1. HEADER (Status) ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "STATUS:",
                                  style: DreadmoorTheme.bodyStyle.copyWith(
                                    color: DreadmoorColors.textMeta,
                                    fontSize: 10,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                Text(
                                  puzzle.isSolved ? "RESTORED" : "CORRUPTED",
                                  style: DreadmoorTheme.headingStyle.copyWith(
                                    color: puzzle.isSolved ? DreadmoorColors.accentCyan : DreadmoorColors.accentRed,
                                    fontSize: 14,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "DATA LOSS:",
                                  style: DreadmoorTheme.bodyStyle.copyWith(
                                    color: DreadmoorColors.textMeta,
                                    fontSize: 10,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                Text(
                                  puzzle.isSolved ? "0%" : "84%",
                                  style: DreadmoorTheme.headingStyle.copyWith(
                                    color: puzzle.isSolved ? DreadmoorColors.accentCyan : DreadmoorColors.textSecondary,
                                    fontSize: 14,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // --- 2. TARGET PATTERN ---
                        Column(
                          children: [
                            Text(
                              "[ TARGET SIGNAL ]",
                              style: DreadmoorTheme.bodyStyle.copyWith(
                                color: DreadmoorColors.textMeta,
                                fontSize: 10,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildMiniBoard(puzzle.targetBoard, puzzle.gridSize),
                          ],
                        ),

                        // --- 3. PUZZLE BOARD ---
                        GestureDetector(
                          onDoubleTap: notifier.undo, // Two-finger tap equivalent conceptually (easy fallback)
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: DreadmoorColors.surfaceAlt,
                                border: Border.all(
                                  color: puzzle.isSolved ? DreadmoorColors.accentCyan : DreadmoorColors.borderSubtle,
                                  width: puzzle.isSolved ? 2.0 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: puzzle.isSolved || _isGlitching ? [
                                  BoxShadow(
                                    color: DreadmoorColors.glowCyan.withOpacity(0.3),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  )
                                ] : [],
                              ),
                              child: _buildInteractiveBoard(puzzle, notifier),
                            ),
                          ),
                        ),

                        // --- 4. CONTROLS ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "MOVES: ${puzzle.moves}",
                              style: DreadmoorTheme.headingStyle.copyWith(
                                color: DreadmoorColors.textSecondary,
                                fontSize: 12,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: puzzle.history.isEmpty ? null : notifier.undo,
                                  child: Text(
                                    "[ UNDO ]",
                                    style: DreadmoorTheme.bodyStyle.copyWith(
                                      color: puzzle.history.isEmpty ? DreadmoorColors.textDisabled : DreadmoorColors.textSecondary,
                                      fontSize: 12,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: notifier.reset,
                                  child: Text(
                                    "[ RESET ]",
                                    style: DreadmoorTheme.bodyStyle.copyWith(
                                      color: DreadmoorColors.textSecondary,
                                      fontSize: 12,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Glitch Overlay on Win
          if (_isGlitching)
            Positioned.fill(
              child: Container(
                color: DreadmoorColors.accentCyan.withOpacity(0.2),
                child: Center(
                  child: Text(
                    "ACCESS RESTORED",
                    style: DreadmoorTheme.headingStyle.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                      letterSpacing: 4.0,
                      shadows: [
                        BoxShadow(color: DreadmoorColors.accentCyan, blurRadius: 20)
                      ]
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniBoard(List<int> target, int size) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: DreadmoorColors.surface,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: size,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: size * size,
        itemBuilder: (context, index) {
          final val = target[index];
          return _buildTileVisual(val, true);
        },
      ),
    );
  }

  Widget _buildInteractiveBoard(PuzzleState puzzle, PuzzleNotifier notifier) {
    final size = puzzle.gridSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth;
        final spacing = 4.0;
        final tileSize = (boardSize - (size - 1) * spacing) / size;

        return Stack(
          children: [
            // Base layer: The physical tiles
            ...List.generate(size * size, (i) {
              // Find where tile 'i' is currently located on the board
              final currentIndex = puzzle.currentBoard.indexOf(i);
              final r = currentIndex ~/ size;
              final c = currentIndex % size;

              final top = r * (tileSize + spacing);
              final left = c * (tileSize + spacing);

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                top: top,
                left: left,
                width: tileSize,
                height: tileSize,
                child: _buildTileVisual(i, false),
              );
            }),

            // Interaction layer: 2x2 touch targets overlaying the intersections
            ...List.generate((size - 1) * (size - 1), (i) {
              final r = i ~/ (size - 1);
              final c = i % (size - 1);

              // The pivot is the top-left tile of this 2x2 block
              final pivotIndex = r * size + c;

              final top = r * (tileSize + spacing) + (tileSize / 2);
              final left = c * (tileSize + spacing) + (tileSize / 2);

              final isPreview = puzzle.previewPivotIndex == pivotIndex;

              return Positioned(
                top: top,
                left: left,
                width: tileSize + spacing,
                height: tileSize + spacing,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    notifier.rotateBlock(pivotIndex);
                  },
                  onLongPressStart: (_) {
                    HapticFeedback.selectionClick();
                    notifier.setPreview(pivotIndex);
                  },
                  onLongPressEnd: (_) {
                    notifier.setPreview(null);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isPreview ? DreadmoorColors.accentCyan.withOpacity(0.1) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    // Invisible hit box in the exact center of 4 tiles
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isPreview ? DreadmoorColors.accentCyan.withOpacity(0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      }
    );
  }

  // Visual representation of a "data fragment"
  Widget _buildTileVisual(int value, bool isMini) {
    // Generate a fixed pattern based on the value so it looks like broken media
    final rng = Random(value * 1234);
    final isRed = rng.nextBool();
    final type = rng.nextInt(3); // 0 = file, 1 = binary, 2 = image fragment

    return Container(
      decoration: BoxDecoration(
        color: DreadmoorColors.surfaceAlt,
        borderRadius: BorderRadius.circular(isMini ? 2 : 4),
        border: Border.all(
          color: isRed ? DreadmoorColors.accentRed.withOpacity(0.2) : DreadmoorColors.borderSubtle,
        ),
      ),
      child: Center(
        child: type == 0
          ? Icon(Icons.description, size: isMini ? 12 : 24, color: Colors.white24)
          : type == 1
            ? Text(
                "0x${value.toRadixString(16).padLeft(2, '0')}",
                style: DreadmoorTheme.bodyStyle.copyWith(
                  fontSize: isMini ? 8 : 12,
                  color: Colors.white38,
                ),
              )
            : Icon(Icons.fingerprint, size: isMini ? 12 : 24, color: Colors.white24),
      ),
    );
  }
}
