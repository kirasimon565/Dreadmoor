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
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isLocked ? Colors.white.withOpacity(0.1) : DreadmoorColors.accentCyan.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Image Placeholder
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                image: isLocked ? null : DecorationImage(
                  image: AssetImage('assets/episodes/$episodeId/cover.png'), // Assuming asset structure
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
                ),
              ),
              child: isLocked
                  ? Center(child: Icon(Icons.lock, color: Colors.white.withOpacity(0.3), size: 48))
                  : null,
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
                        style: GoogleFonts.michroma(fontSize: 10, color: DreadmoorColors.textMeta, letterSpacing: 1.5),
                      ),
                      if (!isLocked)
                        Text(
                          "${(progress * 100).toInt()}% COMPLETE",
                          style: GoogleFonts.inter(fontSize: 10, color: DreadmoorColors.accentCyan),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.michroma(
                      fontSize: 16,
                      color: isLocked ? Colors.white.withOpacity(0.4) : Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLocked ? "Complete previous episode to unlock." : description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Action Bar
            if (!isLocked)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: Center(
                  child: Text(
                    progress > 0 ? "RESUME EPISODE" : "START EPISODE",
                    style: GoogleFonts.michroma(fontSize: 12, color: DreadmoorColors.accentCyan, letterSpacing: 2.0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
