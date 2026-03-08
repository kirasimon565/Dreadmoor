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

class _PuzzleScreenState extends ConsumerState<PuzzleScreen>
    with SingleTickerProviderStateMixin {

  bool _started = false;
  bool _isGlitching = false;

  int? _previewPivot;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOut),
    );
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
  }

  void _handleWin() {
    setState(() => _isGlitching = true);

    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        ref.read(globalSchedulerProvider).completePuzzle();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final puzzle = ref.watch(puzzleProvider);
    final notifier = ref.read(puzzleProvider.notifier);

    ref.listen<PuzzleState>(puzzleProvider, (prev, next) {
      if (prev?.isSolved != true && next.isSolved) {
        _handleWin();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0C1016),
      body: Stack(
        children: [

          SafeArea(
            child: Column(
              children: [

                const OSHeader(
                  title: "DREADMOOR OS",
                  subtitle: "PUZZLE MODULE",
                ),

                Expanded(
                  child: !_started
                      ? _buildLevelSelection()
                      : _buildPuzzleBody(puzzle, notifier),
                ),
              ],
            ),
          ),

          if (_isGlitching) _buildCompletionOverlay(),
        ],
      ),
    );
  }

  // LEVEL SCREEN

  Widget _buildLevelSelection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [

          const SizedBox(height: 20),

          Text(
            "SIGNAL RECOVERY MODULE",
            style: DreadmoorTheme.headingStyle.copyWith(
              fontSize: 18,
              letterSpacing: 3,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "Decrypt corrupted signal fragments to restore hidden data.",
            textAlign: TextAlign.center,
            style: DreadmoorTheme.bodyStyle.copyWith(
              color: DreadmoorColors.textSecondary,
            ),
          ),

          const SizedBox(height: 40),

          _buildPuzzleCard(
            title: "Signal Reconstruction",
            subtitle: "Level 1",
            unlocked: true,
            onTap: () {
              setState(() => _started = true);
            },
          ),

          const SizedBox(height: 16),

          _buildPuzzleCard(
            title: "Encrypted Media",
            subtitle: "Locked",
            unlocked: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleCard({
    required String title,
    required String subtitle,
    bool unlocked = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DreadmoorColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unlocked
                ? DreadmoorColors.accentCyan
                : Colors.white12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              title,
              style: DreadmoorTheme.headingStyle.copyWith(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              unlocked
                  ? subtitle
                  : "Come back when the investigation reaches this stage.",
              style: DreadmoorTheme.bodyStyle.copyWith(
                color: DreadmoorColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PUZZLE BODY

  Widget _buildPuzzleBody(PuzzleState puzzle, PuzzleNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [

          _buildStatusHeader(puzzle),

          _buildTargetBoard(puzzle),

          AnimatedBuilder(
            animation: _shakeController,
            builder: (_, child) {
              return Transform.translate(
                offset: Offset(
                  sin(_shakeAnimation.value) * 4,
                  0,
                ),
                child: child,
              );
            },
            child: _buildPuzzleBoard(puzzle, notifier),
          ),

          _buildControls(puzzle, notifier),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(PuzzleState puzzle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "STATUS",
              style: DreadmoorTheme.bodyStyle.copyWith(
                fontSize: 10,
                letterSpacing: 2,
                color: DreadmoorColors.textMeta,
              ),
            ),
            Text(
              puzzle.isSolved ? "RESTORED" : "CORRUPTED",
              style: DreadmoorTheme.headingStyle.copyWith(
                color: puzzle.isSolved
                    ? DreadmoorColors.accentCyan
                    : DreadmoorColors.accentRed,
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
                fontSize: 10,
                letterSpacing: 2,
                color: DreadmoorColors.textMeta,
              ),
            ),
            Text(
              puzzle.isSolved ? "0%" : "84%",
              style: DreadmoorTheme.headingStyle.copyWith(
                color: DreadmoorColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetBoard(PuzzleState puzzle) {
    return Column(
      children: [

        Text(
          "TARGET SIGNAL",
          style: DreadmoorTheme.bodyStyle.copyWith(
            fontSize: 10,
            letterSpacing: 2,
            color: DreadmoorColors.textMeta,
          ),
        ),

        const SizedBox(height: 8),

        _buildMiniBoard(puzzle.targetBoard, puzzle.gridSize),
      ],
    );
  }

  Widget _buildMiniBoard(List<int> target, int size) {
    return SizedBox(
      width: 120,
      height: 120,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate:
        SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: size),
        itemCount: size * size,
        itemBuilder: (context, index) {
          return _buildTileVisual(target[index], true);
        },
      ),
    );
  }

  Widget _buildPuzzleBoard(PuzzleState puzzle, PuzzleNotifier notifier) {
    return GestureDetector(
      onDoubleTap: notifier.undo,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: DreadmoorColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildInteractiveBoard(puzzle, notifier),
        ),
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

            ...List.generate(size * size, (i) {

              final currentIndex = puzzle.currentBoard.indexOf(i);
              final r = currentIndex ~/ size;
              final c = currentIndex % size;

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                top: r * (tileSize + spacing),
                left: c * (tileSize + spacing),
                width: tileSize,
                height: tileSize,
                child: _buildTileVisual(i, false),
              );
            }),

            ...List.generate((size - 1) * (size - 1), (i) {

              final r = i ~/ (size - 1);
              final c = i % (size - 1);

              final pivotIndex = r * size + c;

              final top = r * (tileSize + spacing) + tileSize / 2;
              final left = c * (tileSize + spacing) + tileSize / 2;

              return Positioned(
                top: top,
                left: left,
                width: tileSize,
                height: tileSize,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    notifier.rotateBlock(pivotIndex);
                    _triggerShake();
                  },
                  onLongPressStart: (_) {
                    setState(() {
                      _previewPivot = pivotIndex;
                    });
                  },
                  onLongPressEnd: (_) {
                    setState(() {
                      _previewPivot = null;
                    });
                  },
                ),
              );
            }),

            if (_previewPivot != null)
              _buildPreviewOverlay(_previewPivot!, tileSize, spacing, size),
          ],
        );
      },
    );
  }

  Widget _buildPreviewOverlay(
      int pivot,
      double tileSize,
      double spacing,
      int gridSize,
      ) {

    final r = pivot ~/ gridSize;
    final c = pivot % gridSize;

    final top = r * (tileSize + spacing);
    final left = c * (tileSize + spacing);

    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: tileSize * 2 + spacing,
        height: tileSize * 2 + spacing,
        decoration: BoxDecoration(
          border: Border.all(
            color: DreadmoorColors.accentCyan,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
          color: DreadmoorColors.accentCyan.withOpacity(0.08),
        ),
        child: Center(
          child: Icon(
            Icons.rotate_left,
            color: DreadmoorColors.accentCyan.withOpacity(0.6),
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildControls(PuzzleState puzzle, PuzzleNotifier notifier) {
    return Column(
      children: [

        Text(
          "MOVES: ${puzzle.moves}",
          style: DreadmoorTheme.headingStyle.copyWith(
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            TextButton(
              onPressed: puzzle.history.isEmpty ? null : notifier.undo,
              child: const Text("[UNDO]"),
            ),

            TextButton(
              onPressed: notifier.reset,
              child: const Text("[RESTART]"),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("[BACK TO CHAT]"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTileVisual(int value, bool mini) {

    final rng = Random(value * 999);
    final type = rng.nextInt(4);

    IconData icon;

    switch (type) {
      case 0:
        icon = Icons.description;
        break;
      case 1:
        icon = Icons.fingerprint;
        break;
      case 2:
        icon = Icons.photo;
        break;
      default:
        icon = Icons.mic;
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: DreadmoorColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: Center(
        child: Icon(
          icon,
          size: mini ? 12 : 22,
          color: Colors.white30,
        ),
      ),
    );
  }

  Widget _buildCompletionOverlay() {
    return Container(
      color: DreadmoorColors.accentCyan.withOpacity(0.2),
      child: Center(
        child: Text(
          "DECRYPTION COMPLETE",
          style: DreadmoorTheme.headingStyle.copyWith(
            fontSize: 30,
            letterSpacing: 4,
            shadows: [
              BoxShadow(
                color: DreadmoorColors.accentCyan,
                blurRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
