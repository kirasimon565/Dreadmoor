import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/routes.dart';
import '../../theme/colors.dart';
import '../../widgets/shared_screen_painters.dart';

class FatalErrorScreen extends StatefulWidget {
  final String? error;
  const FatalErrorScreen({super.key, this.error});

  @override
  State<FatalErrorScreen> createState() => _FatalErrorScreenState();
}

class _FatalErrorScreenState extends State<FatalErrorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  int _scrambleTick = 0;
  Timer? _scrambleTimer;
  bool _settled = false;

  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#@!%&*';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnim = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    _scrambleTimer = Timer.periodic(const Duration(milliseconds: 60), (t) {
      if (!mounted) return;
      setState(() => _scrambleTick++);
      if (_scrambleTick > 30) {
        t.cancel();
        if (mounted) setState(() => _settled = true);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrambleTimer?.cancel();
    super.dispose();
  }

  String _scramble(String input) {
    if (_settled) return input;
    final progress = _scrambleTick / 30.0;
    final settledChars = (input.length * progress).round();
    final result = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      if (input[i] == ' ') {
        result.write(' ');
      } else if (i < settledChars) {
        result.write(input[i]);
      } else {
        result.write(_chars[(_scrambleTick * 7 + i * 13) % _chars.length]);
      }
    }
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: const ScanlinePainter()),
          ),

          // Red pulse vignette
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => CustomPaint(
                painter: VignettePainter(
                  color: DreadmoorColors.accentRed,
                  intensity: 0.06 + _pulseAnim.value * 0.08,
                ),
              ),
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Long-press opens debug
                  GestureDetector(
                    onLongPress: () => context.push(Routes.debug),
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Icon(
                        Icons.error_outline_rounded,
                        color: DreadmoorColors.accentRed
                            .withOpacity(0.5 + _pulseAnim.value * 0.5),
                        size: 52,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    _scramble('SYSTEM FAILURE'),
                    style: GoogleFonts.michroma(
                      fontSize: 20,
                      letterSpacing: 4,
                      color: DreadmoorColors.accentRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    width: 200,
                    color: DreadmoorColors.accentRed.withOpacity(0.25),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    widget.error ?? 'AN UNRECOVERABLE ERROR HAS OCCURRED.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 13,
                      height: 1.7,
                      color: Colors.white.withOpacity(0.75),
                      letterSpacing: 0.3,
                    ),
                  ),

                  if (widget.error != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: DreadmoorColors.accentRed.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bug_report_outlined,
                              size: 12, color: DreadmoorColors.textMeta),
                          const SizedBox(width: 8),
                          Text(
                            'ERROR TRACE CAPTURED',
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 9,
                              letterSpacing: 2,
                              color: DreadmoorColors.textMeta,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 52),
                  _RebootButton(onPressed: () => context.go(Routes.studio)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RebootButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _RebootButton({required this.onPressed});

  @override
  State<_RebootButton> createState() => _RebootButtonState();
}

class _RebootButtonState extends State<_RebootButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _hovered
                  ? DreadmoorColors.accentRed
                  : DreadmoorColors.accentRed.withOpacity(0.5),
            ),
            color: _hovered
                ? DreadmoorColors.accentRed.withOpacity(0.12)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded,
                  size: 15,
                  color: DreadmoorColors.accentRed
                      .withOpacity(_hovered ? 1.0 : 0.7)),
              const SizedBox(width: 10),
              Text(
                'REBOOT SYSTEM',
                style: GoogleFonts.michroma(
                  fontSize: 11,
                  letterSpacing: 2.5,
                  color: DreadmoorColors.accentRed
                      .withOpacity(_hovered ? 1.0 : 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
