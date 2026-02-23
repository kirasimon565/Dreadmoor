// shared_screen_widgets.dart
// Shared painters and decorative widgets used across:
//   - save_load_screen.dart
//   - credits_screen.dart
//   - fatal_error_screen.dart
//   - legal_disclaimer_screen.dart
//
// Import this file in each screen:
//   import '../../widgets/shared_screen_widgets.dart';
//
// (Or paste the contents of this file directly at the bottom of each screen
//  if you prefer no additional import.)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';

// ─────────────────────────────────────────────────────────────
// Scanline painter — subtle CRT texture, no asset required
// ─────────────────────────────────────────────────────────────

class _ScanlinePainter extends CustomPainter {
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

class _VignettePainter extends CustomPainter {
  final Color color;
  final double intensity;

  const _VignettePainter({required this.color, required this.intensity});

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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _VignettePainter old) =>
      old.intensity != intensity || old.color != color;
}

// ─────────────────────────────────────────────────────────────
// Dossier card — bordered container with surface tint
// ─────────────────────────────────────────────────────────────

class _DossierCard extends StatelessWidget {
  final Widget child;
  const _DossierCard({required this.child});

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
// Section label — small all-caps heading with rule
// ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

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
// Horizontal rule
// ─────────────────────────────────────────────────────────────

class _HRule extends StatelessWidget {
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
// Redacted bar — horizontal black-on-dim bar, dossier accent
// ─────────────────────────────────────────────────────────────

class _RedactedBar extends StatelessWidget {
  final double width;
  const _RedactedBar({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 10,
      color: Colors.white.withOpacity(0.06),
    );
  }
}
