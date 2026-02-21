import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

class InterceptBanner extends StatelessWidget {
  const InterceptBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: DreadmoorColors.accentRed.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(
            color: DreadmoorColors.accentRed.withOpacity(0.3),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: DreadmoorColors.accentRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "INTERCEPTED SIGNAL",
                  style: GoogleFonts.michroma(
                    fontSize: 10,
                    letterSpacing: 2.0,
                    color: DreadmoorColors.accentRed,
                  ),
                ),
                Text(
                  "SECURE CONNECTION UNAUTHORIZED",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    color: DreadmoorColors.accentRed.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
