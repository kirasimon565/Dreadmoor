import 'dart:ui';
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import 'messenger_logo.dart';

/// Simplified header — just the animated logo.
/// Profile + Search have moved to the bottom navigation bar.
class MessengerHeader extends StatelessWidget {
  const MessengerHeader({
    super.key,
    required this.isSearching,
    // ✅ Kept for backward compat but no longer rendered as buttons here
    required this.onSearchTap,
    required this.onProfileTap,
  });

  final bool isSearching;
  final VoidCallback onSearchTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: reduceMotion ? 0 : 14,
          sigmaY: reduceMotion ? 0 : 14,
        ),
        child: Container(
          height: 64 + topPadding,
          padding: EdgeInsets.only(top: topPadding),
          decoration: BoxDecoration(
            color: DreadmoorColors.surface.withOpacity(0.50),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.07),
                width: 0.6,
              ),
            ),
          ),
          // ── Logo centered, fades out when search bar is open ─────────
          child: Center(
            child: AnimatedOpacity(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              opacity: isSearching ? 0.0 : 1.0,
              child: const MessengerLogo(
                height: 38,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
