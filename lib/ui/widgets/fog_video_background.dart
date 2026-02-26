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
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // âœ… Delay the entire init to postFrameCallback.
    // On Android 10, the Texture surface isn't registered in the
    // render tree until after the first frame. Calling initialize()
    // before that causes a black screen even if initialization
    // technically "succeeds". Starting after first frame fixes this.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initVideo();
    });
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(widget.assetPath);

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(true);
      await controller.setVolume(0);

      // âœ… Extra delay for Android 10.
      // Even after initialize() the codec output surface on older
      // Android versions needs one more event loop tick to fully bind
      // to the Flutter Texture. 300ms is enough on every device tested.
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.play();

      setState(() {
        _controller = controller;
        _initialized = true;
      });
    } catch (e) {
      debugPrint('ðŸŽ¥ VideoPlayer error: $e');
      await controller.dispose();
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_initialized || _controller == null) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller!.pause();
    } else if (state == AppLifecycleState.resumed) {
      _controller!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error || !_initialized || _controller == null) {
      return const ColoredBox(color: Colors.black);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base black so screen edges never flash white
        const ColoredBox(color: Colors.black),

        // Video with cinematic fade-in
        AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: _initialized ? 1.0 : 0.0,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
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
