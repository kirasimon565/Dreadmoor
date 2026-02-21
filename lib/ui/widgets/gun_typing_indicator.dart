import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class GunTypingIndicator extends StatelessWidget {
  const GunTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4, right: 48),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
              ),
              child: const CompactGunTypingIndicator(),
            ),
          ),
        ),
      ),
    );
  }
}

class CompactGunTypingIndicator extends StatelessWidget {
  const CompactGunTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 36,
      child: Lottie.asset('assets/ui/typing_gun_anim.json', repeat: true, animate: true),
    );
  }
}
