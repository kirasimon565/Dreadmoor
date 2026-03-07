import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  static const int size = 4;

  late List<List<int>> board;
  late List<List<int>> goal;

  @override
  void initState() {
    super.initState();
    _generateBoard();
  }

  void _generateBoard() {
    board = List.generate(
      size,
      (r) => List.generate(size, (c) => r * size + c),
    );

    goal = List.generate(
      size,
      (r) => List.generate(size, (c) => r * size + c),
    );

    final rng = Random();

    for (int i = 0; i < 20; i++) {
      int r = rng.nextInt(size - 1);
      int c = rng.nextInt(size - 1);
      _rotate(r, c);
    }
  }

  void _rotate(int r, int c) {
    final a = board[r][c];
    final b = board[r][c + 1];
    final d = board[r + 1][c];
    final e = board[r + 1][c + 1];

    setState(() {
      board[r][c] = b;
      board[r][c + 1] = e;
      board[r + 1][c] = a;
      board[r + 1][c + 1] = d;
    });

    _checkWin();
  }

  void _checkWin() {
    bool solved = true;

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (board[r][c] != goal[r][c]) {
          solved = false;
        }
      }
    }

    if (solved) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Puzzle Solved"),
          content: const Text("You restored the pattern."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _generateBoard();
                setState(() {});
              },
              child: const Text("Play Again"),
            )
          ],
        ),
      );
    }
  }

  Widget _tile(int r, int c) {
    return GestureDetector(
      onTap: () {
        if (r < size - 1 && c < size - 1) {
          _rotate(r, c);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.white12),
        ),
        child: Center(
          child: Text(
            "${board[r][c]}",
            style: GoogleFonts.robotoMono(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Counterclockwise",
          style: GoogleFonts.robotoMono(),
        ),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: size * size,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: size,
            ),
            itemBuilder: (_, i) {
              final r = i ~/ size;
              final c = i % size;
              return _tile(r, c);
            },
          ),
        ),
      ),
    );
  }
}
