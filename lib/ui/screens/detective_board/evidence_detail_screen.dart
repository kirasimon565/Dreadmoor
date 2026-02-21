import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

class EvidenceDetailScreen extends StatelessWidget {
  final String evidenceId;

  const EvidenceDetailScreen({super.key, required this.evidenceId});

  @override
  Widget build(BuildContext context) {
    // Mock data based on evidenceId
    final title = evidenceId == 'factory_photo' ? "FACTORY ENTRANCE" : "UNKNOWN EVIDENCE";
    final description = "Photo taken at 03:00 AM outside the abandoned chemical plant.";
    final imagePath = 'assets/map/locations/factory.png'; // Mock

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image Viewer (Zoomable)
          InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (c,e,s) => Container(
                  color: Colors.grey[900],
                  child: Center(child: Icon(Icons.image_not_supported, color: Colors.white.withOpacity(0.3), size: 64)),
                ),
              ),
            ),
          ),

          // Header / Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 10, left: 16, right: 16),
              color: Colors.black.withOpacity(0.7),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.michroma(
                            fontSize: 14,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                        Text(
                          "EVIDENCE #${evidenceId.toUpperCase().substring(0, 4)}...", // Mock ID
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.black.withOpacity(0.85),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DESCRIPTION",
                    style: GoogleFonts.michroma(
                      fontSize: 10,
                      color: DreadmoorColors.accentCyan,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.5,
                    ),
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
