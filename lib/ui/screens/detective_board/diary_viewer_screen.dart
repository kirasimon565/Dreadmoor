import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';
import '../../widgets/glitch_text.dart';

class DiaryViewerScreen extends StatefulWidget {
  final String diaryId;

  const DiaryViewerScreen({super.key, required this.diaryId});

  @override
  State<DiaryViewerScreen> createState() => _DiaryViewerScreenState();
}

class _DiaryViewerScreenState extends State<DiaryViewerScreen> {
  // Mock data
  final double recoveryPercentage = 0.42;
  final List<String> fragments = [
    "I saw him again today...",
    "[STATIC] near the old factory...",
    "He was holding a [REDACTED]...",
    "Why can't I remember [STATIC]...",
  ];

  @override
  Widget build(BuildContext context) {
    // If I didn't pass diaryId in constructor, I can get it here:
    final state = GoRouterState.of(context);
    final diaryId = state.pathParameters['diaryId'] ?? widget.diaryId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          CustomScreenHeader(
            title: "AUDIO LOG: $diaryId",
            onBackPressed: () => context.pop(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    "REBECCA'S PRIVATE AUDIO LOG",
                    style: GoogleFonts.michroma(fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // Recovery Bar
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: recoveryPercentage,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: DreadmoorColors.accentRed,
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${(recoveryPercentage * 100).toInt()}% RECOVERED",
                        style: GoogleFonts.inter(fontSize: 10, color: DreadmoorColors.accentRed),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Transcript
                  Expanded(
                    child: ListView.separated(
                      itemCount: fragments.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final text = fragments[index];
                        // If text contains [STATIC], maybe style it differently
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: DreadmoorColors.accentRed.withValues(alpha: 0.3), width: 2)),
                            color: Colors.white.withValues(alpha: 0.02),
                          ),
                          child: GlitchText(
                            text: text,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.6,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                            glitchIntensity: text.contains('[STATIC]') ? 0.8 : 0.1,
                          ),
                        );
                      },
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
