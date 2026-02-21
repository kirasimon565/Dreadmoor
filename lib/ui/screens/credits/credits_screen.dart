import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Column(
        children: [
          CustomScreenHeader(
            title: "CREDITS",
            onBackPressed: () => context.pop(),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/branding/blackmoon_logo.png',
                    width: 100,
                    errorBuilder: (c, e, s) => const SizedBox(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "CREATED BY",
                    style: GoogleFonts.michroma(fontSize: 10, color: DreadmoorColors.textMeta, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "BLACKMOON STUDIO",
                    style: GoogleFonts.michroma(fontSize: 14, color: Colors.white, letterSpacing: 2.0),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "DESIGN & DEVELOPMENT",
                    style: GoogleFonts.michroma(fontSize: 10, color: DreadmoorColors.textMeta, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "JULES & YOU",
                    style: GoogleFonts.michroma(fontSize: 14, color: Colors.white, letterSpacing: 2.0),
                  ),
                  const SizedBox(height: 48),
                  GestureDetector(
                    onTap: () => context.push('/legal'),
                    child: Text(
                      "LEGAL DISCLAIMER",
                      style: GoogleFonts.inter(color: DreadmoorColors.accentCyan),
                    ),
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
