import 'dart:math';
import 'dart:async';
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
  static const int gridSize = 5;

  // Grid state: 0 = empty, 1 = node, 2 = connection path
  late List<int> _grid;
  late List<bool> _activeNodes;

  bool _isSolved = false;
  int _corruptionLevel = 87; // visual fluff
  Timer? _corruptionTimer;

  @override
  void initState() {
    super.initState();
    _generateDataGrid();

    _corruptionTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted && !_isSolved) {
        setState(() {
          _corruptionLevel = max(40, _corruptionLevel - Random().nextInt(5) + 2);
        });
      }
    });
  }

  @override
  void dispose() {
    _corruptionTimer?.cancel();
    super.dispose();
  }

  void _generateDataGrid() {
    _grid = List.generate(gridSize * gridSize, (index) => 0);
    _activeNodes = List.generate(gridSize * gridSize, (index) => false);
    _isSolved = false;
    _corruptionLevel = 87;

    // Place some "corrupted data nodes" that need to be activated by tapping
    final rng = Random();
    int nodesPlaced = 0;
    while (nodesPlaced < 7) {
      int idx = rng.nextInt(gridSize * gridSize);
      if (_grid[idx] == 0) {
        _grid[idx] = 1; // Node
        nodesPlaced++;
      }
    }
    setState(() {});
  }

  void _handleTap(int index) {
    if (_isSolved) return;

    setState(() {
      if (_grid[index] == 1) {
        // Toggle node activation
        _activeNodes[index] = !_activeNodes[index];
        _checkWin();
      }
    });
  }

  void _checkWin() {
    bool allNodesActive = true;
    for (int i = 0; i < _grid.length; i++) {
      if (_grid[i] == 1 && !_activeNodes[i]) {
        allNodesActive = false;
        break;
      }
    }

    if (allNodesActive) {
      setState(() {
        _isSolved = true;
        _corruptionLevel = 0;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: DreadmoorColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: DreadmoorColors.accentCyan, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text(
            "ACCESS GRANTED",
            style: DreadmoorTheme.headingStyle.copyWith(
              color: DreadmoorColors.accentCyan,
              letterSpacing: 2.0,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_open, color: DreadmoorColors.accentCyan, size: 48),
              const SizedBox(height: 16),
              Text(
                "Data fragments successfully recovered.\nSystem integrity restored.",
                style: DreadmoorTheme.bodyStyle.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _generateDataGrid(); // Reset for now until tied to story
                },
                child: Text(
                  "CLOSE CONNECTION",
                  style: DreadmoorTheme.bodyStyle.copyWith(
                    color: DreadmoorColors.accentCyan,
                    letterSpacing: 1.5,
                  ),
                ),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "STATUS",
                            style: DreadmoorTheme.bodyStyle.copyWith(
                              color: DreadmoorColors.textMeta,
                              fontSize: 10,
                              letterSpacing: 2.0,
                            ),
                          ),
                          Text(
                            _isSolved ? "RESTORED" : "CORRUPTED",
                            style: DreadmoorTheme.headingStyle.copyWith(
                              color: _isSolved ? DreadmoorColors.accentCyan : DreadmoorColors.accentRed,
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
                            "DATA LOSS",
                            style: DreadmoorTheme.bodyStyle.copyWith(
                              color: DreadmoorColors.textMeta,
                              fontSize: 10,
                              letterSpacing: 2.0,
                            ),
                          ),
                          Text(
                            "$_corruptionLevel%",
                            style: DreadmoorTheme.headingStyle.copyWith(
                              color: _isSolved ? DreadmoorColors.accentCyan : DreadmoorColors.textSecondary,
                              fontSize: 14,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Instructions
                  Text(
                    "INITIALIZE ALL CORRUPTED SECTORS TO RECOVER DATA FRAGMENT.",
                    style: DreadmoorTheme.bodyStyle.copyWith(
                      color: DreadmoorColors.textSecondary,
                      fontSize: 11,
                      letterSpacing: 1.0,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Data Grid Puzzle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DreadmoorColors.surfaceAlt,
                      border: Border.all(
                        color: _isSolved ? DreadmoorColors.accentCyan : DreadmoorColors.borderSubtle,
                        width: _isSolved ? 2.0 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isSolved ? [
                        BoxShadow(
                          color: DreadmoorColors.glowCyan.withOpacity(0.2),
                          blurRadius: 24,
                          spreadRadius: 2,
                        )
                      ] : [],
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridSize,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: gridSize * gridSize,
                        itemBuilder: (context, index) {
                          final isNode = _grid[index] == 1;
                          final isActive = _activeNodes[index];

                          return GestureDetector(
                            onTap: () => _handleTap(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: isNode
                                    ? (isActive ? DreadmoorColors.accentCyan.withOpacity(0.2) : DreadmoorColors.accentRed.withOpacity(0.1))
                                    : DreadmoorColors.surface,
                                border: Border.all(
                                  color: isNode
                                      ? (isActive ? DreadmoorColors.accentCyan : DreadmoorColors.accentRed.withOpacity(0.5))
                                      : Colors.white.withOpacity(0.05),
                                  width: isNode ? 2.0 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(isNode ? 8 : 4),
                                boxShadow: isNode && isActive ? [
                                  BoxShadow(
                                    color: DreadmoorColors.accentCyan.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ] : [],
                              ),
                              child: Center(
                                child: isNode
                                    ? Icon(
                                        isActive ? Icons.check : Icons.warning_amber_rounded,
                                        color: isActive ? DreadmoorColors.accentCyan : DreadmoorColors.accentRed,
                                        size: 20,
                                      )
                                    : Text(
                                        "0x${(index * 3).toRadixString(16).padLeft(2, '0').toUpperCase()}",
                                        style: DreadmoorTheme.bodyStyle.copyWith(
                                          fontSize: 9,
                                          color: DreadmoorColors.textMeta.withOpacity(0.3),
                                        ),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
