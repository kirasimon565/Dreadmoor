import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/investigation_state.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';
import '../../widgets/glitch_text.dart';

class DiaryViewerScreen extends ConsumerWidget {
  final String diaryId;

  const DiaryViewerScreen({super.key, required this.diaryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaryProgress = ref.watch(diaryProgressProvider).value ?? 0.0;

    final diary = allEvidence.firstWhere((e) => e.id == diaryId);

    final fragments = diary.content.split('\n');
    final visibleCount = (fragments.length * diaryProgress).ceil();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          CustomScreenHeader(
            title: "DIARY FRAGMENT",
            onBackPressed: () => context.pop(),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: diaryProgress,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    color: DreadmoorColors.accentRed,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${(diaryProgress * 100).toInt()}% RECOVERED",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: DreadmoorColors.accentRed,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: fragments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final isVisible = index < visibleCount;
                final text = isVisible ? fragments[index] : "[DATA CORRUPTED]";

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: DreadmoorColors.accentRed.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    color: Colors.white.withOpacity(0.02),
                  ),
                  child: GlitchText(
                    text: text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(isVisible ? 0.85 : 0.3),
                      height: 1.6,
                    ),
                    glitchIntensity: isVisible ? 0.1 : 0.9,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
