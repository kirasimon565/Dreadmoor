import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/drift_database.dart';
import 'game_state.dart';

class MapLocation {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final double x; // 0.0 = left edge, 1.0 = right edge of map image
  final double y; // 0.0 = top edge, 1.0 = bottom edge of map image
  final String? requiredFlag; // null = always visible
  final String? type;
  final List<String>? evidenceTags;

  const MapLocation({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.x,
    required this.y,
    this.requiredFlag,
    this.type,
    this.evidenceTags,
  });
}

const allMapLocations = <MapLocation>[
  MapLocation(
    id: 'restaurant',
    title: "JOE'S DINER",
    description: 'Last place Rebecca was seen alive with an unknown man.',
    imagePath: 'assets/map/locations/restaurant.png',
    // Upper-left cluster on the map (from screenshot)
    x: 0.36,
    y: 0.35,
    type: 'witness',
    evidenceTags: [],
  ),
  MapLocation(
    id: 'factory',
    title: 'OLD CHEMICAL FACTORY',
    description:
        'Abandoned since the 90s. Locals report strange noises from the lower floors.',
    imagePath: 'assets/map/locations/factory.png',
    // Right-center on the map (from screenshot)
    x: 0.72,
    y: 0.50,
    type: 'crime_scene',
    evidenceTags: ['photo_factory', 'diary_01'],
  ),
  MapLocation(
    id: 'rebecca_home',
    title: "REBECCA'S APARTMENT",
    description: 'Signs of forced entry found on the back door.',
    imagePath: 'assets/map/locations/rebecca_home.png',
    // Mid-left residential area
    x: 0.28,
    y: 0.60,
    type: 'landmark',
    evidenceTags: [],
  ),
  MapLocation(
    id: 'highway',
    title: 'ROUTE 66 HIGHWAY',
    description: 'Crash site. Skid marks still visible.',
    imagePath: 'assets/map/locations/highway.png',
    // Lower diagonal road crossing
    x: 0.45,
    y: 0.82,
    type: 'crime_scene',
    evidenceTags: [],
  ),
];

final unlockedLocationsProvider = FutureProvider<Set<String>>((ref) async {
  final db = ref.read(databaseProvider);
  final flags = await db.select(db.storyState).get();
  return flags.where((f) => f.value).map((f) => f.key).toSet();
});

final unlockedMapLocationsProvider = FutureProvider<List<MapLocation>>((
  ref,
) async {
  final unlockedKeys = await ref.read(unlockedLocationsProvider.future);
  return allMapLocations
      .where(
        (loc) =>
            loc.requiredFlag == null || unlockedKeys.contains(loc.requiredFlag),
      )
      .toList();
});
