import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> with SingleTickerProviderStateMixin {
  bool _started = false;
  bool _isSolved = false;
  
  @override
  Widget build(BuildContext context) {
    final puzzle = ref.watch(puzzleProvider);
    final notifier = ref.read(puzzleProvider.notifier);

    ref.listen<PuzzleState>(puzzleProvider, (prev, next) {
      if (prev?.isSolved != true && next.isSolved) {
        setState(() => _isSolved = true);
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            ref.read(globalSchedulerProvider).completePuzzle();
            Navigator.of(context).pop();
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF080A0C), // Deeper tactical black
      body: Stack(
        children: [
          // Background Grid Texture
          Positioned.fill(child: _buildBackgroundGrid()),

          SafeArea(
            child: Column(
              children: [
                const OSHeader(title: "RESTRICTED", subtitle: "SIGNAL_DECRYPT_V.4"),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: !_started ? _buildEntryGate() : _buildActiveTerminal(puzzle, notifier),
                  ),
                ),
              ],
            ),
          ),

          if (_isSolved) _buildSolvedOverlay(),
        ],
      ),
    );
  }

  // --- ENTRY GATE (The "Mission" Briefing) ---

  Widget _buildEntryGate() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security_rounded, color: DreadmoorColors.investigatorCyan, size: 48),
          const SizedBox(height: 24),
          Text(
            "INTERCEPTED_FRAGMENT.DAT",
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          Text(
            "Phase alignment required to restore bit-stream integrity. Rotate signal blocks to match the target frequency.",
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 40),
          _buildTacticalButton("INITIATE_DECRYPT", () => setState(() => _started = true)),
        ],
      ),
    );
  }

  // --- ACTIVE TERMINAL ---

  Widget _buildActiveTerminal(PuzzleState puzzle, PuzzleNotifier notifier) {
    return Column(
      children: [
        _buildTopReadout(puzzle),
        const Spacer(),
        _buildTargetReference(puzzle),
        const SizedBox(height: 30),
        _buildMainSignalBoard(puzzle, notifier),
        const Spacer(),
        _buildBottomControls(puzzle, notifier),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTopReadout(PuzzleState puzzle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _readoutLabel("BIT_FLIPS", "${puzzle.moves}"),
          _readoutLabel("SYNC_RATE", puzzle.isSolved ? "100%" : "24.8%"),
          _readoutLabel("CORE", "ALPHA_9"),
        ],
      ),
    );
  }

  Widget _buildTargetReference(PuzzleState puzzle) {
    return Column(
      children: [
        Text("TARGET_SIGNAL_MATRIX", style: GoogleFonts.spaceGrotesk(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border.all(color: Colors.white10), color: Colors.white.withOpacity(0.02)),
          child: SizedBox(
            width: 80,
            height: 80,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: puzzle.gridSize),
              itemCount: puzzle.gridSize * puzzle.gridSize,
              itemBuilder: (_, i) => _buildTile(puzzle.targetBoard[i], true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainSignalBoard(PuzzleState puzzle, PuzzleNotifier notifier) {
    final size = puzzle.gridSize;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(30),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: DreadmoorColors.investigatorCyan.withOpacity(0.3), width: 2),
          boxShadow: [BoxShadow(color: DreadmoorColors.investigatorCyan.withOpacity(0.05), blurRadius: 40)],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tileSize = (constraints.maxWidth - (size - 1) * 2) / size;
            return Stack(
              children: [
                // Tiles
                ...List.generate(size * size, (i) {
                  final currentIndex = puzzle.currentBoard.indexOf(i);
                  final r = currentIndex ~/ size;
                  final c = currentIndex % size;
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuart,
                    top: r * (tileSize + 2),
                    left: c * (tileSize + 2),
                    width: tileSize,
                    height: tileSize,
                    child: _buildTile(i, false),
                  );
                }),
                // Invisible Rotation Pivots
                ...List.generate((size - 1) * (size - 1), (i) {
                  final r = i ~/ (size - 1);
                  final c = i % (size - 1);
                  return Positioned(
                    top: r * (tileSize + 2) + tileSize / 2,
                    left: c * (tileSize + 2) + tileSize / 2,
                    width: tileSize,
                    height: tileSize,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        notifier.rotateBlock(r * size + c);
                      },
                      highlightColor: DreadmoorColors.investigatorCyan.withOpacity(0.1),
                      child: Center(
                        child: Container(
                          width: 4, height: 4, 
                          decoration: BoxDecoration(color: DreadmoorColors.investigatorCyan.withOpacity(0.5), shape: BoxShape.circle)
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- TILE VISUALS (Hex Code Style) ---

  Widget _buildTile(int id, bool mini) {
    // Generate a pseudo-random hex fragment based on ID
    final hexCodes = ["0x4F", "0xA2", "0x1B", "0xEE", "0x9D", "0x33", "0x74", "0xBC", "0x01", "0x88", "0x56", "0xCA", "0xD1", "0xFF", "0x22", "0x3B"];
    final hex = hexCodes[id % hexCodes.length];

    return Container(
      decoration: BoxDecoration(
        color: mini ? Colors.white10 : const Color(0xFF12161A),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
      ),
      child: Center(
        child: Text(
          hex,
          style: GoogleFonts.firaCode(
            fontSize: mini ? 8 : 16,
            fontWeight: FontWeight.bold,
            color: mini ? Colors.white24 : DreadmoorColors.investigatorCyan.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _readoutLabel(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
        Text(val, style: GoogleFonts.firaCode(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTacticalButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(border: Border.all(color: DreadmoorColors.investigatorCyan)),
        child: Center(child: Text(label, style: GoogleFonts.spaceGrotesk(color: DreadmoorColors.investigatorCyan, fontWeight: FontWeight.bold, letterSpacing: 4))),
      ),
    );
  }

  Widget _buildBottomControls(PuzzleState puzzle, PuzzleNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _smallAction("UNDO", notifier.undo),
          _smallAction("RESET", notifier.reset),
          _smallAction("EXIT", () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _smallAction(String label, VoidCallback? onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 11, letterSpacing: 2)),
    );
  }

  Widget _buildBackgroundGrid() {
    return Opacity(
      opacity: 0.03,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
        itemBuilder: (_, __) => Container(decoration: BoxDecoration(border: Border.all(color: Colors.white))),
      ),
    );
  }

  Widget _buildSolvedOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: DreadmoorColors.investigatorCyan, size: 80),
            const SizedBox(height: 20),
            Text("INTEGRITY_RESTORED", style: GoogleFonts.spaceGrotesk(color: DreadmoorColors.investigatorCyan, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4)),
          ],
        ),
      ),
    );
  }
}
