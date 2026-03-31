// lib/features/minigame/tracecore/models/tracecore_target.dart

class TracecoreTarget {
  final String ip;
  final String name;
  final String tag;
  final String location;

  const TracecoreTarget({
    required this.ip,
    required this.name,
    required this.tag,
    required this.location,
  });

  factory TracecoreTarget.fromJson(Map<String, dynamic> j) => TracecoreTarget(
        ip:       j['ip']       as String,
        name:     j['name']     as String,
        tag:      j['tag']      as String,
        location: j['location'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'ip':       ip,
        'name':     name,
        'tag':      tag,
        'location': location,
      };
}
