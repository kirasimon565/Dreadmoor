import 'package:flutter/material.dart';

/// Animated MESSENGER logo.
/// A pistol enters from the left, fires a bullet that slices through
/// the word "MESSENGER" — text splits apart as the bullet passes —
/// then the text snaps back and the gun exits. Loops forever.
class MessengerLogo extends StatefulWidget {
  final double height;
  final Color color;

  const MessengerLogo({
    super.key,
    this.height = 40,
    this.color = Colors.white,
  });

  @override
  State<MessengerLogo> createState() => _MessengerLogoState();
}

class _MessengerLogoState extends State<MessengerLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Total loop: 3.2 seconds — snappy but readable
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.height * 7.0;
    return SizedBox(
      width: w,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            painter: _LogoPainter(
              t: _controller.value,
              color: widget.color,
            ),
            size: Size(w, widget.height),
          );
        },
      ),
    );
  }
}

// ── Animation timeline ─────────────────────────────────────────────────────
//
//  0.00 – 0.12  Gun slides in from left edge
//  0.12 – 0.18  Gun pauses, aims (slight pause before firing)
//  0.18 – 0.20  Muzzle flash
//  0.20 – 0.62  Bullet travels right across full width
//               Text splits open as bullet passes through each letter
//  0.62 – 0.72  Bullet exits right, text snaps back together
//  0.72 – 0.82  Gun slides back out left
//  0.82 – 1.00  Hold (empty frame, breathe before next loop)

class _LogoPainter extends CustomPainter {
  final double t; // 0.0 → 1.0 animation progress
  final Color color;

  const _LogoPainter({required this.t, required this.color});

  // ── Easing helpers ─────────────────────────────────────────────────
  double _clampMap(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  double _easeOut(double x) => 1 - (1 - x) * (1 - x);
  double _easeIn(double x) => x * x;
  double _easeInOut(double x) =>
      x < 0.5 ? 2 * x * x : 1 - (-2 * x + 2) * (-2 * x + 2) / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cy = h / 2; // vertical center

    // ── Gun entrance (0.0 – 0.12) ──────────────────────────────────
    final gunEnter = _easeOut(_clampMap(t, 0.0, 0.12));
    // ── Gun exit (0.72 – 0.82) ──────────────────────────────────────
    final gunExit = _easeIn(_clampMap(t, 0.72, 0.82));
    // Gun x: starts off-screen left, enters to 12% of width, then exits
    final gunTargetX = w * 0.08;
    final gunX = gunTargetX * gunEnter - w * 0.12 * gunExit;

    // ── Bullet travel (0.20 – 0.62) ─────────────────────────────────
    final bulletProgress = _easeInOut(_clampMap(t, 0.20, 0.62));
    final bulletVisible = t >= 0.20 && t <= 0.68;
    // Bullet travels from gun tip across full width
    final bulletStartX = gunX + h * 0.6; // from muzzle
    final bulletX = bulletStartX + (w - bulletStartX) * bulletProgress;

    // ── Muzzle flash (0.18 – 0.22) ──────────────────────────────────
    final flashProgress = _clampMap(t, 0.18, 0.22);
    final flashAlpha = flashProgress < 0.3
        ? flashProgress / 0.3
        : 1.0 - (flashProgress - 0.3) / 0.7;

    // ── Text split: letters above/below the bullet path ──────────────
    // As bullet passes through each character, the two halves of the
    // word separate vertically. splitAmount peaks when bullet is
    // mid-word and fades as bullet exits.
    final textSplitAmount = bulletVisible
        ? _easeInOut(_clampMap(t, 0.20, 0.55)) *
              (1.0 - _easeIn(_clampMap(t, 0.58, 0.68))) *
              h * 0.22
        : 0.0;

    // ── Draw ──────────────────────────────────────────────────────────

    // 1. "MESSENGER" text — split into top half and bottom half
    _drawSplitText(
      canvas,
      text: 'MESSENGER',
      size: size,
      cy: cy,
      bulletX: bulletVisible ? bulletX : -1,
      splitAmount: textSplitAmount,
      color: color,
    );

    // 2. Gun (if entering or visible or exiting)
    if (t < 0.85) {
      _drawGun(canvas, x: gunX, cy: cy, h: h, color: color);
    }

    // 3. Bullet
    if (bulletVisible) {
      _drawBullet(canvas, x: bulletX, cy: cy, h: h, color: color);
    }

    // 4. Muzzle flash
    if (flashAlpha > 0.01 && t < 0.85) {
      _drawMuzzleFlash(
        canvas,
        x: gunX + h * 0.6,
        cy: cy,
        h: h,
        alpha: flashAlpha,
        color: color,
      );
    }
  }

  // ── Text renderer — clips top/bottom halves and offsets them ────────
  void _drawSplitText(
    Canvas canvas, {
    required String text,
    required Size size,
    required double cy,
    required double bulletX, // -1 = no bullet
    required double splitAmount,
    required Color color,
  }) {
    final h = size.height;
    final fontSize = h * 0.38;
    final letterSpacing = h * 0.06;

    final span = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Michroma',
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
        height: 1.0,
      ),
    );
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();

    // Center the text horizontally
    final textX = (size.width - tp.width) / 2;
    final textY = cy - tp.height / 2;

    if (splitAmount < 0.5) {
      // No split — draw normally
      tp.paint(canvas, Offset(textX, textY));
      return;
    }

    // Draw top half (above cy) shifted UP
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, cy));
    tp.paint(canvas, Offset(textX, textY - splitAmount));
    canvas.restore();

    // Draw bottom half (below cy) shifted DOWN
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, cy, size.width, size.height - cy));
    tp.paint(canvas, Offset(textX, textY + splitAmount));
    canvas.restore();

    // Draw a thin gap line where the split is (bullet channel)
    if (bulletX > 0) {
      final gapPaint = Paint()
        ..color = color.withOpacity(0.08)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(textX, cy - splitAmount, tp.width, splitAmount * 2),
        gapPaint,
      );
    }
  }

  // ── Compact pistol silhouette ────────────────────────────────────────
  void _drawGun(
    Canvas canvas, {
    required double x,
    required double cy,
    required double h,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Proportions relative to h
    final barrelLen = h * 0.55;
    final barrelH = h * 0.07;
    final slideH = h * 0.20;
    final gripW = h * 0.14;
    final gripH = h * 0.30;

    final barrelY = cy - barrelH / 2;
    final slideTop = cy - slideH;
    final gripX = x + barrelLen * 0.55;

    // Barrel
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, barrelY, barrelLen, barrelH),
        Radius.circular(barrelH / 2),
      ),
      paint,
    );

    // Slide
    final slide = Path()
      ..moveTo(x + barrelLen * 0.05, slideTop)
      ..lineTo(gripX + gripW * 0.9, slideTop)
      ..lineTo(gripX + gripW * 0.9, cy + barrelH / 2)
      ..lineTo(x + barrelLen * 0.05, cy + barrelH / 2)
      ..close();
    canvas.drawPath(slide, paint);

    // Ejection port cutout
    canvas.drawRect(
      Rect.fromLTWH(
        x + barrelLen * 0.32,
        slideTop + h * 0.03,
        barrelLen * 0.20,
        slideH * 0.42,
      ),
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill,
    );

    // Grip
    final grip = Path()
      ..moveTo(gripX, cy + barrelH / 2)
      ..lineTo(gripX + gripW, cy + barrelH / 2)
      ..lineTo(gripX + gripW + h * 0.03, cy + gripH)
      ..lineTo(gripX, cy + gripH)
      ..close();
    canvas.drawPath(grip, paint);

    // Trigger guard
    final tgPath = Path()
      ..moveTo(gripX - h * 0.06, cy + barrelH / 2)
      ..quadraticBezierTo(
        gripX - h * 0.08, cy + gripH * 0.5,
        gripX + gripW * 0.5, cy + gripH * 0.48,
      )
      ..quadraticBezierTo(
        gripX + gripW * 1.05, cy + gripH * 0.5,
        gripX + gripW, cy + barrelH / 2,
      );
    canvas.drawPath(tgPath, strokePaint);

    // Trigger
    canvas.drawLine(
      Offset(gripX + gripW * 0.35, cy + barrelH),
      Offset(gripX + gripW * 0.42, cy + gripH * 0.55),
      strokePaint,
    );

    // Muzzle block
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - h * 0.02, barrelY - h * 0.03, h * 0.05, barrelH + h * 0.06),
        const Radius.circular(1.5),
      ),
      paint,
    );

    // Rear sight
    canvas.drawRect(
      Rect.fromLTWH(gripX - h * 0.01, slideTop - h * 0.035, h * 0.035, h * 0.045),
      paint,
    );
    // Front sight
    canvas.drawRect(
      Rect.fromLTWH(x + barrelLen * 0.60, slideTop - h * 0.03, h * 0.025, h * 0.035),
      paint,
    );
  }

  // ── Bullet ───────────────────────────────────────────────────────────
  void _drawBullet(
    Canvas canvas, {
    required double x,
    required double cy,
    required double h,
    required Color color,
  }) {
    final bh = h * 0.06;
    final bw = h * 0.18;

    // Casing
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - bw, cy - bh / 2, bw * 0.65, bh),
        Radius.circular(bh * 0.2),
      ),
      Paint()
        ..color = color.withOpacity(0.55)
        ..style = PaintingStyle.fill,
    );

    // Tip (pointed)
    final tipPath = Path()
      ..moveTo(x - bw * 0.35, cy - bh / 2)
      ..lineTo(x, cy)
      ..lineTo(x - bw * 0.35, cy + bh / 2)
      ..close();
    canvas.drawPath(
      tipPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Motion trail (fades left)
    for (int i = 1; i <= 5; i++) {
      final trailX = x - bw - (i * h * 0.07);
      final opacity = (1.0 - i / 6.0) * 0.25;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(trailX, cy),
          width: h * 0.10 / i,
          height: bh * 0.5,
        ),
        Paint()
          ..color = color.withOpacity(opacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  // ── Muzzle flash ─────────────────────────────────────────────────────
  void _drawMuzzleFlash(
    Canvas canvas, {
    required double x,
    required double cy,
    required double h,
    required double alpha,
    required Color color,
  }) {
    final flashPaint = Paint()
      ..color = color.withOpacity(alpha * 0.9)
      ..style = PaintingStyle.fill;

    // Central cone
    final cone = Path()
      ..moveTo(x, cy - h * 0.04)
      ..lineTo(x + h * 0.22, cy)
      ..lineTo(x, cy + h * 0.04)
      ..close();
    canvas.drawPath(cone, flashPaint);

    // Top spike
    canvas.drawPath(
      Path()
        ..moveTo(x + h * 0.04, cy - h * 0.02)
        ..lineTo(x + h * 0.18, cy - h * 0.10)
        ..lineTo(x + h * 0.10, cy - h * 0.01)
        ..close(),
      flashPaint..color = color.withOpacity(alpha * 0.6),
    );

    // Bottom spike
    canvas.drawPath(
      Path()
        ..moveTo(x + h * 0.04, cy + h * 0.02)
        ..lineTo(x + h * 0.18, cy + h * 0.10)
        ..lineTo(x + h * 0.10, cy + h * 0.01)
        ..close(),
      flashPaint..color = color.withOpacity(alpha * 0.6),
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.t != t || old.color != color;
}
