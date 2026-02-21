import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

class FatalErrorScreen extends StatelessWidget {
  final String? error;

  const FatalErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: DreadmoorColors.accentRed, size: 64),
              const SizedBox(height: 24),
              Text(
                "SYSTEM FAILURE",
                style: GoogleFonts.michroma(fontSize: 18, color: DreadmoorColors.accentRed, letterSpacing: 2.0),
              ),
              const SizedBox(height: 12),
              Text(
                error ?? "An unrecoverable error has occurred.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8), height: 1.6),
              ),
              const SizedBox(height: 48),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: DreadmoorColors.accentRed),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () => context.go('/'),
                child: Text("REBOOT SYSTEM", style: GoogleFonts.michroma(color: DreadmoorColors.accentRed)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
