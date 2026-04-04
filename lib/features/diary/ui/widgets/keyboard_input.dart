import 'package:flutter/material.dart';

class KeyboardInput extends StatelessWidget {
  final Function(String) onLetterTap;
  final VoidCallback onBackspace;

  const KeyboardInput({
    super.key,
    required this.onLetterTap,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['Z', 'X', 'C', 'V', 'B', 'N', 'M', '<']
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            final isBackspace = key == '<';
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: InkWell(
                onTap: () {
                  if (isBackspace) {
                    onBackspace();
                  } else {
                    onLetterTap(key);
                  }
                },
                child: Container(
                  width: isBackspace ? 60 : 35,
                  height: 45,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isBackspace
                      ? const Icon(Icons.backspace, color: Colors.white, size: 20)
                      : Text(
                          key,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
