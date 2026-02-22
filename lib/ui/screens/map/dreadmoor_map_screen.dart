import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/map_state.dart';
import '../../theme/colors.dart';
import 'location_detail_sheet.dart';

class DreadmoorMapScreen extends ConsumerWidget {
  const DreadmoorMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedAsync = ref.watch(unlockedLocationsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: unlockedAsync.when(
        data: (unlockedFlags) {
          return Stack(
            children: [
              InteractiveViewer(
                minScale: 0.6,
                maxScale: 2.5,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;

                    return Stack(
                      children: [
                        Image.asset(
                          'assets/map/dreadmore_map.png',
                          width: w,
                          height: h,
                          fit: BoxFit.cover,
                        ),

                        for (final loc in allMapLocations)
                          _MapPin(
                            location: loc,
                            unlocked: unlockedFlags.contains(loc.requiredFlag),
                            mapWidth: w,
                            mapHeight: h,
                          ),
                      ],
                    );
                  },
                ),
              ),

              _Header(onBack: () => context.pop()),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: DreadmoorColors.accentCyan)),
        error: (e, _) => Center(child: Text("MAP ERROR", style: GoogleFonts.michroma(color: Colors.red))),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          bottom: 10,
          left: 16,
          right: 16,
        ),
        color: Colors.black.withOpacity(0.55),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
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
    );
  }
}

class _MapPin extends StatelessWidget {
  final MapLocation location;
  final bool unlocked;
  final double mapWidth;
  final double mapHeight;

  const _MapPin({
    required this.location,
    required this.unlocked,
    required this.mapWidth,
    required this.mapHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: mapWidth * location.x,
      top: mapHeight * location.y,
      child: GestureDetector(
        onTap: unlocked
            ? () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => LocationDetailSheet(location: location),
                );
              }
            : null,
        child: Opacity(
          opacity: unlocked ? 1.0 : 0.3,
          child: Column(
            children: [
              Icon(
                Icons.location_on,
                color: unlocked ? DreadmoorColors.accentRed : Colors.grey[700],
                size: 32,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: Colors.black.withOpacity(0.7),
                child: Text(
                  location.title,
                  style: GoogleFonts.michroma(fontSize: 9, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
