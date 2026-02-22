import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/routes.dart';
import '../../theme/colors.dart';

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
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: reduceMotion ? 0 : 12,
          sigmaY: reduceMotion ? 0 : 12,
        ),
        child: Container(
          height: 64 + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
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
              Center(
                child: AnimatedOpacity(
                  duration:
                      reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
                  opacity: isSearching ? 0.0 : 1.0,
                  child: Image.asset(
                    'assets/ui/messenger_weapon_logo.png',
                    height: 28,
                    errorBuilder: (c, e, s) => Text(
                      "MESSENGER",
                      style: TextStyle(color: DreadmoorColors.textPrimary),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: onSearchTap,
                    icon: Icon(
                      isSearching ? Icons.close_rounded : Icons.search_rounded,
                      color: DreadmoorColors.textSecondary,
                      size: 20,
                    ),
                    tooltip: isSearching ? 'Close search' : 'Search',
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: onProfileTap,
                    icon: const Icon(Icons.person_outline_rounded),
                    color: DreadmoorColors.textSecondary,
                    tooltip: 'Profile',
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
