// lib/features/minigame/tracecore/utils/fake_data_builder.dart
// Generates deterministic fake IPs, names, tags, and locations.

import 'dart:math';

class FakeDataBuilder {
  static final _rng = Random();

  static const _names = [
    'Rebecca', 'Jordan', 'Mira', 'Asher', 'Noel',
    'Cass',    'Blake',  'Ryn',  'Vale',  'Soren',
  ];

  static const _locations = [
    'Downtown hotspot',    'Factory district WiFi',
    'Central library',     'Riverside café',
    'Northside apartment', 'Station plaza',
    'Old quarter net hub', 'Harbor bridge node',
  ];

  static const _tagChars = 'ABCDEF0123456789';

  static String randomIp() {
    return [
      _rng.nextInt(223) + 1,
      _rng.nextInt(255),
      _rng.nextInt(255),
      _rng.nextInt(254) + 1,
    ].join('.');
  }

  static String randomTag(String prefix) {
    final suffix = List.generate(
      4, (_) => _tagChars[_rng.nextInt(_tagChars.length)],
    ).join();
    return '$prefix-$suffix';
  }

  static String randomName({String? exclude}) {
    final pool = _names.where((n) => n != exclude).toList();
    return pool[_rng.nextInt(pool.length)];
  }

  static String randomLocation({String? exclude}) {
    final pool = _locations.where((l) => l != exclude).toList();
    return pool[_rng.nextInt(pool.length)];
  }
}
