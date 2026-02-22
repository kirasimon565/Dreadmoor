import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/routes.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  void _openDebug(BuildContext context) {
    context.push(Routes.debug);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          // Subtle Grain / Glitch Overlay
          Opacity(
            opacity: 0.035,
            child: Image.asset(
              'assets/ui/glitch_overlay.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),

          Column(
            children: [
              CustomScreenHeader(
                title: "CREDITS",
                onBackPressed: () => context.pop(),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Studio Logo (long-press opens debug)
                        GestureDetector(
                          onLongPress: () => _openDebug(context),
                          child: Image.asset(
                            'assets/branding/blackmoon_logo.png',
                            width: 110,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),

                        const SizedBox(height: 32),

                        Text(
                          "CREATED BY",
                          style: GoogleFonts.michroma(
                            fontSize: 10,
                            color: DreadmoorColors.textMeta,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "BLACKMOON STUDIO",
                          style: GoogleFonts.michroma(
                            fontSize: 16,
                            color: Colors.white,
                            letterSpacing: 2.2,
                          ),
                        ),

                        const SizedBox(height: 40),

                        Text(
                          "DESIGN & DEVELOPMENT",
                          style: GoogleFonts.michroma(
                            fontSize: 10,
                            color: DreadmoorColors.textMeta,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "BLACKMOON STUDIO",
                          style: GoogleFonts.michroma(
                            fontSize: 14,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),

                        const SizedBox(height: 56),

                        GestureDetector(
                          onTap: () => context.push(Routes.legal),
                          child: Text(
                            "LEGAL DISCLAIMER",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              letterSpacing: 1.2,
                              color: DreadmoorColors.accentCyan,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          "© ${DateTime.now().year} BlackMoon Studio",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: DreadmoorColors.textMeta,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
