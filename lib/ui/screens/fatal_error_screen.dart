import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/routes.dart';
import '../theme/colors.dart';

class FatalErrorScreen extends StatelessWidget {
  const FatalErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      resizeToAvoidBottomInset: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '[ CRITICAL ERROR: SIGNAL LOST ]',
                textAlign: TextAlign.center,
                style: GoogleFonts.michroma(
                  fontSize: 13,
                  letterSpacing: 2,
                  color: DreadmoorColors.accentRed,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => context.go(Routes.studio),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: DreadmoorColors.accentRed.withOpacity(0.7), width: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'RETRY',
                    style: GoogleFonts.michroma(
                      fontSize: 11,
                      letterSpacing: 2,
                      color: DreadmoorColors.accentRed,
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
