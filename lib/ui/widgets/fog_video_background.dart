import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FogVideoBackground extends StatefulWidget {
  const FogVideoBackground({
    super.key,
    required this.assetPath,
    this.fogOpacity = 0.15,     // Max fog opacity (rule)
    this.darkenOpacity = 0.65,  // Dark overlay for readability
  });

  final String assetPath;
  final double fogOpacity;
  final double darkenOpacity;

  @override
  State<FogVideoBackground> createState() => _FogVideoBackgroundState();
}

class _FogVideoBackgroundState extends State<FogVideoBackground>
    with WidgetsBindingObserver {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        if (!mounted) return;
        _controller
          ..setLooping(true)
          ..setVolume(0)
          ..play();
        setState(() => _initialized = true);
      }).catchError((error) {
        debugPrint("🎥 VideoPlayer error: $error");
        if (mounted) setState(() => _error = true);
      });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_initialized) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return const ColoredBox(color: Colors.black);
    }

    if (!_initialized) {
      return const ColoredBox(color: Colors.black);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base black
        const ColoredBox(color: Colors.black),

        // Fog video layer (subtle)
        Opacity(
          opacity: widget.fogOpacity.clamp(0.0, 0.15),
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),

        // Dark overlay for UI readability
        Container(
          color: Colors.black.withOpacity(widget.darkenOpacity.clamp(0.0, 0.9)),
        ),

        // Gentle fade-in so it feels cinematic
        AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: _initialized ? 1 : 0,
          child: const SizedBox.expand(),
        ),
      ],
    );
  }
}
