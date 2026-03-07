import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';

import '../../../core/state/investigation_state.dart';
import 'package:dreadmoor/ui/theme/colors.dart';

class EvidenceDetailScreen extends ConsumerWidget {
  final String evidenceId;
  const EvidenceDetailScreen({super.key, required this.evidenceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Safe lookup — no crash if evidence ID doesn't exist
    final evidence = allEvidence.firstWhereOrNull((e) => e.id == evidenceId);

    if (evidence == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            "NOT FOUND",
            style: GoogleFonts.michroma(
              color: DreadmoorColors.accentRed,
              fontSize: 13,
            ),
          ),
        ),
        body: Center(
          child: Text(
            "EVIDENCE NOT FOUND",
            style: GoogleFonts.michroma(
              color: DreadmoorColors.accentRed,
              letterSpacing: 2.0,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Zoomable evidence image ───────────────────────────────────
          Positioned.fill(
            child: InteractiveViewer(
              // ✅ minScale 0.5 so image can zoom out if it overflows screen
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: Hero(
                  tag: 'evidence_${evidence.id}',
                  child: Image.asset(
                    evidence.imagePath ?? '',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white.withOpacity(0.2),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "IMAGE UNAVAILABLE",
                          style: GoogleFonts.michroma(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.3),
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Top overlay header ────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 12,
                    left: 8,
                    right: 16,
                  ),
                  color: Colors.black.withOpacity(0.72),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.pop();
                        },
                        tooltip: 'Close',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              evidence.title,
                              style: GoogleFonts.michroma(
                                fontSize: 13,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (evidence.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                evidence.subtitle!,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.45),
                                  letterSpacing: 0.8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          evidence.type.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            color: Colors.white.withOpacity(0.55),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Pinch-to-zoom hint (shown briefly on first open) ──────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Center(child: _ZoomHint()),
          ),
        ],
      ),
    );
  }
}

// ── Zoom hint — fades out after 2 seconds ──────────────────────────────────

class _ZoomHint extends StatefulWidget {
  @override
  State<_ZoomHint> createState() => _ZoomHintState();
}

class _ZoomHintState extends State<_ZoomHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0,
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Hold for 1.8s then fade out
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.zoom_in_rounded,
              size: 14,
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(width: 6),
            Text(
              "Pinch to zoom",
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
