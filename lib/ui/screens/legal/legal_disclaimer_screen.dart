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
      body: Column(
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
                  Text(
                    "FICTIONAL DISCLAIMER",
                    style: GoogleFonts.michroma(fontSize: 12, color: DreadmoorColors.accentCyan),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "This game is a work of fiction. Names, characters, businesses, places, events, locales, and incidents are either the products of the author's imagination or used in a fictitious manner. Any resemblance to actual persons, living or dead, or actual events is purely coincidental.",
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8), height: 1.6),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "TERMS OF USE",
                    style: GoogleFonts.michroma(fontSize: 12, color: DreadmoorColors.accentCyan),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "By playing this game, you agree to...",
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8), height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
