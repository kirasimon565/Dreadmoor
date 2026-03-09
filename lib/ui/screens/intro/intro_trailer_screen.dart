import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/core/scheduler/global_scheduler.dart';
import 'package:dreadmoor/core/state/game_state.dart';

class IntroTrailerScreen extends ConsumerStatefulWidget {
  const IntroTrailerScreen({super.key});

  @override
  ConsumerState<IntroTrailerScreen> createState() => _IntroTrailerScreenState();
}

class _IntroTrailerScreenState extends ConsumerState<IntroTrailerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.asset('assets/media/videos/intro_teaser.mp4')
          ..initialize().then((_) {
            setState(() {
              _initialized = true;
            });
            _controller.play();
          });

    _controller.addListener(_videoListener);

    // Preload Game Systems
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadSystems();
    });
  }

  void _videoListener() {
    if (_controller.value.isInitialized &&
        _controller.value.position >= _controller.value.duration &&
        !_isTransitioning) {
      _isTransitioning = true;
      context.go('/title_cinematic');
    }
  }

  Future<void> _preloadSystems() async {
    // Start episode 1 loading in the background
    final scheduler = ref.read(globalSchedulerProvider);
    // Don't auto-start it since we just want to preload?
    // Wait, the instructions say "preload the OS and episode systems during the video playback".
    // And "Start episode 1 begins" when OS appears.
    // If we call startEpisode, the scheduler begins.
    // We should pause it immediately so it doesn't push events while video plays.
    await scheduler.startEpisode('ep01');
    scheduler.pause();
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _initialized
            ? FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
