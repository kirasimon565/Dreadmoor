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

class _StudioIntroScreenState extends ConsumerState<StudioIntroScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _breathingController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    
    // Entrance Animation
    _logoController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 2000),
    );

    // Subtle breathing effect for the logo
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _logoFade = CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.8, curve: Curves.easeIn));
    _logoScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    _startFlow();
  }

  Future<void> _startFlow() async {
    // Start fading in the logo immediately
    _logoController.forward();

    // Parallel processing: App Init + Minimum Delay
    final startTime = DateTime.now();

    try {
      await AppDatabase.init();
      await ScriptLoader.loadAll();
      await GlobalScheduler.prepare();
    } catch (e) {
      debugPrint("Init Error: $e");
      // Optionally route to FatalErrorScreen here
    }

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    const minDisplayTime = 4000; // Slightly longer for cinematic tension
    
    if (elapsed < minDisplayTime) {
      await Future.delayed(Duration(milliseconds: minDisplayTime - elapsed));
    }

    if (mounted) {
      setState(() => _initialized = true);
      _navigateNext();
    }
  }

  Future<void> _navigateNext() async {
    final db = ref.read(databaseProvider);
    final player = await (db.select(db.players)..limit(1)).getSingleOrNull();

    if (mounted) {
      // Fade out effect before switching screens
      _logoController.reverse().then((_) {
        if (player != null) {
          context.go('/welcome');
        } else {
          context.go('/setup');
        }
      });
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00E5FF); // Dreadmoor Cyan

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Cinematic Background Texture
          Image.asset(
            'assets/backgrounds/studio_intro_bg.png',
            fit: BoxFit.cover,
            color: Colors.white.withOpacity(0.2),
            colorBlendMode: BlendMode.modulate,
            errorBuilder: (c, e, s) => Container(color: const Color(0xFF050505)),
          ),

          // 2. Glitch & Grain Layer
          Opacity(
            opacity: 0.08,
            child: Image.asset(
              'assets/ui/glitch_overlay.png',
              fit: BoxFit.cover,
            ),
          ),

          // 3. Vignette (The "Noir" shadow frame)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                  Colors.black,
                ],
                stops: const [0.2, 0.7, 1.0],
                radius: 1.2,
              ),
            ),
          ),

          // 4. Center Branding
          FadeTransition(
            opacity: _logoFade,
            child: ScaleTransition(
              scale: _logoScale,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Breathing Logo
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.03).animate(_breathingController),
                      child: Image.asset(
                        'assets/branding/blackmoon_logo.png', // Uses your custom logo
                        width: 180,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (c, e, s) => const Icon(Icons.blur_on, size: 100, color: Colors.white24),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // High-Contrast Legal Text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: Text(
                        "This game is a work of fiction. Names, characters, businesses, places, events, locales, and incidents are either the products of the author's imagination or used in a fictitious manner. Any resemblance to actual persons, living or dead, or actual events is purely coincidental.",
                        style: GoogleFonts.michroma(
                          fontSize: 8,
                          letterSpacing: 3.5,
                          height: 2.0,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. System Status (Bottom Bar)
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Loading Status
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor.withOpacity(0.5)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      "INITIALIZING_DREADMOOR_PROTOCOL...",
                      style: GoogleFonts.shareTechMono(
                        fontSize: 10,
                        color: accentColor.withOpacity(0.4),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                // Version
                Text(
                  "VER_0.1.0_PROTOTYPE",
                  style: GoogleFonts.shareTechMono(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
