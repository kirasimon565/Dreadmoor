import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/map_state.dart';
import '../../theme/colors.dart';

class LocationDetailSheet extends StatelessWidget {
  final MapLocation location;

  const LocationDetailSheet({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              location.imagePath,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            location.title,
            style: GoogleFonts.michroma(fontSize: 18, color: DreadmoorColors.textPrimary, letterSpacing: 2.0),
          ),

          const SizedBox(height: 12),

          Text(
            location.description,
            style: GoogleFonts.inter(fontSize: 14, color: DreadmoorColors.textSecondary, height: 1.5),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: DreadmoorColors.accentCyan.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                // Hook later: context.push('/board?filter=LOCATIONS&id=${location.id}');
              },
              child: Text(
                "VIEW EVIDENCE",
                style: GoogleFonts.michroma(fontSize: 12, color: DreadmoorColors.accentCyan),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
