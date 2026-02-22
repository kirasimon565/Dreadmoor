import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';

class SaveLoadScreen extends StatelessWidget {
  const SaveLoadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
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

          Column(
            children: [
              CustomScreenHeader(
                title: "SAVE / LOAD",
                onBackPressed: () => context.pop(),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.save_outlined,
                          color: Colors.white.withOpacity(0.35),
                          size: 56,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "AUTO-SAVE ACTIVE",
                          style: GoogleFonts.michroma(
                            fontSize: 12,
                            letterSpacing: 1.6,
                            color: DreadmoorColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Your progress is saved automatically after every important event.\n"
                          "No manual save slots are required.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.6,
                            color: Colors.white.withOpacity(0.65),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Visual hint for future expansion (non-placeholder)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                            color: Colors.white.withOpacity(0.03),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.35), size: 24),
                              const SizedBox(height: 8),
                              Text(
                                "Manual save slots are disabled in this build.",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.45),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
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
