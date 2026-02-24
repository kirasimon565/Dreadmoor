import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FogVideoBackground extends StatefulWidget {
  const FogVideoBackground({
    super.key,
    required this.assetPath,
    this.darkenOpacity = 0.55,
  });

  final String assetPath;
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
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.asset(widget.assetPath);

    try {
      await _controller.initialize();

      if (!mounted) return;

      await _controller.setLooping(true);
      await _controller.setVolume(0);

      // âœ… Wait for the next frame before calling play().
      // On Android 10 the Texture surface isn't attached to the
      // VideoPlayer until after the first build â€” calling play()
      // immediately after initialize() causes a black screen because
      // the codec starts decoding before the surface is ready.
      // One addPostFrameCallback ensures the widget tree has rendered
      // at least once and the surface is fully attached.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _controller.play();
        if (mounted) setState(() => _initialized = true);
      });
    } catch (e) {
      debugPrint('ðŸŽ¥ VideoPlayer error: $e');
      if (mounted) setState(() => _error = true);
    }
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
    if (_error || !_initialized) {
      return const ColoredBox(color: Colors.black);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base black so screen edges never flash white
        const ColoredBox(color: Colors.black),

        // Video with cinematic fade-in
        AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          opacity: _initialized ? 1.0 : 0.0,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),

        // Dark overlay â€” keeps UI readable over video
        ColoredBox(
          color: Colors.black.withOpacity(
            widget.darkenOpacity.clamp(0.0, 0.95),
          ),
        ),
      ],
    );
  }
}
