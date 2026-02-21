import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/colors.dart';

class MessengerHeader extends StatelessWidget {
  const MessengerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0x08FFFFFF), // white.03 approx
            border: Border(
              bottom: BorderSide(
                color: Color(0x0FFFFFFF), // white.06 approx
                width: 0.5,
              ),
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Image.asset(
                  'assets/ui/messenger_weapon_logo.png',
                  height: 28,
                  errorBuilder: (c, e, s) => Text("MESSENGER", style: TextStyle(color: DreadmoorColors.textPrimary)),
                ),
              ),
              Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      // Search functionality
                    },
                    child: Icon(
                      Icons.search_rounded,
                      color: DreadmoorColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      context.push('/profile/player');
                    },
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: DreadmoorColors.textSecondary,
                      size: 20,
                    ),
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
