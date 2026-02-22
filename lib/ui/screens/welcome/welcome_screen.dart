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

  void _continueGame() {
    final threadId = ref.read(activeThreadIdProvider);
    if (threadId != null) {
      context.go(Routes.chat(threadId));
    } else {
      context.go(Routes.messenger);
    }
  }

  void _startNewGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DreadmoorColors.surface,
        title: Text(
          "START NEW GAME?",
          style: GoogleFonts.michroma(color: DreadmoorColors.accentRed),
        ),
        content: Text(
          "This will erase your current progress. Are you sure?",
          style: GoogleFonts.inter(color: DreadmoorColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL",
                style: GoogleFonts.michroma(
                    color: DreadmoorColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetAndStart();
            },
            child: Text("CONFIRM",
                style: GoogleFonts.michroma(
                    color: DreadmoorColors.accentRed)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAndStart() async {
    HapticFeedback.mediumImpact();
    final scheduler = ref.read(globalSchedulerProvider);
    await scheduler.resetAll();
    await scheduler.startThread('ep01', 'amelia_chat');
    if (mounted) context.go(Routes.messenger);
  }

  void _openDebug() {
    if (!isDebugMode) return;
    HapticFeedback.heavyImpact();
    context.push('/debug');
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: FogVideoBackground(
              assetPath: 'assets/backgrounds/welcome_fog_loop.mp4',
              darkenOpacity: 0.65,
            ),
          ),

          IgnorePointer(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/ui/glitch_overlay.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                Center(
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: reduceMotion ? 1.0 : _scaleAnimation.value,
                      child: GestureDetector(
                        onLongPress: _openDebug,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: DreadmoorColors.accentCyan.withOpacity(0.2),
                                blurRadius: 40,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/branding/dreadmore_logo.png',
                            width: 220,
                            errorBuilder: (_, __, ___) => Text(
                              "DREADMOOR",
                              style: GoogleFonts.cinzel(
                                fontSize: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 56),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MenuItem(label: "CONTINUE", onTap: _continueGame),
                      const SizedBox(height: 24),
                      _MenuItem(label: "START GAME", onTap: _startNewGame),
                      const SizedBox(height: 24),
                      _MenuItem(
                        label: "CREDITS",
                        onTap: () => context.push(Routes.credits),
                      ),
                      const SizedBox(height: 24),
                      _MenuItem(
                        label: "SETTINGS",
                        onTap: () => context.push(Routes.settings),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "BLACKMOON",
                        style: GoogleFonts.michroma(
                          fontSize: 10,
                          letterSpacing: 2.0,
                          color: Colors.white.withOpacity(0.35),
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

class _MenuItem extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.label,
    required this.onTap,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.6 : 1.0,
        child: Row(
          children: [
            Text("➤",
                style: GoogleFonts.inter(
                    fontSize: 14, color: DreadmoorColors.accentCyan)),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: GoogleFonts.michroma(
                fontSize: 16,
                letterSpacing: 2.0,
                color: DreadmoorColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
