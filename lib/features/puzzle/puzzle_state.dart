import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PuzzleState {
  final int gridSize;
  final List<int> currentBoard;
  final List<int> targetBoard;
  final int moves;
  final List<List<int>> history;
  final bool isSolved;
  final int? previewPivotIndex; // Index of the top-left tile of the 2x2 block being previewed

  PuzzleState({
    required this.gridSize,
    required this.currentBoard,
    required this.targetBoard,
    this.moves = 0,
    this.history = const [],
    this.isSolved = false,
    this.previewPivotIndex,
  });

  PuzzleState copyWith({
    List<int>? currentBoard,
    List<int>? targetBoard,
    int? moves,
    List<List<int>>? history,
    bool? isSolved,
    int? previewPivotIndex,
    bool clearPreview = false,
  }) {
    return PuzzleState(
      gridSize: gridSize,
      currentBoard: currentBoard ?? this.currentBoard,
      targetBoard: targetBoard ?? this.targetBoard,
      moves: moves ?? this.moves,
      history: history ?? this.history,
      isSolved: isSolved ?? this.isSolved,
      previewPivotIndex: clearPreview ? null : (previewPivotIndex ?? this.previewPivotIndex),
    );
  }
}

class PuzzleNotifier extends StateNotifier<PuzzleState> {
  PuzzleNotifier() : super(_generateInitialState(3)); // Default to 3x3 for early levels

  static PuzzleState _generateInitialState(int size) {
    final target = List.generate(size * size, (index) => index);

    // Create a solved board, then scramble it using valid moves
    List<int> current = List.of(target);
    final rng = Random();

    // Scramble by applying 20-30 random counter-clockwise rotations
    final scrambleMoves = 20 + rng.nextInt(10);
    for (int i = 0; i < scrambleMoves; i++) {
      // Pick a random pivot that can form a 2x2 block
      final maxRow = size - 1;
      final maxCol = size - 1;
      final r = rng.nextInt(maxRow);
      final c = rng.nextInt(maxCol);
      final pivot = r * size + c;

      current = _rotateCCW(current, pivot, size);
    }

    return PuzzleState(
      gridSize: size,
      currentBoard: current,
      targetBoard: target,
    );
  }

  void loadLevel(int level) {
    int size = 3;
    if (level >= 6 && level <= 15) {
      size = 4;
    } else if (level > 15) {
      size = 5;
    }
    state = _generateInitialState(size);
  }

  void reset() {
    // Just clear history and moves, keeping the same target/scramble
    // But since the current board is the *result* of a scramble, we'd need to store the initial scramble state.
    // Easiest is to just generate a new puzzle.
    state = _generateInitialState(state.gridSize);
  }

  // Rotate a 2x2 block counter-clockwise starting from the top-left pivot index
  static List<int> _rotateCCW(List<int> board, int pivot, int size) {
    final newBoard = List<int>.from(board);

    final tl = pivot;
    final tr = pivot + 1;
    final bl = pivot + size;
    final br = pivot + size + 1;

    // CCW Rotation logic for 2x2:
    // Top-Left <- Top-Right
    // Top-Right <- Bottom-Right
    // Bottom-Right <- Bottom-Left
    // Bottom-Left <- Top-Left

    final temp = newBoard[tl];
    newBoard[tl] = newBoard[tr];
    newBoard[tr] = newBoard[br];
    newBoard[br] = newBoard[bl];
    newBoard[bl] = temp;

    return newBoard;
  }

  void rotateBlock(int pivotIndex) {
    if (state.isSolved) return;

    final newBoard = _rotateCCW(state.currentBoard, pivotIndex, state.gridSize);
    final isSolved = _checkSolved(newBoard, state.targetBoard);

    state = state.copyWith(
      currentBoard: newBoard,
      history: [...state.history, state.currentBoard],
      moves: state.moves + 1,
      isSolved: isSolved,
      clearPreview: true, // clear any active preview
    );
  }

  void undo() {
    if (state.history.isEmpty || state.isSolved) return;

    final previousBoard = state.history.last;
    final newHistory = List<List<int>>.from(state.history)..removeLast();

    state = state.copyWith(
      currentBoard: previousBoard,
      history: newHistory,
      // We don't decrement moves on undo to penalize mistakes slightly, or we can. Let's not decrement.
    );
  }

  void setPreview(int? pivotIndex) {
    if (state.isSolved) return;
    state = state.copyWith(previewPivotIndex: pivotIndex, clearPreview: pivotIndex == null);
  }

  bool _checkSolved(List<int> current, List<int> target) {
    for (int i = 0; i < current.length; i++) {
      if (current[i] != target[i]) return false;
    }
    return true;
  }
}

final puzzleProvider = StateNotifierProvider<PuzzleNotifier, PuzzleState>((ref) {
  return PuzzleNotifier();
});
