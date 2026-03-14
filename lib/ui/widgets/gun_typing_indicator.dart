import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:dreadmoor/ui/theme/colors.dart';

class GunTypingIndicator extends StatelessWidget {
  const GunTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 6, bottom: 6, right: 48, left: 12),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          child: BackdropFilter(
            // Performance-friendly blur
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: DreadmoorColors.surface(Theme.of(context).brightness).withOpacity(0.35),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 0.6,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: CompactGunTypingIndicator(animate: !reduceMotion),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CompactGunTypingIndicator extends StatelessWidget {
  const CompactGunTypingIndicator({super.key, this.animate = true});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 36,
      child: Lottie.asset(
        'assets/ui/typing_gun_anim.json',
        repeat: true,
        animate: animate,
        frameRate: FrameRate.max,
        fit: BoxFit.contain,
      ),
    );
  }
}
