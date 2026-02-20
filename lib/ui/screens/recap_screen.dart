import 'package:flutter/material.dart';

class RecapScreen extends StatelessWidget {
  const RecapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder recap content
    return Scaffold(
      appBar: AppBar(
        title: const Text('PREVIOUSLY ON...', style: TextStyle(fontFamily: 'Cinzel', letterSpacing: 2)),
        backgroundColor: Colors.grey[900],
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EPISODE 1: THE DISAPPEARANCE',
              style: TextStyle(fontFamily: 'Cinzel', fontSize: 18, color: Colors.purple, letterSpacing: 1),
            ),
            const Divider(color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '• Rebecca vanished after the rooftop party.',
              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 10),
            const Text(
              '• Amelia claims she called you last.',
              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
            ),
             const SizedBox(height: 10),
            const Text(
              '• You found a strange keycard near the factory.',
              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 40),

            Center(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text('CONTINUE INVESTIGATION'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
