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
      previewPivotIndex: clearPreview ? null : (previewPivotIndex ?? this.previewPivotIndex),
    );
  }
}

class PuzzleNotifier extends StateNotifier<PuzzleState> {
  PuzzleNotifier() : super(_generateInitialState(3, level: 1));

  static PuzzleState _generateInitialState(int size, {int level = 1}) {
    final target = List.generate(size * size, (index) => index);
    List<int> current = List.of(target);
    final rng = Random();
    final scrambleMoves = 15 + rng.nextInt(10);

    for (int i = 0; i < scrambleMoves; i++) {
      final r = rng.nextInt(size - 1);
      final c = rng.nextInt(size - 1);
      final pivot = r * size + c;
      current = _rotateCCW(current, pivot, size);
    }

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

  void loadLevel(int level) {
    int size = (level >= 6) ? 4 : 3;
    state = _generateInitialState(size, level: level);
  }

  void reset() => state = _generateInitialState(state.gridSize, level: state.level);

  static List<int> _rotateCCW(List<int> board, int pivot, int size) {
    final newBoard = List<int>.from(board);
    final tl = pivot, tr = pivot + 1, bl = pivot + size, br = pivot + size + 1;
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
    state = state.copyWith(
      currentBoard: newBoard,
      history: [...state.history, state.currentBoard],
      moves: state.moves + 1,
      isSolved: _isSameBoard(newBoard, state.targetBoard),
      clearPreview: true,
    );
  }

  void undo() {
    if (state.history.isEmpty || state.isSolved) return;
    final previousBoard = state.history.last;
    final newHistory = List<List<int>>.from(state.history)..removeLast();
    state = state.copyWith(currentBoard: previousBoard, history: newHistory);
  }

  static bool _isSameBoard(List<int> a, List<int> b) {
    for (int i = 0; i < a.length; i++) if (a[i] != b[i]) return false;
    return true;
  }
}

final puzzleProvider = StateNotifierProvider<PuzzleNotifier, PuzzleState>((ref) => PuzzleNotifier());
