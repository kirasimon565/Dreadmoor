// lib/features/minigame/ghost_trace/data/target_generator.dart

import 'dart:math';

class NetworkTarget {
  final String nodeId;
  final String ip;
  final String tag;
  final List<String> relayChain; // ordered hop IDs

  const NetworkTarget({
    required this.nodeId,
    required this.ip,
    required this.tag,
    required this.relayChain,
  });
}

class TargetGenerator {
  static final _rng = Random();

  static const _tagChars = 'ABCDEF0123456789';

  static NetworkTarget generate({
    required List<String> allNodeIds,
    required int relayHops,
  }) {
    // Pick attacker node (not the first — keep it interesting)
    final shuffled = List<String>.from(allNodeIds)..shuffle(_rng);
    final attackerNodeId = shuffled.first;

    // Build relay chain from remaining nodes
    final others = shuffled.where((id) => id != attackerNodeId).toList();
    final chain  = others.take(relayHops).toList();

    return NetworkTarget(
      nodeId:     attackerNodeId,
      ip:         _randomIp(),
      tag:        _randomTag(8),
      relayChain: chain,
    );
  }

  static String _randomIp() {
    return [
      _rng.nextInt(223) + 1,
      _rng.nextInt(255),
      _rng.nextInt(255),
      _rng.nextInt(254) + 1,
    ].join('.');
  }

  static String _randomTag(int length) {
    return List.generate(
      length,
      (_) => _tagChars[_rng.nextInt(_tagChars.length)],
    ).join();
  }
}
