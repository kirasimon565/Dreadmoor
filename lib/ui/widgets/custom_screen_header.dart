import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/colors.dart';

class CustomScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showBack;

  const CustomScreenHeader({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final topPad = MediaQuery.of(context).padding.top;

    return ClipRect(
      child: Stack(
        children: [
          // [0] Dirty Glitch Layer (visual only, no hit testing)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(
                  'assets/ui/glitch_overlay.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const SizedBox(),
                ),
              ),
            ),
          ),

          // [1] Blur + Glass Container
          BackdropFilter(
            // Performance-friendly blur
            filter: ImageFilter.blur(
              sigmaX: reduceMotion ? 0 : 12,
              sigmaY: reduceMotion ? 0 : 12,
            ),
            child: Container(
              height: 56 + topPad,
              padding: EdgeInsets.only(top: topPad),
              decoration: BoxDecoration(
                color: DreadmoorColors.surface.withOpacity(0.45),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.12),
                    width: 0.6,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (showBack)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: onBackPressed ?? () => context.pop(),
                      tooltip: 'Back',
                    )
                  else
                    const SizedBox(width: 48),

                  const SizedBox(width: 6),

                  // Accent bar
                  Container(
                    width: 2,
                    height: 12,
                    color: DreadmoorColors.accentCyan,
                    margin: const EdgeInsets.only(right: 8),
                  ),

                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.michroma(
                        fontSize: 12.5,
                        color: Colors.white.withOpacity(0.95),
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),

                  if (actions != null) ...actions!,
                  if (actions == null) const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
