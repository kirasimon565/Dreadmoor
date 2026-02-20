import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../core/state/player_state.dart';

class StudioIntroScreen extends ConsumerStatefulWidget {
  const StudioIntroScreen({super.key});

  @override
  ConsumerState<StudioIntroScreen> createState() => _StudioIntroScreenState();
}

class _StudioIntroScreenState extends ConsumerState<StudioIntroScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward().then((_) async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) _checkPlayerAndNavigate();
    });
  }

  void _checkPlayerAndNavigate() {
    final playerAsync = ref.read(playerProvider);

    playerAsync.when(
      data: (player) {
        if (player == null) {
          context.go('/setup');
        } else {
          context.go('/welcome');
        }
      },
      loading: () {
        // Wait a bit more or listen
         ref.listenManual(playerProvider, (previous, next) {
           next.whenData((player) {
             if (player == null) context.go('/setup');
             else context.go('/welcome');
           });
         });
      },
      error: (e, s) {
        // Fallback to setup on error?
        context.go('/setup');
      }
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Fog (Simulated with Gradient for now)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF000000), Color(0xFF1A1A1A)],
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _opacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Image.asset(
                    'assets/branding/blackmoon_logo.png',
                    width: 150,
                    errorBuilder: (c, o, s) => const Icon(Icons.nightlight_round, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'BLACKMOON STUDIO',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 24,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'These characters and places are purely fictional.',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Row(
              children: [
                const Text('Loading', style: TextStyle(color: Colors.grey)),
                Lottie.asset(
                  'assets/ui/loading_dots_anim.json',
                  width: 30,
                  height: 10,
                  errorBuilder: (c, e, s) => const Text('...', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 20,
            right: 20,
            child: Text('v0.1.0', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
