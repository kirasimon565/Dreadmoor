// lib/features/minigame/tracecore/ui/widgets/timer_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimerBar extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;
  final int hearts;
  final int maxHearts;

  const TimerBar({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.hearts,
    required this.maxHearts,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0
        ? secondsLeft / totalSeconds
        : 0.0;
    final isUrgent = secondsLeft <= 10;

    final m = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF1A3A1A), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Timer
          Text(
            '$m:$s',
            style: GoogleFonts.sourceCodePro(
              fontSize:      16,
              fontWeight:    FontWeight.w700,
              color:         isUrgent
                  ? const Color(0xFFFF1744)
                  : const Color(0xFF00FF41),
              letterSpacing: 2,
            ),
          ),

          const SizedBox(width: 12),

          // Progress bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value:           progress.clamp(0.0, 1.0),
                minHeight:       4,
                backgroundColor: const Color(0xFF0A1A0A),
                valueColor:      AlwaysStoppedAnimation<Color>(
                  isUrgent
                      ? const Color(0xFFFF1744)
                      : const Color(0xFF00CC33),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Hearts
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(maxHearts, (i) => Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Icon(
                Icons.favorite,
                size:  12,
                color: i < hearts
                    ? const Color(0xFFFF1744)
                    : const Color(0xFF2A0A0A),
              ),
            )),
          ),
        ],
      ),
    );
  }
}
