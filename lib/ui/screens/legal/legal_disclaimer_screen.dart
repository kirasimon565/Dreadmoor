import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';

class LegalDisclaimerScreen extends StatelessWidget {
  const LegalDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          // Subtle glitch texture
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
                title: "LEGAL",
                onBackPressed: () => context.pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("FICTIONAL DISCLAIMER"),
                      _bodyText(
                        "Dreadmoor: Rebecca Stone Mystery is a work of fiction. "
                        "All names, characters, organizations, locations, and events portrayed in this game are either the products of the author's imagination "
                        "or are used in a fictional manner. Any resemblance to actual persons, living or dead, or to real-world events or locations is purely coincidental.",
                      ),

                      const SizedBox(height: 32),

                      _sectionTitle("INTELLECTUAL PROPERTY"),
                      _bodyText(
                        "All content within this game, including but not limited to storylines, dialogue, characters, artwork, audio, music, and visual designs, "
                        "is the intellectual property of BlackMoon Studio unless otherwise stated. Unauthorized reproduction, redistribution, or modification of any part "
                        "of this game is prohibited.",
                      ),

                      const SizedBox(height: 32),

                      _sectionTitle("LIABILITY DISCLAIMER"),
                      _bodyText(
                        "The developers and publishers of this game assume no responsibility for any direct or indirect damages arising from the use of this software. "
                        "This game is provided \"as is\" without warranties of any kind, express or implied.",
                      ),

                      const SizedBox(height: 32),

                      _sectionTitle("DATA & PRIVACY"),
                      _bodyText(
                        "This game stores gameplay progress locally on your device. No personal data is transmitted to external servers. "
                        "Deleting the app or clearing local storage will permanently erase your progress.",
                      ),

                      const SizedBox(height: 48),

                      Center(
                        child: Text(
                          "© ${DateTime.now().year} BLACKMOON STUDIO. ALL RIGHTS RESERVED.",
                          style: GoogleFonts.michroma(
                            fontSize: 10,
                            letterSpacing: 1.5,
                            color: DreadmoorColors.textMeta,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.michroma(
          fontSize: 12,
          color: DreadmoorColors.accentCyan,
          letterSpacing: 1.8,
        ),
      ),
    );
  }

  Widget _bodyText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.white.withOpacity(0.82),
        height: 1.7,
      ),
    );
  }
}
