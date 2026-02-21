import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/colors.dart';

class EvidenceDetailScreen extends StatelessWidget {
  const EvidenceDetailScreen({super.key, required this.evidenceId});

  final String evidenceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.07,
              child: Image.asset('assets/ui/glitch_overlay.png', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: context.pop,
                    child: Text(
                      'BACK',
                      style: GoogleFonts.michroma(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FORENSIC DOSSIER',
                                style: GoogleFonts.michroma(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: DreadmoorColors.accentCyan,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                evidenceId.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                  color: DreadmoorColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'CHAIN OF CUSTODY VERIFIED. CONTENT LOCKED TO STORY PROGRESSION FLAGS. METADATA, SOURCE FRAMES, AND TIMELINE ANNOTATIONS ARE AVAILABLE WHEN UNSEALED.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  height: 1.7,
                                  letterSpacing: 0.3,
                                  color: DreadmoorColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
