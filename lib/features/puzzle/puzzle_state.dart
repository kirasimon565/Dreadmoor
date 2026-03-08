import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PuzzleState {
  final int level;
  final int gridSize;
  final List<int> currentBoard;
  final List<int> targetBoard;
  final int moves;
  final List<List<int>> history;
  final bool isSolved;
  final int? previewPivotIndex;

  const PuzzleState({
    required this.level,
    required this.gridSize,
    required this.currentBoard,
    required this.targetBoard,
    this.moves = 0,
    this.history = const [],
    this.isSolved = false,
    this.previewPivotIndex,
  });

  PuzzleState copyWith({
    int? level,
    List<int>? currentBoard,
    List<int>? targetBoard,
    int? moves,
    List<List<int>>? history,
    bool? isSolved,
    int? previewPivotIndex,
    bool clearPreview = false,
  }) {
    return PuzzleState(
      level: level ?? this.level,
      gridSize: gridSize,
      currentBoard: currentBoard ?? this.currentBoard,
      targetBoard: targetBoard ?? this.targetBoard,
      moves: moves ?? this.moves,
      history: history ?? this.history,
      isSolved: isSolved ?? this.isSolved,
      previewPivotIndex:
          clearPreview ? null : (previewPivotIndex ?? this.previewPivotIndex),
    );
  }
}

class PuzzleNotifier extends StateNotifier<PuzzleState> {
  PuzzleNotifier() : super(_generateInitialState(3, level: 1));

  /// Generates a new puzzle board
  static PuzzleState _generateInitialState(int size, {int level = 1}) {
    final target = List.generate(size * size, (index) => index);

    List<int> current = List.of(target);
    final rng = Random();

    // scramble board with valid moves
    final scrambleMoves = 20 + rng.nextInt(10);

    for (int i = 0; i < scrambleMoves; i++) {
      final r = rng.nextInt(size - 1);
      final c = rng.nextInt(size - 1);
      final pivot = r * size + c;

      current = _rotateCCW(current, pivot, size);
    }

    // ensure puzzle isn't accidentally solved
    if (_isSameBoard(current, target)) {
      current = _rotateCCW(current, 0, size);
    }

    return PuzzleState(
      level: level,
      gridSize: size,
      currentBoard: current,
      targetBoard: target,
    );
  }

  /// Load a puzzle level
  void loadLevel(int level) {
    int size = 3;

    if (level >= 6 && level <= 15) {
      size = 4;
    } else if (level > 15) {
      size = 5;
    }

    state = _generateInitialState(size, level: level);
  }

  /// Restart current level
  void reset() {
    state = _generateInitialState(
      state.gridSize,
      level: state.level,
    );
  }

  /// Rotate a 2x2 block counter-clockwise
  static List<int> _rotateCCW(List<int> board, int pivot, int size) {
    final newBoard = List<int>.from(board);

    final tl = pivot;
    final tr = pivot + 1;
    final bl = pivot + size;
    final br = pivot + size + 1;

    final temp = newBoard[tl];

    newBoard[tl] = newBoard[tr];
    newBoard[tr] = newBoard[br];
    newBoard[br] = newBoard[bl];
    newBoard[bl] = temp;

    return newBoard;
  }

  /// Rotate block from UI interaction
  void rotateBlock(int pivotIndex) {
    if (state.isSolved) return;

    final newBoard =
        _rotateCCW(state.currentBoard, pivotIndex, state.gridSize);

    final solved = _checkSolved(newBoard, state.targetBoard);

    state = state.copyWith(
      currentBoard: newBoard,
      history: [...state.history, state.currentBoard],
      moves: state.moves + 1,
      isSolved: solved,
      clearPreview: true,
    );
  }

  /// Undo last move
  void undo() {
    if (state.history.isEmpty || state.isSolved) return;

    final previousBoard = state.history.last;
    final newHistory = List<List<int>>.from(state.history)..removeLast();

    state = state.copyWith(
      currentBoard: previousBoard,
      history: newHistory,
    );
  }

  /// Show preview highlight
  void setPreview(int? pivotIndex) {
    if (state.isSolved) return;

    state = state.copyWith(
      previewPivotIndex: pivotIndex,
      clearPreview: pivotIndex == null,
    );
  }

  /// Check if board matches target
  bool _checkSolved(List<int> current, List<int> target) {
    for (int i = 0; i < current.length; i++) {
      if (current[i] != target[i]) return false;
    }
    return true;
  }

  static bool _isSameBoard(List<int> a, List<int> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final puzzleProvider =
    StateNotifierProvider<PuzzleNotifier, PuzzleState>((ref) {
  return PuzzleNotifier();
});
