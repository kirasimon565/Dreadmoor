import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/navigation/routes.dart';
import 'package:dreadmoor/ui/theme/colors.dart';

class StudioIntroScreen extends ConsumerStatefulWidget {
  const StudioIntroScreen({super.key});

  @override
  ConsumerState<StudioIntroScreen> createState() => _StudioIntroScreenState();
}

class _StudioIntroScreenState extends ConsumerState<StudioIntroScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Logo entrance
  late final AnimationController _logoController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  // Subtle breathing pulse
  late final AnimationController _breathingController;
  late final Animation<double> _breathingScale;

  // Disclaimer fades in after logo settles
  late final AnimationController _disclaimerController;
  late final Animation<double> _disclaimerFade;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ── Logo entrance ─────────────────────────────────────────────────
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeIn),
    );

    _logoScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    // ── Breathing pulse ───────────────────────────────────────────────
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    _breathingScale = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // ── Disclaimer ────────────────────────────────────────────────────
    _disclaimerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _disclaimerFade = CurvedAnimation(
      parent: _disclaimerController,
      curve: Curves.easeIn,
    );

    _startFlow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logoController.dispose();
    _breathingController.dispose();
    _disclaimerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _logoController.stop();
      _breathingController.stop();
      _disclaimerController.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (!_logoController.isCompleted) _logoController.forward();
      _breathingController.repeat(reverse: true);
      if (!_disclaimerController.isCompleted) _disclaimerController.forward();
    }
  }

  Future<void> _startFlow() async {
    final startTime = DateTime.now();

    _logoController.forward();

    // Disclaimer fades in after logo settles
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) _disclaimerController.forward();

    // ── Initialization ────────────────────────────────────────────────
    try {
      await AppDatabase.init();
    } catch (e) {
      debugPrint('⚠️ Studio init error: $e');
      // Non-fatal — continue anyway
    }

    // Minimum cinematic display time
    const minDisplay = 4000;
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsed < minDisplay) {
      await Future.delayed(Duration(milliseconds: minDisplay - elapsed));
    }

    await _navigateNext();
  }

  Future<void> _navigateNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    // ✅ Load player and set playerStateProvider BEFORE navigating
    // so the router redirect sees the correct state immediately
    final db = ref.read(databaseProvider);
    final player = await (db.select(db.players)..limit(1)).getSingleOrNull();

    if (!mounted) return;

    if (player != null) {
      ref.read(playerStateProvider.notifier).state = player;
    }

    // Fade logo out
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
      backgroundColor: DreadmoorColors.background(Theme.of(context).brightness),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Background texture ─────────────────────────────────────
          Image.asset(
            'assets/backgrounds/studio_intro_bg.png',
            fit: BoxFit.cover,
            color: Colors.white.withOpacity(0.18),
            colorBlendMode: BlendMode.modulate,
            errorBuilder: (_, __, ___) =>
                ColoredBox(color: DreadmoorColors.background(Theme.of(context).brightness)),
          ),

          // ── 2. Grain / glitch overlay ─────────────────────────────────
          IgnorePointer(
            child: Opacity(
              opacity: 0.07,
              child: Image.asset(
                'assets/ui/glitch_overlay.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // ── 3. Radial vignette ────────────────────────────────────────
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.75),
                    Colors.black,
                  ],
                  stops: const [0.25, 0.70, 1.0],
                  radius: 1.2,
                ),
              ),
            ),
          ),

          // ── 4. Center branding ────────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ Logo tinted white (original is black),
                    //    breathing pulse kept, glow removed entirely
                    ScaleTransition(
                      scale: _breathingScale,
                      child: Image.asset(
                        'assets/branding/blackmoon_logo.png',
                        width: 180,
                        filterQuality: FilterQuality.high,
                        // ✅ Tint black logo to white using BlendMode.srcATop
                        color: Colors.white.withOpacity(0.88),
                        colorBlendMode: BlendMode.srcATop,
                        errorBuilder: (_, __, ___) => Text(
                          "BLACKMOON STUDIO",
                          style: GoogleFonts.cinzel(
                            fontSize: 22,
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 5.0,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Disclaimer fades in after logo
                    FadeTransition(
                      opacity: _disclaimerFade,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          "These characters and places are purely fictional.\n"
                          "Any resemblance to actual persons or events is purely coincidental.",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9,
                            letterSpacing: 1.2,
                            height: 1.9,
                            color: Colors.white.withOpacity(0.22),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 5. Bottom status bar ──────────────────────────────────────
          Positioned(
            bottom: 36,
            left: 32,
            right: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Lottie loading dots
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Lottie.asset(
                        'assets/ui/loading_dots_anim.json',
                        repeat: true,
                        animate: true,
                        fit: BoxFit.contain,
                        // Graceful fallback if JSON is missing
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(width: 28, height: 28),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Loading",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        color: DreadmoorColors.investigatorCyan.withOpacity(0.45),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),

                // Version
                Text(
                  "v1.0.0",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.2),
                    letterSpacing: 1.0,
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
