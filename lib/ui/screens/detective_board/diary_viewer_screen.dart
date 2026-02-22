import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // ✅ Safe lookup — orElse prevents StateError crash if ID not found
    final diary = allEvidence.firstWhereOrNull((e) => e.id == diaryId);

    if (diary == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: DreadmoorColors.accentRed, size: 36),
              const SizedBox(height: 16),
              Text(
                "DIARY NOT FOUND",
                style: GoogleFonts.michroma(
                  fontSize: 12,
                  color: DreadmoorColors.accentRed,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Use .when() so loading and error states are handled properly
    final progressAsync = ref.watch(diaryProgressProvider(diaryId));

    return progressAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child:
              CircularProgressIndicator(color: DreadmoorColors.accentCyan),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "ERROR LOADING DIARY",
            style: GoogleFonts.michroma(
                color: DreadmoorColors.accentRed, letterSpacing: 1.5),
          ),
        ),
      ),
      data: (progress) {
        final fragments =
            (diary.content ?? '').split('\n').where((s) => s.isNotEmpty).toList();
        final visibleCount = (fragments.length * progress).ceil();

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // ── Background ─────────────────────────────────────────
              Positioned.fill(
                child: Image.asset(
                  'assets/backgrounds/diary_bg_texture.png',
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.85),
                  colorBlendMode: BlendMode.darken,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Colors.black),
                ),
              ),

              // ── Grain ──────────────────────────────────────────────
              IgnorePointer(
                child: Opacity(
                  opacity: 0.06,
                  child: Image.asset(
                    'assets/ui/glitch_overlay.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),

              Column(
                children: [
                  // ── Header ───────────────────────────────────────
                  CustomScreenHeader(
                    title: "AUDIO LOG",
                    onBackPressed: () {
                      HapticFeedback.selectionClick();
                      context.pop();
                    },
                  ),

                  // ── Subtitle + recovery bar ───────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "REBECCA'S PRIVATE AUDIO LOG",
                          style: GoogleFonts.michroma(
                            fontSize: 9,
                            letterSpacing: 2.0,
                            color: DreadmoorColors.accentRed.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.08),
                                  color: DreadmoorColors.accentRed,
                                  minHeight: 3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "${(progress * 100).toInt()}% RECOVERED",
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: DreadmoorColors.accentRed,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 0.5,
                          color: DreadmoorColors.accentRed.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),

                  // ── Fragments ─────────────────────────────────────
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                      itemCount: fragments.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final isVisible = index < visibleCount;
                        final text = isVisible
                            ? fragments[index]
                            : "[DATA CORRUPTED]";

                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 600),
                          opacity: isVisible ? 1.0 : 1.0,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isVisible
                                  ? Colors.white.withOpacity(0.03)
                                  : Colors.red.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(2),
                              border: Border(
                                left: BorderSide(
                                  color: isVisible
                                      ? DreadmoorColors.accentRed
                                          .withOpacity(0.35)
                                      : Colors.red.withOpacity(0.15),
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Line number
                                Text(
                                  "LINE ${(index + 1).toString().padLeft(2, '0')}",
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color:
                                        DreadmoorColors.textMeta.withOpacity(0.5),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GlitchText(
                                  text: text,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white
                                        .withOpacity(isVisible ? 0.85 : 0.28),
                                    height: 1.65,
                                  ),
                                  glitchIntensity: isVisible ? 0.08 : 0.9,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
