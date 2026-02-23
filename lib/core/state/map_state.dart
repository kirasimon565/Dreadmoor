import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/drift_database.dart';
import 'game_state.dart';

class MapLocation {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final double x; // normalized 0..1
  final double y; // normalized 0..1
  final String requiredFlag;

  // FIX: Added type and evidenceTags — used by location_detail_sheet.dart
  // but missing from the original model definition.
  final String? type;           // e.g. 'crime_scene', 'witness', 'landmark'
  final List<String>? evidenceTags; // evidence IDs linked to this location

  const MapLocation({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.x,
    required this.y,
    required this.requiredFlag,
    this.type,
    this.evidenceTags,
  });
}

const allMapLocations = <MapLocation>[
  MapLocation(
    id: 'factory',
    title: 'OLD CHEMICAL FACTORY',
    description:
        'Abandoned since the 90s. Locals report strange noises from the lower floors.',
    imagePath: 'assets/map/locations/factory.png',
    x: 0.22,
    y: 0.38,
    requiredFlag: 'visited_factory',
    type: 'crime_scene',
    evidenceTags: ['photo_factory', 'diary_01'],
  ),
  MapLocation(
    id: 'restaurant',
    title: "JOE'S DINER",
    description: 'Last place Rebecca was seen alive with an unknown man.',
    imagePath: 'assets/map/locations/restaurant.png',
    x: 0.12,
    y: 0.24,
    requiredFlag: 'unlocked_restaurant',
    type: 'witness',
    evidenceTags: [],
  ),
  MapLocation(
    id: 'highway',
    title: 'ROUTE 66 HIGHWAY',
    description: 'Crash site. Skid marks still visible.',
    imagePath: 'assets/map/locations/highway.png',
    x: 0.55,
    y: 0.62,
    requiredFlag: 'unlocked_highway',
    type: 'crime_scene',
    evidenceTags: [],
  ),
  MapLocation(
    id: 'rebecca_home',
    title: "REBECCA'S APARTMENT",
    description: 'Signs of forced entry found on the back door.',
    imagePath: 'assets/map/locations/rebecca_home.png',
    x: 0.35,
    y: 0.48,
    requiredFlag: 'visited_rebecca_home',
    type: 'landmark',
    evidenceTags: [],
  ),
];

// FIX: ref.watch → ref.read inside async FutureProvider body
final unlockedLocationsProvider = FutureProvider<Set<String>>((ref) async {
  final db = ref.read(databaseProvider);
  final flags = await db.select(db.storyState).get();
  // Only return keys where the flag is actually true
  return flags.where((f) => f.value).map((f) => f.key).toSet();
});

// Enriched provider — returns only locations the player has unlocked
final unlockedMapLocationsProvider =
    FutureProvider<List<MapLocation>>((ref) async {
  final unlockedKeys = await ref.read(unlockedLocationsProvider.future);
  return allMapLocations
      .where((loc) => unlockedKeys.contains(loc.requiredFlag))
      .toList();
});
