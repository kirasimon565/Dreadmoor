import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/game_state.dart';
import '../../theme/colors.dart';
import '../../widgets/fog_video_background.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  void _continueGame() async {
    // Logic to resume last active thread
    final threadId = ref.read(activeThreadIdProvider);
    if (threadId != null) {
      context.go('/chat/$threadId');
    } else {
      context.go('/messenger');
    }
  }

  void _startNewGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DreadmoorColors.surface,
        title: Text("START NEW GAME?", style: GoogleFonts.michroma(color: DreadmoorColors.accentRed)),
        content: Text(
          "This will erase your current progress. Are you sure?",
          style: GoogleFonts.inter(color: DreadmoorColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: GoogleFonts.michroma(color: DreadmoorColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetAndStart();
            },
            child: Text("CONFIRM", style: GoogleFonts.michroma(color: DreadmoorColors.accentRed)),
          ),
        ],
      ),
    );
  }

  void _resetAndStart() async {
    // TODO: Implement full reset logic via GlobalScheduler or DB
    // For now, just go to setup or first episode
    // await db.delete(db.messages).go();
    // await db.delete(db.threads).go();
    // await db.delete(db.storyState).go();
    // This logic should be robust.

    // Start Ep01
    final scheduler = ref.read(globalSchedulerProvider);
    await scheduler.startThread('ep01', 'amelia_chat');
    if (mounted) context.go('/messenger');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          // [0] Video Background
          // Assuming FogVideoBackground is implemented in widgets/fog_video_background.dart
          // and imported. If not, this will fail. But I checked and it exists.
          // Wait, imports? Yes.
          const Positioned.fill(
            child: FogVideoBackground(
              assetPath: 'assets/backgrounds/welcome_fog_loop.mp4',
              darkenOpacity: 0.65,
            ),
          ),

          // [1] Glitch Overlay
          Opacity(
            opacity: 0.04,
            child: Image.asset(
              'assets/ui/glitch_overlay.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (c,e,s) => const SizedBox(),
            ),
          ),

          // [2] Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo
                Center(
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: DreadmoorColors.accentCyan.withOpacity(0.12),
                              blurRadius: 40,
                              spreadRadius: 0,
                            )
                          ]
                        ),
                        child: Image.asset(
                          'assets/branding/dreadmore_logo.png',
                          width: 220,
                          errorBuilder: (c,e,s) => Text("DREADMOOR", style: GoogleFonts.cinzel(fontSize: 40, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 56),

                // Menu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MenuItem(label: "CONTINUE", onTap: _continueGame),
                      const SizedBox(height: 20),
                      _MenuItem(label: "NEW GAME", onTap: _startNewGame),
                      const SizedBox(height: 20),
                      _MenuItem(label: "EPISODES", onTap: () => context.push('/episodes')),
                      const SizedBox(height: 20),
                      _MenuItem(label: "SETTINGS", onTap: () => context.push('/settings')),
                      const SizedBox(height: 20),
                      _MenuItem(label: "CREDITS", onTap: () => context.push('/credits')),
                      const SizedBox(height: 20),
                      _MenuItem(label: "SAVE / LOAD", onTap: () => context.push('/save')),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
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
                        "v0.1.0",
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) {
        setState(() => _isHovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _isHovered ? 0.6 : 1.0,
        child: Row(
          mainAxisSize: MainAxisSize.min, // Ensure row doesn't take full width if not needed, but spec implied full width hits? No, just row.
          children: [
            Text(
              "➤",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: DreadmoorColors.accentCyan,
              ),
            ),
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
