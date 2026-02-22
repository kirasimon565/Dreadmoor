import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

class InterceptBanner extends StatelessWidget {
  const InterceptBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/ui/intercept_banner_bg.png'),
              fit: BoxFit.cover,
            ),
            border: Border(
              bottom: BorderSide(
                color: DreadmoorColors.accentRed.withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: DreadmoorColors.accentRed, size: 18),
              const SizedBox(width: 10),
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
                      "SECURE CHANNEL BREACHED",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: DreadmoorColors.accentRed.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
