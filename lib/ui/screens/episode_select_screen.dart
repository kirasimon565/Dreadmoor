import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/game_state.dart';
import '../../core/scheduler/global_scheduler.dart';
import 'package:go_router/go_router.dart';

class EpisodeSelectScreen extends ConsumerWidget {
  const EpisodeSelectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hardcoded for now, or fetch from DB
    final episodes = [
      {'id': 'ep01', 'title': 'Episode 1: The Disappearance', 'locked': false},
      {'id': 'ep02', 'title': 'Episode 2: Dark Web', 'locked': true},
      {'id': 'ep03', 'title': 'Episode 3: Betrayal', 'locked': true},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EPISODES', style: TextStyle(fontFamily: 'Cinzel', letterSpacing: 2)),
        backgroundColor: Colors.grey[900],
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: episodes.length,
        itemBuilder: (context, index) {
          final ep = episodes[index];
          final isLocked = ep['locked'] as bool;

          return GestureDetector(
            onTap: isLocked ? null : () {
               ref.read(globalSchedulerProvider).startThread(ep['id'] as String, 'amelia_chat'); // Default start thread
               context.go('/messenger');
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              height: 150,
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey[900] : Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isLocked ? Colors.grey[800]! : Colors.purple),
                image: DecorationImage(
                  image: const AssetImage('assets/backgrounds/studio_intro_bg.mp4'), // Placeholder
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.darken),
                  onError: (e, s) {},
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLocked) const Icon(Icons.lock, color: Colors.grey, size: 40),
                        const SizedBox(height: 10),
                        Text(
                          ep['title'] as String,
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 20,
                            color: isLocked ? Colors.grey : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isLocked)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text('TAP TO PLAY', style: TextStyle(color: Colors.purpleAccent, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
