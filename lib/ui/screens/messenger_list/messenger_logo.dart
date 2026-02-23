import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

/// Standalone "MESSENGER" logo with a stylized gun passing through the text.
/// Pure Flutter — no PNG assets required.
class MessengerLogo extends StatelessWidget {
  final double height;
  final Color color;

  const MessengerLogo({
    super.key,
    this.height = 44,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _MessengerLogoPainter(color: color),
        // Wide enough to fit the word + gun
        size: Size(height * 6.5, height),
      ),
    );
  }
}

class _MessengerLogoPainter extends CustomPainter {
  final Color color;
  const _MessengerLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2; // horizontal center
    final cy = h / 2; // vertical center (gun barrel axis)

    // ── Paints ────────────────────────────────────────────────────────
    final textPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final gunPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final gunStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ── Text: "MESS" on the left, "ENGER" on the right ───────────────
    // Split the word so the gun visually passes through the gap between
    // "MESS" and "ENGER", crossing through the S/E letterforms.

    final fontSize = h * 0.42;
    final letterSpacing = h * 0.08;

    // Left half: MESS
    _drawText(
      canvas,
      text: 'MESS',
      x: 0,
      y: cy,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      color: color,
      align: TextAlign.left,
    );

    // Right half: ENGER
    _drawText(
      canvas,
      text: 'ENGER',
      x: w,
      y: cy,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      color: color,
      align: TextAlign.right,
    );

    // ── Gun silhouette (passes through center horizontally) ───────────
    // All dimensions relative to height (h) for scalability.
    // The gun is oriented horizontally, barrel pointing RIGHT.
    // Total gun width ≈ 42% of logo width.

    final gw = w * 0.42; // total gun width
    final gl = cx - gw / 2; // gun left edge (x)
    final gr = gl + gw; // gun right edge (x)

    final barrelH = h * 0.065; // barrel thickness
    final barrelY = cy - barrelH / 2;
    final slideH = h * 0.22; // slide/body height (above + barrel)
    final slideTop = cy - slideH;

    final gripW = gw * 0.28;
    final gripH = h * 0.38;
    final gripX = gl + gw * 0.52; // grip starts ~52% into gun

    // 1. Barrel (thin horizontal rod)
    final barrelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(gl, barrelY, gw * 0.55, barrelH),
      Radius.circular(barrelH / 2),
    );
    canvas.drawRRect(barrelRect, gunPaint);

    // 2. Slide / upper receiver (above barrel)
    final slidePath = Path()
      ..moveTo(gl + gw * 0.08, slideTop)
      ..lineTo(gr - gripW * 0.1, slideTop)
      ..lineTo(gr - gripW * 0.1, cy + barrelH / 2)
      ..lineTo(gl + gw * 0.08, cy + barrelH / 2)
      ..close();
    canvas.drawPath(slidePath, gunPaint);

    // Ejection port cutout on slide (makes it look like a real pistol)
    final cutoutPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    final cutoutRect = Rect.fromLTWH(
      gl + gw * 0.3,
      slideTop + h * 0.02,
      gw * 0.22,
      slideH * 0.45,
    );
    canvas.drawRect(cutoutRect, cutoutPaint);

    // 3. Grip (angled downward from rear of slide)
    final gripPath = Path()
      ..moveTo(gripX, cy + barrelH / 2) // top-left of grip
      ..lineTo(gripX + gripW, cy + barrelH / 2) // top-right
      ..lineTo(gripX + gripW + h * 0.04, cy + gripH) // bottom-right (angled)
      ..lineTo(gripX - h * 0.01, cy + gripH) // bottom-left
      ..close();
    canvas.drawPath(gripPath, gunPaint);

    // Grip texture lines (horizontal hatching)
    final hatchPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 1; i < 4; i++) {
      final lineY = cy + barrelH / 2 + (gripH * i / 4.5);
      canvas.drawLine(
        Offset(gripX + h * 0.01, lineY),
        Offset(gripX + gripW - h * 0.01, lineY),
        hatchPaint,
      );
    }

    // 4. Trigger guard (teardrop loop below barrel)
    final tgX = gripX - gw * 0.10;
    final tgY = cy + barrelH / 2;
    final tgW = gripW * 0.75;
    final tgH = h * 0.18;
    final tgPath = Path()
      ..moveTo(tgX, tgY)
      ..quadraticBezierTo(tgX - tgW * 0.1, tgY + tgH, tgX + tgW * 0.5, tgY + tgH)
      ..quadraticBezierTo(tgX + tgW * 1.1, tgY + tgH, tgX + tgW, tgY)
      ..lineTo(tgX, tgY);
    canvas.drawPath(tgPath, gunStroke);

    // 5. Trigger inside the guard
    final trigPaint = Paint()
      ..color = color
      ..strokeWidth = h * 0.03
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(tgX + tgW * 0.42, tgY + tgH * 0.15),
      Offset(tgX + tgW * 0.50, tgY + tgH * 0.8),
      trigPaint,
    );

    // 6. Muzzle cap at barrel tip
    final muzzleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(gl, barrelY - h * 0.04, h * 0.06, barrelH + h * 0.08),
      const Radius.circular(2),
    );
    canvas.drawRRect(muzzleRect, gunPaint);

    // 7. Sight on top of slide
    final sightPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(gl + gw * 0.62, slideTop - h * 0.04, h * 0.04, h * 0.06),
      sightPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(gl + gw * 0.14, slideTop - h * 0.03, h * 0.03, h * 0.045),
      sightPaint,
    );
  }

  void _drawText(
    Canvas canvas, {
    required String text,
    required double x,
    required double y,
    required double fontSize,
    required double letterSpacing,
    required Color color,
    required TextAlign align,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Michroma', // matches GoogleFonts.michroma
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
        height: 1.0,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: double.infinity);

    final offsetX = align == TextAlign.right ? x - tp.width : x;
    tp.paint(canvas, Offset(offsetX, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(_MessengerLogoPainter old) => old.color != color;
}
