// lib/features/minigame/ghost_trace/ghost_trace_game.dart

import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'components/network_node.dart';
import 'components/network_edge.dart';
import 'components/packet.dart';
import 'components/scanline_overlay.dart';
import 'data/ghost_trace_constants.dart';
import 'data/difficulty_config.dart';

class GhostTraceGame extends FlameGame {
  final DifficultyConfig config;
  final void Function(String) onNodeTapped;

  final Map<String, NetworkNode> _nodes = {};
  final List<NetworkEdge> _edges = [];
  final List<List<int>> _adjacency = [];
  final _rng = Random();

  // Overlay names
  static const hudOverlay     = 'hud';
  static const scrambleOverlay = 'scramble';
  static const resultOverlay   = 'result';

  GhostTraceGame({
    required this.config,
    required this.onNodeTapped,
  });

  @override
  Color backgroundColor() => GhostTraceColors.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Scanlines background
    add(ScanlineOverlay(canvasSize: size));

    // Generate node positions in a circle + random offset
    final nodeIds = List.generate(
      config.nodeCount,
      (i) => 'N${String.fromCharCode(65 + i)}', // NA, NB, NC...
    );

    final cx = size.x / 2;
    final cy = size.y / 2;
    final radius = min(cx, cy) * 0.65;

    for (int i = 0; i < nodeIds.length; i++) {
      final angle  = (2 * pi * i / nodeIds.length) - pi / 2;
      final jitterX = (_rng.nextDouble() - 0.5) * 40;
      final jitterY = (_rng.nextDouble() - 0.5) * 40;
      final pos = Vector2(
        cx + cos(angle) * radius + jitterX,
        cy + sin(angle) * radius + jitterY,
      );

      final node = NetworkNode(
        nodeId:    nodeIds[i],
        position:  pos,
        onTapped:  onNodeTapped,
        nodeState: NodeState.normal,
      );
      _nodes[nodeIds[i]] = node;
      add(node);
    }

    // Connect nodes: ring + some random cross-edges
    final ids = _nodes.keys.toList();
    for (int i = 0; i < ids.length; i++) {
      final a = _nodes[ids[i]]!.position;
      final b = _nodes[ids[(i + 1) % ids.length]]!.position;
      _edges.add(NetworkEdge(from: a, to: b));
    }
    // 2 random cross-links per 3 nodes
    for (int i = 0; i < ids.length ~/ 3; i++) {
      final ai = _rng.nextInt(ids.length);
      var   bi = _rng.nextInt(ids.length);
      while (bi == ai) bi = _rng.nextInt(ids.length);
      final a = _nodes[ids[ai]]!.position;
      final b = _nodes[ids[bi]]!.position;
      _edges.add(NetworkEdge(from: a, to: b));
    }
    for (final edge in _edges) {
      add(edge);
    }

    // Start packet traffic
    _schedulePackets(ids);
  }

  void _schedulePackets(List<String> ids) {
    Future.delayed(
      Duration(milliseconds: _rng.nextInt(800) + 200),
      () {
        if (!isMounted) return;
        _spawnPacket(ids);
        _schedulePackets(ids);
      },
    );
  }

  void _spawnPacket(List<String> ids) {
    if (ids.length < 2) return;
    final ai = _rng.nextInt(ids.length);
    var   bi = _rng.nextInt(ids.length);
    while (bi == ai) bi = _rng.nextInt(ids.length);

    final from = _nodes[ids[ai]]!.position;
    final to   = _nodes[ids[bi]]!.position;

    final speed = GhostTraceConstants.packetBaseSpeed *
        config.packetSpeedMultiplier;

    add(Packet(
      start: from.clone(),
      end:   to.clone(),
      type:  PacketType.normal,
      speed: speed,
    ));
  }

  // ── EXTERNAL COMMANDS ────────────────────────────────────────────────────

  void markAttacker(String nodeId) {
    _nodes[nodeId]?.nodeState = NodeState.attacker;
  }

  void markSuspect(String nodeId) {
    _nodes[nodeId]?.nodeState = NodeState.suspect;
  }

  void markTraced(String nodeId) {
    _nodes[nodeId]?.nodeState = NodeState.traced;
  }

  void dimAll() {
    for (final n in _nodes.values) {
      if (n.nodeState == NodeState.normal) {
        n.nodeState = NodeState.idle;
      }
    }
  }

  List<String> get nodeIds => _nodes.keys.toList();
}
