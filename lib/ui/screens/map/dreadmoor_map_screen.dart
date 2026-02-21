import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import 'location_detail_sheet.dart';

class DreadmoorMapScreen extends StatelessWidget {
  const DreadmoorMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Map Viewer
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 2.5,
            child: Stack(
              children: [
                Image.asset(
                  'assets/map/dreadmore_map.png',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c,e,s) => Container(color: Colors.grey[900], child: const Center(child: Text('Map Unavailable', style: TextStyle(color: Colors.white)))),
                ),

                // Pins
                _buildPin(context, 100, 200, 'factory'),
                _buildPin(context, 300, 400, 'rebecca_home'),
                _buildPin(context, 50, 150, 'restaurant'),
                _buildPin(context, 250, 300, 'highway'),
              ],
            ),
          ),

          // Header Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 10, left: 16, right: 16),
              color: Colors.black.withOpacity(0.5),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "DREADMOOR",
                    style: GoogleFonts.michroma(
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 2.0,
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

  Widget _buildPin(BuildContext context, double x, double y, String locationId) {
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 0.8,
              builder: (context, scrollController) => SingleChildScrollView(
                controller: scrollController,
                child: LocationDetailSheet(locationId: locationId),
              ),
            ),
          );
        },
        child: Column(
          children: [
            const Icon(Icons.location_on, color: DreadmoorColors.accentRed, size: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: Colors.black.withOpacity(0.7),
              child: Text(
                locationId.toUpperCase().replaceAll('_', ' '),
                style: GoogleFonts.michroma(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
