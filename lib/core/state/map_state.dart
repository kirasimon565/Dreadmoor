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

  // ✅ Nullable — null means always visible (no flag required)
  // A non-null string means this location is hidden until that
  // story flag is set to true in the DB.
  final String? requiredFlag;

  final String? type;
  final List<String>? evidenceTags;

  const MapLocation({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.x,
    required this.y,
    this.requiredFlag,         // ✅ optional — omit for always-visible locations
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
    // ✅ null = always on map. Set requiredFlag: 'visited_factory'
    // when you want it hidden until the player triggers that event.
    requiredFlag: null,
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
    requiredFlag: null,
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
    requiredFlag: null,
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
    requiredFlag: null,
    type: 'landmark',
    evidenceTags: [],
  ),
];

final unlockedLocationsProvider = FutureProvider<Set<String>>((ref) async {
  final db = ref.read(databaseProvider);
  final flags = await db.select(db.storyState).get();
  return flags.where((f) => f.value).map((f) => f.key).toSet();
});

final unlockedMapLocationsProvider =
    FutureProvider<List<MapLocation>>((ref) async {
  final unlockedKeys = await ref.read(unlockedLocationsProvider.future);
  return allMapLocations.where((loc) {
    // ✅ null requiredFlag = always show
    // non-null = only show when that flag is in the DB
    return loc.requiredFlag == null ||
        unlockedKeys.contains(loc.requiredFlag);
  }).toList();
});
