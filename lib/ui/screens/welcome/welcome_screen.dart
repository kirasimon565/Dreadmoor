import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/game_state.dart';
import '../../navigation/routes.dart';
import '../../theme/colors.dart';
import '../../widgets/fog_video_background.dart';

bool get isDebugMode {
  bool inDebug = false;
  assert(inDebug = true);
  return inDebug;
}

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breathingController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _breathingController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _breathingController.repeat(reverse: true);
    }
  }

  // ✅ Returns true if this is a returning player with an active thread
  bool get _hasActiveGame {
    final player = ref.read(playerStateProvider);
    return player != null;
  }

  void _onMainAction() {
    HapticFeedback.selectionClick();
    if (_hasActiveGame) {
      _continueGame();
    } else {
      context.go(Routes.setup);
    }
  }

  void _continueGame() {
    final threadId = ref.read(activeThreadIdProvider);
    if (threadId != null) {
      context.go(Routes.chat(threadId));
    } else {
      context.go(Routes.messenger);
    }
  }

  void _openDebug() {
    if (!isDebugMode) return;
    HapticFeedback.heavyImpact();
    context.push(Routes.debug);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final player = ref.watch(playerStateProvider);
    final hasGame = player != null;

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          // ── Video background ──────────────────────────────────────────
          const Positioned.fill(
            child: FogVideoBackground(
              assetPath: 'assets/backgrounds/welcome_fog_loop.mp4',
              darkenOpacity: 0.65,
            ),
          ),

          // ── Glitch overlay ────────────────────────────────────────────
          IgnorePointer(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/ui/glitch_overlay.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Logo ─────────────────────────────────────────────
                Center(
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: reduceMotion ? 1.0 : _scaleAnimation.value,
                      child: GestureDetector(
                        onLongPress: _openDebug,
                        child: Image.asset(
                          'assets/branding/dreadmore_logo.png',
                          width: 200,
                          errorBuilder: (_, __, ___) => Text(
                            "DREADMOOR",
                            style: GoogleFonts.cinzel(
                              fontSize: 40,
                              color: Colors.white,
                              letterSpacing: 4.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── Hero action button ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _HeroButton(
                    label: hasGame ? "CONTINUE" : "START GAME",
                    onTap: _onMainAction,
                    reduceMotion: reduceMotion,
                  ),
                ),

                const Spacer(flex: 3),

                // ── Bottom bar ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "BLACKMOON",
                        style: GoogleFonts.michroma(
                          fontSize: 10,
                          letterSpacing: 2.0,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),

                      // Settings icon — center
                      GestureDetector(
                        onTap: () => context.push(Routes.settings),
                        child: Icon(
                          Icons.settings_outlined,
                          size: 20,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),

                      Text(
                        "v1.0.0",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                    ],
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

// ── Hero glass button ──────────────────────────────────────────────────────

class _HeroButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool reduceMotion;

  const _HeroButton({
    required this.label,
    required this.onTap,
    required this.reduceMotion,
  });

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed && !widget.reduceMotion ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 64,
              decoration: BoxDecoration(
                color: _pressed
                    ? DreadmoorColors.accentCyan.withOpacity(0.12)
                    : DreadmoorColors.surface.withOpacity(0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: DreadmoorColors.accentCyan.withOpacity(
                      _pressed ? 0.8 : 0.4),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: DreadmoorColors.accentCyan.withOpacity(0.9),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: GoogleFonts.michroma(
                      fontSize: 15,
                      letterSpacing: 3.0,
                      color: DreadmoorColors.accentCyan.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
