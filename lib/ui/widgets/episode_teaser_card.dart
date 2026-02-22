import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/colors.dart';

class EpisodeTeaserCard extends StatelessWidget {
  final String episodeId;
  final String title;
  final String description;
  final bool isLocked;
  final double progress;
  final VoidCallback onTap;

  const EpisodeTeaserCard({
    super.key,
    required this.episodeId,
    required this.title,
    required this.description,
    required this.isLocked,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Opacity(
      opacity: isLocked ? 0.7 : 1.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isLocked ? null : onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: DreadmoorColors.surface.withOpacity(0.5),
            border: Border.all(
              color: isLocked
                  ? Colors.white.withOpacity(0.1)
                  : DreadmoorColors.accentCyan.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(11)),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 140,
                      child: isLocked
                          ? const ColoredBox(color: Colors.black)
                          : Image.asset(
                              'assets/episodes/$episodeId/cover.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const ColoredBox(color: Colors.black),
                            ),
                    ),
                    // Darken for readability
                    Container(
                      height: 140,
                      color: Colors.black.withOpacity(0.45),
                    ),
                    if (isLocked)
                      Positioned.fill(
                        child: Image.asset(
                          'assets/ui/locked_episode_overlay.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(Icons.lock,
                                color: Colors.white.withOpacity(0.4), size: 42),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "EPISODE ${episodeId.replaceAll(RegExp(r'[^0-9]'), '')}",
                          style: GoogleFonts.michroma(
                            fontSize: 10,
                            color: DreadmoorColors.textMeta,
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (!isLocked)
                          Text(
                            "${(progress * 100).clamp(0, 100).toInt()}% COMPLETE",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: DreadmoorColors.accentCyan,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.michroma(
                        fontSize: 16,
                        color: isLocked
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLocked
                          ? "Complete the previous episode to unlock."
                          : description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Progress / Action
              if (!isLocked)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 2,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        DreadmoorColors.accentCyan.withOpacity(0.9),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          progress > 0 ? "RESUME EPISODE" : "START EPISODE",
                          style: GoogleFonts.michroma(
                            fontSize: 12,
                            color: DreadmoorColors.accentCyan,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
