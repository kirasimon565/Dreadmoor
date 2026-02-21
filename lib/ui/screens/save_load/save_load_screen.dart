import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';

class SaveLoadScreen extends StatelessWidget {
  const SaveLoadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Column(
        children: [
          CustomScreenHeader(
            title: "SAVE / LOAD",
            onBackPressed: () => context.pop(),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.save_outlined, color: Colors.white.withValues(alpha: 0.3), size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "NO SAVE SLOTS AVAILABLE",
                    style: GoogleFonts.michroma(fontSize: 12, color: DreadmoorColors.textMeta),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Progress is automatically saved.",
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
