import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

class InterceptBanner extends StatefulWidget {
  /// Controls whether the banner is shown.
  /// Pass true when the current thread is a secret/intercepted channel.
  final bool isVisible;

  const InterceptBanner({super.key, required this.isVisible});

  @override
  State<InterceptBanner> createState() => _InterceptBannerState();
}

class _InterceptBannerState extends State<InterceptBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isVisible) _controller.forward();
  }

  @override
  void didUpdateWidget(InterceptBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Fully collapses when not visible — takes no space in the layout
    if (!widget.isVisible && _controller.isDismissed) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                // ✅ errorBuilder via DecorationImage isn't supported —
                // use a Stack with a fallback color underneath instead
                color: Colors.black.withOpacity(0.6),
                border: Border(
                  bottom: BorderSide(
                    color: DreadmoorColors.accentRed.withOpacity(0.4),
                    width: 1.0,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  // Background image with graceful fallback
                  Positioned.fill(
                    child: Image.asset(
                      'assets/ui/intercept_banner_bg.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 18),
                    child: Row(
                      children: [
                        // Pulsing warning icon
                        _PulsingIcon(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "INTERCEPTED SIGNAL",
                                style: GoogleFonts.michroma(
                                  fontSize: 10,
                                  letterSpacing: 2.0,
                                  color: DreadmoorColors.accentRed,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "SECURE CHANNEL BREACHED",
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  letterSpacing: 1.0,
                                  color: DreadmoorColors.accentRed
                                      .withOpacity(0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pulsing warning icon ───────────────────────────────────────────────────

class _PulsingIcon extends StatefulWidget {
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Icon(
        Icons.warning_amber_rounded,
        color: DreadmoorColors.accentRed,
        size: 18,
      ),
    );
  }
}
