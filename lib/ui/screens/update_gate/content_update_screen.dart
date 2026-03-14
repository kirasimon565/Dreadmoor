import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/ui/navigation/routes.dart';
import 'package:dreadmoor/ui/theme/colors.dart';

class ContentUpdateScreen extends StatefulWidget {
  const ContentUpdateScreen({super.key});

  @override
  State<ContentUpdateScreen> createState() => _ContentUpdateScreenState();
}

class _ContentUpdateScreenState extends State<ContentUpdateScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _runUpdateCheck();
  }

  Future<void> _runUpdateCheck() async {
    // 🔐 Hook real update logic here later (content manifest, checksum, version gate, etc)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    context.go(Routes.welcome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background(Theme.of(context).brightness),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle glitch texture
          Opacity(
            opacity: 0.03,
            child: Image.asset(
              'assets/ui/glitch_overlay.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),

          // Vignette
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                  Colors.black,
                ],
                stops: const [0.2, 0.7, 1.0],
              ),
            ),
          ),

          // Center Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(
                      DreadmoorColors.investigatorCyan,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  "VERIFYING CONTENT",
                  style: GoogleFonts.michroma(
                    fontSize: 12,
                    letterSpacing: 2.5,
                    color: DreadmoorColors.text(Theme.of(context).brightness),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Ensuring all episodes are up to date...",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.55),
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
