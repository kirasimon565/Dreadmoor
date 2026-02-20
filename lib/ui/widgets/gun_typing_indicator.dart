import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class GunTypingIndicator extends StatelessWidget {
  const GunTypingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.black54,
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Text('Typing...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          const SizedBox(width: 10),
          Lottie.asset(
            'assets/ui/typing_gun_anim.json',
            height: 30,
            errorBuilder: (c, e, s) => const Icon(Icons.more_horiz, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
