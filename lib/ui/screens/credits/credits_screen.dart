import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/routes.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';
import '../../widgets/shared_screen_painters.dart'; // FIX: was private classes

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: const ScanlinePainter()),
          ),

          Column(
            children: [
              CustomScreenHeader(
                title: 'CREDITS',
                onBackPressed: () => context.pop(),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                  child: Column(
                    children: [
                      // ── Studio logo — long-press opens debug ──────────
                      GestureDetector(
                        onLongPress: () => context.push(Routes.debug),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: Image.asset(
                                'assets/branding/blackmoon_logo.png',
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => CustomPaint(
                                  painter: _FallbackLogoPainter(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _StampText(text: 'BLACKMOON STUDIO'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                      const HRule(),

                      const SizedBox(height: 32),
                      const _CreditRow(role: 'CREATED BY', name: 'BLACKMOON STUDIO'),
                      const SizedBox(height: 24),
                      const _CreditRow(role: 'DESIGN & DEVELOPMENT', name: 'BLACKMOON STUDIO'),
                      const SizedBox(height: 24),
                      const _CreditRow(role: 'STORY & NARRATIVE', name: 'BLACKMOON STUDIO'),
                      const SizedBox(height: 24),
                      const _CreditRow(
                          role: 'BUILT WITH', name: 'FLUTTER · RIVERPOD · DRIFT'),

                      const SizedBox(height: 40),
                      const HRule(),
                      const SizedBox(height: 32),

                      // ── Legal link ────────────────────────────────────
                      GestureDetector(
                        onTap: () => context.push(Routes.legal),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 13,
                              color: DreadmoorColors.accentCyan.withOpacity(0.8),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LEGAL DISCLAIMER',
                              style: GoogleFonts.michroma(
                                fontSize: 10,
                                letterSpacing: 2.5,
                                color: DreadmoorColors.accentCyan,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        '© ${DateTime.now().year} BLACKMOON STUDIO',
                        style: GoogleFonts.michroma(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          color: DreadmoorColors.textMeta.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ALL RIGHTS RESERVED',
                        style: GoogleFonts.michroma(
                          fontSize: 8,
                          letterSpacing: 2,
                          color: DreadmoorColors.textMeta.withOpacity(0.3),
                        ),
                      ),

                      const SizedBox(height: 32),
                      const RedactedBar(width: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  final String role;
  final String name;
  const _CreditRow({required this.role, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          role,
          style: GoogleFonts.michroma(
            fontSize: 9,
            letterSpacing: 3,
            color: DreadmoorColors.textMeta,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: GoogleFonts.michroma(
            fontSize: 14,
            letterSpacing: 2,
            color: DreadmoorColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StampText extends StatelessWidget {
  final String text;
  const _StampText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: DreadmoorColors.textMeta.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: GoogleFonts.michroma(
          fontSize: 10,
          letterSpacing: 3,
          color: DreadmoorColors.textMeta,
        ),
      ),
    );
  }
}

class _FallbackLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(
        Rect.fromLTWH(4, 4, size.width - 8, size.height - 8), paint);
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(
        Offset(cx - 10, cy - 12), Offset(cx - 10, cy + 12), paint..strokeWidth = 2);
    canvas.drawArc(Rect.fromLTWH(cx - 10, cy - 12, 20, 12), -1.57, 3.14, false, paint);
    canvas.drawArc(Rect.fromLTWH(cx - 10, cy, 22, 12), -1.57, 3.14, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
