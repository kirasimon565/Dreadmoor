import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

class ContentUpdateScreen extends StatelessWidget {
  const ContentUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Logic to check updates, then navigate back or to welcome
    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) context.go('/welcome');
    });

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: DreadmoorColors.accentCyan),
            const SizedBox(height: 24),
            Text(
              "CHECKING FOR UPDATES",
              style: GoogleFonts.michroma(fontSize: 14, color: DreadmoorColors.textPrimary, letterSpacing: 2.0),
            ),
            const SizedBox(height: 12),
            Text(
              "Connecting to server...",
              style: GoogleFonts.inter(fontSize: 12, color: DreadmoorColors.textMeta),
            ),
          ],
        ),
      ),
    );
  }
}
