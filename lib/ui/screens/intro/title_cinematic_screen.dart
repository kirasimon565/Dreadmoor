import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/core/scheduler/global_scheduler.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/state/scheduler_state.dart';
import 'package:dreadmoor/ui/navigation/routes.dart';

class TitleCinematicScreen extends ConsumerStatefulWidget {
  const TitleCinematicScreen({super.key});

  @override
  ConsumerState<TitleCinematicScreen> createState() =>
      _TitleCinematicScreenState();
}

class _TitleCinematicScreenState extends ConsumerState<TitleCinematicScreen> {
  late VideoPlayerController _controller;

  bool _finished = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(
      'assets/media/videos/title_intro.mp4',
    )
      ..initialize().then((_) {
        if (!mounted) return;

        setState(() {});

        _controller.play();

        _controller.addListener(_checkVideoEnd);
      });
  }

  void _checkVideoEnd() {
    if (!_controller.value.isInitialized) return;

    final position = _controller.value.position;
    final duration = _controller.value.duration;

    if (!_finished && position >= duration) {
      _finished = true;
      _goToGame();
    }
  }

  void _goToGame() async {
    final scheduler = ref.read(globalSchedulerProvider);
    final db = ref.read(databaseProvider);

    // 1. Check if there's a saved node to resume from
    final currentNodeIdRow = await (db.select(db.storyState)
          ..where((t) => t.key.equals('current_node_id')))
        .getSingleOrNull();
    final currentNodeId = currentNodeIdRow?.stringValue;

    if (currentNodeId != null && currentNodeId.isNotEmpty) {
      ref.read(schedulerStateProvider.notifier).update(
            (s) => s.copyWith(activeNodeId: currentNodeId),
          );
      scheduler.resume();
      context.go(Routes.messenger);
      return;
    }

    // 2. No saved state — look up the starting node from the database
    final startNodeRow = await (db.select(db.storyState)
          ..where((t) => t.key.equals('start_node_id')))
        .getSingleOrNull();
    final startNodeId = startNodeRow?.stringValue;

    if (startNodeId != null && startNodeId.isNotEmpty) {
      scheduler.processNode(startNodeId);
      context.go(Routes.messenger);
      return;
    }

    // 3. Nothing configured — log clearly so you know what to fix
    print(
        "DreadmoorOS ✗ No 'current_node_id' or 'start_node_id' in story_state. "
        "Set 'start_node_id' to the first node of the active episode.");
    context.go(Routes.messenger);
  }

  @override
  void dispose() {
    _controller.removeListener(_checkVideoEnd);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
