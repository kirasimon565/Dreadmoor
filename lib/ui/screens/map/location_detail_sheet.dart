import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/map_state.dart';
import '../../theme/colors.dart';

class LocationDetailSheet extends StatelessWidget {
  final MapLocation location;
  const LocationDetailSheet({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F).withOpacity(0.96),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 0.6,
              ),
            ),
          ),
          // ✅ DraggableScrollableSheet content is scrollable so long
          // descriptions never overflow on small screens
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Drag handle ──────────────────────────────
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 6),
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Location image ────────────────────
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.asset(
                                location.imagePath ?? '',
                                fit: BoxFit.cover,
                                // ✅ errorBuilder — no crash if asset missing
                                errorBuilder: (_, __, ___) => Container(
                                  color: DreadmoorColors.surface,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported_outlined,
                                          color:
                                              Colors.white.withOpacity(0.15),
                                          size: 36,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "IMAGE UNAVAILABLE",
                                          style: GoogleFonts.michroma(
                                            fontSize: 9,
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Location type badge ───────────────
                          if (location.type != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: DreadmoorColors.accentRed
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: DreadmoorColors.accentRed
                                        .withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  location.type!.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: DreadmoorColors.accentRed,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                          // ── Title ─────────────────────────────
                          Text(
                            location.title.toUpperCase(),
                            style: GoogleFonts.michroma(
                              fontSize: 16,
                              color: DreadmoorColors.textPrimary,
                              letterSpacing: 2.0,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 14),

                          Container(
                            height: 0.5,
                            color: Colors.white.withOpacity(0.07),
                          ),

                          const SizedBox(height: 14),

                          // ── Description ───────────────────────
                          Text(
                            location.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: DreadmoorColors.textSecondary,
                              height: 1.65,
                            ),
                          ),

                          // ── Evidence tags ─────────────────────
                          if (location.evidenceTags != null &&
                              location.evidenceTags!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text(
                              "LINKED EVIDENCE",
                              style: GoogleFonts.michroma(
                                fontSize: 9,
                                color: DreadmoorColors.textMeta,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: location.evidenceTags!
                                  .map((tag) => _EvidenceTag(tag: tag))
                                  .toList(),
                            ),
                          ],

                          const SizedBox(height: 28),

                          // ── View Evidence button ──────────────
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: DreadmoorColors.accentCyan
                                      .withOpacity(0.4),
                                  width: 0.7,
                                ),
                                backgroundColor: DreadmoorColors.accentCyan
                                    .withOpacity(0.05),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                Navigator.pop(context);
                                // ✅ Navigate to detective board filtered by
                                // this location — wired when board supports
                                // location filter query params
                                context.push(
                                    '/board?filter=LOCATIONS&locationId=${location.id}');
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.folder_open_outlined,
                                    size: 16,
                                    color: DreadmoorColors.accentCyan,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "VIEW EVIDENCE",
                                    style: GoogleFonts.michroma(
                                      fontSize: 11,
                                      color: DreadmoorColors.accentCyan,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ✅ Bottom padding respects home bar
                          SizedBox(height: 16 + bottomPadding),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Evidence tag chip ──────────────────────────────────────────────────────

class _EvidenceTag extends StatelessWidget {
  final String tag;
  const _EvidenceTag({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 0.5,
        ),
      ),
      child: Text(
        tag.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          color: DreadmoorColors.textMeta,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
