import 'dart:math';
import 'package:flutter/material.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/os/components/os_header.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  static const int size = 4;

  late List<int> tiles;
  int emptyIndex = 15;
  int moves = 0;

  @override
  void initState() {
    super.initState();
    _generateBoard();
  }

  void _generateBoard() {
    tiles = List.generate(size * size, (index) => index + 1);
    tiles[15] = 0;

    emptyIndex = 15;
    moves = 0;

    final rng = Random();
    for(int i = 0; i < 100; i++) {
        _performMove(_getValidMoves()[rng.nextInt(_getValidMoves().length)], checkWin: false);
    }
    setState(() {});
  }

  List<int> _getValidMoves() {
      List<int> validMoves = [];
      int r = emptyIndex ~/ size;
      int c = emptyIndex % size;

      if (r > 0) validMoves.add(emptyIndex - size); // Top
      if (r < size - 1) validMoves.add(emptyIndex + size); // Bottom
      if (c > 0) validMoves.add(emptyIndex - 1); // Left
      if (c < size - 1) validMoves.add(emptyIndex + 1); // Right

      return validMoves;
  }

  void _performMove(int index, {bool checkWin = true}) {
      setState(() {
          tiles[emptyIndex] = tiles[index];
          tiles[index] = 0;
          emptyIndex = index;
          if (checkWin) moves++;
      });

      if(checkWin) {
         _checkWin();
      }
  }

  void _handleTap(int index) {
      if (_getValidMoves().contains(index)) {
          _performMove(index);
      }
  }

  void _checkWin() {
    bool solved = true;

    for (int i = 0; i < size * size - 1; i++) {
        if (tiles[i] != i + 1) {
            solved = false;
            break;
        }
    }

    if (solved) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: DreadmoorColors.surfaceAlt,
          title: Text(
              "System Restored",
              style: DreadmoorTheme.headingStyle.copyWith(color: DreadmoorColors.accentCyan),
          ),
          content: Text(
              "Sequence successful. System access granted.",
              style: DreadmoorTheme.bodyStyle.copyWith(color: DreadmoorColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _generateBoard();
              },
              child: Text(
                  "Reboot",
                  style: DreadmoorTheme.bodyStyle.copyWith(color: DreadmoorColors.accentCyan),
              ),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Column(
        children: [
          const OSHeader(
              title: "SYSTEM OVERRIDE",
              subtitle: "MAINFRAME ACCESS",
              trailing: Icon(Icons.security, color: DreadmoorColors.accentRed, size: 20),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Align data fragments to restore sequence.",
                      style: DreadmoorTheme.bodyStyle.copyWith(
                        color: DreadmoorColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Puzzle Frame
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DreadmoorColors.surfaceAlt,
                        border: Border.all(color: DreadmoorColors.borderSubtle),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                            BoxShadow(
                                color: DreadmoorColors.glowCyan.withOpacity(0.05),
                                blurRadius: 20,
                                spreadRadius: 5,
                            )
                        ]
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final boardSize = constraints.maxWidth;
                          final tileSize = (boardSize - (size - 1) * 4) / size; // 4 is spacing

                          return SizedBox(
                            width: boardSize,
                            height: boardSize,
                            child: Stack(
                              children: List.generate(size * size, (i) {
                                final number = tiles[i];
                                if (number == 0) return const SizedBox();

                                // Calculate position based on current index in array
                                final r = i ~/ size;
                                final c = i % size;
                                final top = r * (tileSize + 4);
                                final left = c * (tileSize + 4);

                                final isValid = _getValidMoves().contains(i);

                                return AnimatedPositioned(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  top: top,
                                  left: left,
                                  width: tileSize,
                                  height: tileSize,
                                  child: GestureDetector(
                                    onTap: () => _handleTap(i),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      decoration: BoxDecoration(
                                        color: DreadmoorColors.surface,
                                        border: Border.all(
                                          color: isValid
                                            ? DreadmoorColors.accentCyan.withOpacity(0.5)
                                            : DreadmoorColors.borderSubtle,
                                          width: isValid ? 1.5 : 1.0,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: isValid ? [
                                          BoxShadow(
                                              color: DreadmoorColors.glowCyan.withOpacity(0.2),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                          )
                                        ] : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          number.toString().padLeft(2, '0'),
                                          style: DreadmoorTheme.headingStyle.copyWith(
                                            color: isValid ? DreadmoorColors.accentCyan : DreadmoorColors.textPrimary,
                                            fontSize: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        }
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Move counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                            onPressed: _generateBoard,
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                foregroundColor: DreadmoorColors.textMeta,
                            ),
                            child: Text(
                                "RESET",
                                style: DreadmoorTheme.bodyStyle.copyWith(color: DreadmoorColors.textMeta, fontSize: 12),
                            ),
                        ),
                        Row(
                          children: [
                            Text(
                              "MOVES: ",
                              style: DreadmoorTheme.headingStyle.copyWith(
                                color: DreadmoorColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              moves.toString().padLeft(3, '0'),
                              style: DreadmoorTheme.headingStyle.copyWith(
                                color: DreadmoorColors.accentCyan,
                                fontSize: 16,
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
          ),
        ],
      ),
    );
  }
}
