import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

class LocationDetailSheet extends StatelessWidget {
  final String locationId;

  const LocationDetailSheet({super.key, required this.locationId});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final title = _getTitle(locationId);
    final description = _getDescription(locationId);
    final imagePath = 'assets/map/locations/${locationId}.png';

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
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),

          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (c,e,s) => Container(color: Colors.grey[900], height: 200, child: const Center(child: Icon(Icons.location_city, color: Colors.white24, size: 48))),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            title,
            style: GoogleFonts.michroma(fontSize: 18, color: DreadmoorColors.textPrimary, letterSpacing: 2.0),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: GoogleFonts.inter(fontSize: 14, color: DreadmoorColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: DreadmoorColors.accentCyan.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                // Navigate to evidence related to this location
                // e.g. context.push('/board?filter=LOCATIONS')
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

  String _getTitle(String id) {
    switch (id) {
      case 'factory': return "OLD CHEMICAL FACTORY";
      case 'restaurant': return "JOE'S DINER";
      case 'highway': return "ROUTE 66 HIGHWAY";
      case 'rebecca_home': return "REBECCA'S APARTMENT";
      default: return "UNKNOWN LOCATION";
    }
  }

  String _getDescription(String id) {
    switch (id) {
      case 'factory': return "Abandoned since the 90s. Locals claim strange noises originate from the basement levels.";
      case 'restaurant': return "Last known location where Rebecca was seen having coffee with a mystery man.";
      case 'highway': return "The site of the accident. Skid marks are still visible on the asphalt.";
      case 'rebecca_home': return "Her safe haven. Signs of forced entry were found on the back door.";
      default: return "No data available.";
    }
  }
}
