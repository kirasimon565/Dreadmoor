import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/core/scheduler/global_scheduler.dart';
import 'package:dreadmoor/core/state/game_state.dart';
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

    final currentNodeIdRow = await (db.select(db.storyState)
          ..where((t) => t.key.equals('current_node_id')))
        .getSingleOrNull();
    final currentNodeId = currentNodeIdRow?.stringValue;

    if (currentNodeId != null && currentNodeId.isNotEmpty) {
      ref.read(activeNodeIdProvider.notifier).setId(currentNodeId);
      scheduler.resume();
    } else {
      // Initial launch point after the cinematic completes
      scheduler.processNode('SCENE_1_NEWS_ARTICLE');
    }

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
