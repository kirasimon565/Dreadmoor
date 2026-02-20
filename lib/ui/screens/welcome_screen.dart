import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/game_state.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background loop
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/welcome_fog_loop.png',
              fit: BoxFit.cover,
              errorBuilder: (c,o,s) => Container(color: Colors.black),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const Text(
                    'DREADMOOR',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 48,
                      color: Colors.white,
                      letterSpacing: 8,
                      shadows: [Shadow(color: Colors.purple, blurRadius: 10)],
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Menu
                  _buildMenuButton('CONTINUE', () {
                     // Resume last active thread logic
                     // For now, just go to messenger
                     context.go('/messenger');
                  }),
                  _buildMenuButton('START GAME', () {
                    _showStartGameWarning();
                  }),
                  _buildMenuButton('EPISODES', () => context.push('/episodes')),
                  _buildMenuButton('PLAYER PROFILE', () => context.push('/player_profile')),
                  _buildMenuButton('SETTINGS', () => context.push('/settings')),
                  _buildMenuButton('CREDITS', () => context.push('/credits')),
                  _buildMenuButton('SAVE / LOAD', () => context.push('/saveload')),
                ],
              ),
            ),
          ),

          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'BLACKMOON v0.1.0',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
        child: Text(text),
      ),
    );
  }

  void _showStartGameWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Start New Game?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will reset your current progress in the story.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text('START', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _startNewGame() {
    // Reset state Logic
    // Start Episode 1, Thread 1
    // For prototype:
    final scheduler = ref.read(globalSchedulerProvider);
    scheduler.startThread('ep01', 'amelia_chat');

    context.go('/messenger');
  }
}
