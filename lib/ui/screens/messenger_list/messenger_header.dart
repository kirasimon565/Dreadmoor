import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import 'messenger_logo.dart';

class MessengerHeader extends StatelessWidget {
  const MessengerHeader({
    super.key,
    required this.onSearchTap,
    required this.onProfileTap,
    required this.isSearching,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onProfileTap;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: reduceMotion ? 0 : 12,
          sigmaY: reduceMotion ? 0 : 12,
        ),
        child: Container(
          height: 72 + topPadding,
          padding: EdgeInsets.only(top: topPadding),
          decoration: BoxDecoration(
            color: DreadmoorColors.surface.withOpacity(0.55),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 0.6,
              ),
            ),
          ),
          child: Stack(
            children: [
              // ── Center: custom logo or fallback title ─────────────
              Center(
                child: AnimatedOpacity(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  opacity: isSearching ? 0.0 : 1.0,
                  child: const MessengerLogo(
                    height: 40,
                    color: Colors.white,
                  ),
                ),
              ),

              // ── Left: player profile ──────────────────────────────
              Positioned(
                left: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: onProfileTap,
                    icon: const Icon(Icons.person_outline_rounded),
                    color: DreadmoorColors.textSecondary,
                    iconSize: 22,
                    tooltip: 'Profile',
                  ),
                ),
              ),

              // ── Right: search toggle ──────────────────────────────
              Positioned(
                right: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: onSearchTap,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        isSearching
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        key: ValueKey(isSearching),
                        color: DreadmoorColors.textSecondary,
                        size: 22,
                      ),
                    ),
                    tooltip: isSearching ? 'Close search' : 'Search',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
