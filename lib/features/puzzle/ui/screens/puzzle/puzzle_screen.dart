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

  // 0 = empty, 1 = straight path, 2 = corner path
  late List<int> _gridTypes;
  // Rotation states: 0 = 0deg, 1 = 90deg, 2 = 180deg, 3 = 270deg
  late List<int> _gridRotations;
  // Target rotation required to "solve" the path segment
  late List<int> _targetRotations;

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
    final totalCells = gridSize * gridSize;
    _gridTypes = List.generate(totalCells, (index) => 0);
    _gridRotations = List.generate(totalCells, (index) => 0);
    _targetRotations = List.generate(totalCells, (index) => 0);
    _isSolved = false;
    _corruptionLevel = 87;

    final rng = Random();

    // Hardcode a start point and end point visually
    // 3 = Start Node, 4 = End Node
    _gridTypes[0] = 3;
    _gridTypes[totalCells - 1] = 4;
    _targetRotations[0] = 0;
    _targetRotations[totalCells - 1] = 0;

    // We create a mock "path" that the user needs to align
    // For simplicity, we just scatter pieces that have a specific correct rotation
    int nodesPlaced = 0;
    while (nodesPlaced < 12) {
      int idx = rng.nextInt(totalCells);
      if (_gridTypes[idx] == 0) {
        _gridTypes[idx] = rng.nextBool() ? 1 : 2; // Randomly straight or corner
        _targetRotations[idx] = rng.nextInt(4); // The correct orientation
        _gridRotations[idx] = (_targetRotations[idx] + rng.nextInt(3) + 1) % 4; // Scramble
        nodesPlaced++;
      }
    }
    setState(() {});
  }

  void _handleTap(int index) {
    if (_isSolved) return;

    // Only rotate straight and corner paths, not endpoints or empty space
    if (_gridTypes[index] == 1 || _gridTypes[index] == 2) {
      setState(() {
        _gridRotations[index] = (_gridRotations[index] + 1) % 4;
        _checkWin();
      });
    }
  }

  void _checkWin() {
    bool allAligned = true;
    for (int i = 0; i < _gridTypes.length; i++) {
      // Only check alignment for rotatable pieces
      if ((_gridTypes[i] == 1 || _gridTypes[i] == 2) && _gridRotations[i] != _targetRotations[i]) {
        // For straight pieces (type 1), 0deg and 180deg are visually identical,
        // same for 90 and 270. We account for this logic:
        if (_gridTypes[i] == 1) {
            if (_gridRotations[i] % 2 != _targetRotations[i] % 2) {
                allAligned = false;
                break;
            }
        } else {
            allAligned = false;
            break;
        }
      }
    }

    if (allAligned) {
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
            "SIGNAL RESTORED",
            style: DreadmoorTheme.headingStyle.copyWith(
              color: DreadmoorColors.accentCyan,
              letterSpacing: 2.0,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sensors, color: DreadmoorColors.accentCyan, size: 48),
              const SizedBox(height: 16),
              Text(
                "Data fragments successfully aligned.\nMedia file decrypted.",
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
                    "ALIGN DATA FRAGMENTS TO RECONNECT THE SIGNAL PATH AND DECRYPT MEDIA.",
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
                          final type = _gridTypes[index];
                          final rot = _gridRotations[index];

                          // Determine if this specific block is "correct"
                          bool isAligned = false;
                          if (type == 1) {
                              isAligned = rot % 2 == _targetRotations[index] % 2;
                          } else if (type == 2) {
                              isAligned = rot == _targetRotations[index];
                          }

                          final isEndpoint = type == 3 || type == 4;

                          Color bgColor = DreadmoorColors.surface;
                          Color borderColor = Colors.white.withOpacity(0.05);

                          if (type == 3) {
                             bgColor = DreadmoorColors.accentCyan.withOpacity(0.2);
                             borderColor = DreadmoorColors.accentCyan;
                          } else if (type == 4) {
                             bgColor = isAligned ? DreadmoorColors.accentCyan.withOpacity(0.2) : DreadmoorColors.accentRed.withOpacity(0.2);
                             borderColor = isAligned ? DreadmoorColors.accentCyan : DreadmoorColors.accentRed;
                          } else if (type != 0) {
                             bgColor = isAligned ? DreadmoorColors.accentCyan.withOpacity(0.15) : DreadmoorColors.surfaceAlt;
                             borderColor = isAligned ? DreadmoorColors.accentCyan : DreadmoorColors.accentRed.withOpacity(0.4);
                          }

                          return GestureDetector(
                            onTap: () => _handleTap(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: Border.all(
                                  color: borderColor,
                                  width: type != 0 ? 1.5 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(isEndpoint ? 8 : 4),
                              ),
                              child: type == 0
                                  ? Center(
                                      child: Text(
                                        "0x${(index * 3).toRadixString(16).padLeft(2, '0').toUpperCase()}",
                                        style: DreadmoorTheme.bodyStyle.copyWith(
                                          fontSize: 8,
                                          color: DreadmoorColors.textMeta.withOpacity(0.2),
                                        ),
                                      ),
                                    )
                                  : isEndpoint
                                      ? Center(
                                          child: Text(
                                            type == 3 ? "SRC" : "DST",
                                            style: DreadmoorTheme.bodyStyle.copyWith(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: type == 3 ? DreadmoorColors.accentCyan : (isAligned ? DreadmoorColors.accentCyan : DreadmoorColors.accentRed),
                                            ),
                                          ),
                                        )
                                      : AnimatedRotation(
                                          turns: rot * 0.25,
                                          duration: const Duration(milliseconds: 200),
                                          child: CustomPaint(
                                            painter: _PathPainter(type: type, color: isAligned ? DreadmoorColors.accentCyan : DreadmoorColors.accentRed),
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

class _PathPainter extends CustomPainter {
  final int type;
  final Color color;

  _PathPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    if (type == 1) {
      // Straight line
      canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    } else if (type == 2) {
      // Corner line (top to right)
      final path = Path()
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width / 2, size.height / 2)
        ..lineTo(size.width, size.height / 2);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}
