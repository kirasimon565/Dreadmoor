import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/scheduler/global_scheduler.dart';
import '../../../core/scripting/script_loader.dart';
import '../../../core/state/game_state.dart';

class StudioIntroScreen extends ConsumerStatefulWidget {
  const StudioIntroScreen({super.key});

  @override
  ConsumerState<StudioIntroScreen> createState() => _StudioIntroScreenState();
}

class _StudioIntroScreenState extends ConsumerState<StudioIntroScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _textVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _controller.forward().then((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _textVisible = true;
        });
        await _initializeApp();
      }
    });
  }

  Future<void> _initializeApp() async {
    // Minimum display time 3000ms total
    final startTime = DateTime.now();

    await AppDatabase.init();
    await ScriptLoader.loadAll();
    await GlobalScheduler.prepare();

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final remaining = 3000 - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (mounted) {
      _checkPlayerAndNavigate();
    }
  }

  Future<void> _checkPlayerAndNavigate() async {
    final db = ref.read(databaseProvider);
    final player = await (db.select(db.players)..limit(1)).getSingleOrNull();

    if (mounted) {
      if (player != null) {
        context.go('/welcome');
      } else {
        context.go('/setup');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // [0] Background
          Image.asset(
            'assets/backgrounds/studio_intro_bg.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.55),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (c, e, s) => Container(color: const Color(0xFF111111)),
          ),
          // [1] Glitch Overlay
          Opacity(
            opacity: 0.04,
            child: Image.asset(
              'assets/ui/glitch_overlay.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (c, e, s) => const SizedBox(),
            ),
          ),
          // [2] Center Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/branding/blackmoon_logo_anim.json',
                  width: 160,
                  repeat: false,
                  animate: true,
                  errorBuilder: (c, e, s) => Image.asset('assets/branding/blackmoon_logo.png', width: 160, errorBuilder: (c,e,s) => const Icon(Icons.circle, size: 80, color: Colors.white)),
                ),
                const SizedBox(height: 24),
                AnimatedOpacity(
                  opacity: _textVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 1200),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      "THESE CHARACTERS AND PLACES ARE PURELY FICTIONAL...",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        letterSpacing: 1.8,
                        color: Colors.white.withOpacity(0.35),
                        height: 1.7,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // [3] Bottom Left Loading
          Positioned(
            bottom: 32,
            left: 32,
            child: Row(
              children: [
                Lottie.asset(
                  'assets/ui/loading_dots_anim.json',
                  width: 40,
                  errorBuilder: (c, e, s) => const SizedBox(width: 40, height: 10, child: Center(child: Text("...", style: TextStyle(color: Colors.white)))),
                ),
                const SizedBox(width: 8),
                Text(
                  "LOADING",
                  style: GoogleFonts.michroma(
                    fontSize: 11,
                    letterSpacing: 2.0,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ),
          // [4] Bottom Right Version
          Positioned(
            bottom: 32,
            right: 32,
            child: Text(
              "v0.1.0",
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 1.5,
                color: Colors.white.withOpacity(0.25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
