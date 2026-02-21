import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/colors.dart';

class CustomScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const CustomScreenHeader({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          // [0] Dirty Glitch Layer (Under the blur)
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/ui/glitch_overlay.png',
                fit: BoxFit.cover,
                errorBuilder: (c,e,s) => const SizedBox(),
              ),
            ),
          ),

          // [1] Blur + Glass Container
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 60 + MediaQuery.of(context).padding.top,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                  left: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                  right: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBackPressed ?? () => context.pop(),
                  ),
                  const SizedBox(width: 8),

                  // "Lead-In" Typography
                  Container(
                    width: 2,
                    height: 12,
                    color: DreadmoorColors.accentCyan,
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      textAlign: TextAlign.left,
                      style: GoogleFonts.michroma(
                        fontSize: 13,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),

                  if (actions != null) ...actions!,
                  if (actions == null) const SizedBox(width: 48), // Balance back button? No, title is left-aligned now.
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
