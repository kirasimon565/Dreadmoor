import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/scheduler/global_scheduler.dart';
import '../../../core/scripting/script_loader.dart';
import '../../../core/state/game_state.dart';
import '../../navigation/routes.dart';
import '../../theme/colors.dart';

class StudioIntroScreen extends ConsumerStatefulWidget {
  const StudioIntroScreen({super.key});

  @override
  ConsumerState<StudioIntroScreen> createState() => _StudioIntroScreenState();
}

class _StudioIntroScreenState extends ConsumerState<StudioIntroScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _logoController;
  late AnimationController _breathingController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Entrance animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Subtle breathing effect for the logo
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    );

    _logoScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    _startFlow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logoController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _logoController.stop();
      _breathingController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _logoController.forward();
      _breathingController.repeat(reverse: true);
    }
  }

  Future<void> _startFlow() async {
    _logoController.forward();

    final startTime = DateTime.now();

    try {
      await AppDatabase.init();
      await ScriptLoader.loadAll();
      await GlobalScheduler.prepare();
    } catch (e) {
      debugPrint("Init Error: $e");
      // context.go(Routes.error); // enable later if needed
    }

    const minDisplayTime = 4000; // cinematic pacing
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsed < minDisplayTime) {
      await Future.delayed(
          Duration(milliseconds: minDisplayTime - elapsed));
    }

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    final db = ref.read(databaseProvider);
    final player = await (db.select(db.players)..limit(1)).getSingleOrNull();

    await _logoController.reverse();

    if (!mounted) return;

    if (player != null) {
      context.go(Routes.welcome);
    } else {
      context.go(Routes.setup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1) Cinematic Background Texture
          Image.asset(
            'assets/backgrounds/studio_intro_bg.png',
            fit: BoxFit.cover,
            color: Colors.white.withOpacity(0.18),
            colorBlendMode: BlendMode.modulate,
            errorBuilder: (c, e, s) =>
                const ColoredBox(color: DreadmoorColors.background),
          ),

          // 2) Glitch / Grain Layer (visual only)
          IgnorePointer(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/ui/glitch_overlay.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // 3) Vignette
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

          // 4) Center Branding
          FadeTransition(
            opacity: _logoFade,
            child: ScaleTransition(
              scale: _logoScale,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subtle glow aura behind logo (optional polish)
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: DreadmoorColors.glowCyan.withOpacity(0.25),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 1.03)
                            .animate(_breathingController),
                        child: Image.asset(
                          'assets/branding/blackmoon_logo.png',
                          width: 180,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.blur_on,
                            size: 100,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: Text(
                        "This game is a work of fiction. Names, characters, businesses, places, events, locales, and incidents are either the products of the author's imagination or used in a fictitious manner. Any resemblance to actual persons, living or dead, or actual events is purely coincidental.",
                        style: GoogleFonts.michroma(
                          fontSize: 8,
                          letterSpacing: 3.5,
                          height: 2.0,
                          color: Colors.white.withOpacity(0.22),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5) Bottom Status Bar
          Positioned(
            bottom: 36,
            left: 32,
            right: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Loading Status (Lottie dots)
                Row(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Lottie.asset(
                        'assets/ui/loading_dots_anim.json',
                        repeat: true,
                        animate: true,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Loading...",
                      style: GoogleFonts.shareTechMono(
                        fontSize: 10,
                        color:
                            DreadmoorColors.accentCyan.withOpacity(0.45),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),

                // Version
                Text(
                  "v1.0.0",
                  style: GoogleFonts.shareTechMono(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.2),
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
