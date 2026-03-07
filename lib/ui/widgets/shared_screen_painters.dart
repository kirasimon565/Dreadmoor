// lib/ui/widgets/shared_screen_painters.dart
//
// Shared painters and decorative widgets used across utility screens.
// Import in each screen:
//   import 'package:dreadmoor/ui/widgets/shared_screen_painters.dart';
//
// NOTE: All classes are PUBLIC (no _ prefix) so they are importable.
// Previously these were private (_ScanlinePainter etc) which caused
// "method not defined" build errors in every screen that used them.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/ui/theme/colors.dart';

// ─────────────────────────────────────────────────────────────
// Scanline painter — subtle CRT texture, no asset required
// ─────────────────────────────────────────────────────────────

class ScanlinePainter extends CustomPainter {
  const ScanlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// Vignette painter — radial dark edge, colour-tintable
// Used by FatalErrorScreen for red pulse
// ─────────────────────────────────────────────────────────────

class VignettePainter extends CustomPainter {
  final Color color;
  final double intensity;

  const VignettePainter({required this.color, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        radius: 1.1,
        colors: [
          Colors.transparent,
          color.withOpacity(intensity),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant VignettePainter old) =>
      old.intensity != intensity || old.color != color;
}

// ─────────────────────────────────────────────────────────────
// Dossier card — bordered container with surface tint
// ─────────────────────────────────────────────────────────────

class DossierCard extends StatelessWidget {
  final Widget child;
  const DossierCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DreadmoorColors.surface,
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section label — small all-caps heading with trailing rule
// ─────────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.michroma(
              fontSize: 8,
              letterSpacing: 3,
              color: DreadmoorColors.textMeta,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Horizontal rule — gradient fade
// ─────────────────────────────────────────────────────────────

class HRule extends StatelessWidget {
  const HRule({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Redacted bar — horizontal dim block, dossier accent
// ─────────────────────────────────────────────────────────────

class RedactedBar extends StatelessWidget {
  final double width;
  const RedactedBar({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 10,
      color: Colors.white.withOpacity(0.06),
    );
  }
}
