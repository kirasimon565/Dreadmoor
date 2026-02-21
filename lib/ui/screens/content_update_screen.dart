import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../theme/colors.dart';
import '../widgets/glitch_text.dart';

class ContentUpdateScreen extends StatelessWidget {
  const ContentUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset('assets/ui/glitch_overlay.png', fit: BoxFit.cover),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlitchText(
                  text: 'DOWNLOADING ENCRYPTED DATA...',
                  glitchIntensity: 0.7,
                  style: GoogleFonts.michroma(
                    fontSize: 12,
                    letterSpacing: 2,
                    color: DreadmoorColors.accentCyan,
                  ),
                ),
                const SizedBox(height: 16),
                Lottie.asset('assets/ui/loading_dots_anim.json', width: 56),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
