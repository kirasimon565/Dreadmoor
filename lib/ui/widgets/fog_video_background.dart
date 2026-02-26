import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FogVideoBackground extends StatefulWidget {
  const FogVideoBackground({
    super.key,
    required this.assetPath,
    this.darkenOpacity = 0.55,
    this.fallbackAsset = 'assets/backgrounds/welcome_bg_still.png',
  });

  final String assetPath;
  final double darkenOpacity;
  final String fallbackAsset;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initVideo();
    });
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(
      widget.assetPath,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await controller.initialize();
      if (!mounted) { await controller.dispose(); return; }

      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();

      // âœ… Instead of checking size immediately (which is zero on Android 10
      // right after play), wait up to 3 seconds for the first frame to decode.
      // Size becomes non-zero once the codec produces its first output frame.
      final gotFrame = await _waitForFirstFrame(controller);

      if (!mounted) { await controller.dispose(); return; }

      if (!gotFrame) {
        // Timed out â€” device genuinely can't decode this video
        await controller.dispose();
        if (mounted) setState(() => _error = true);
        return;
      }

      setState(() {
        _controller = controller;
        _initialized = true;
      });
    } catch (e) {
      debugPrint('VideoPlayer error: $e');
      await controller.dispose();
      if (mounted) setState(() => _error = true);
    }
  }

  // âœ… Poll until size is non-zero or timeout expires.
  // On Android 10, size is zero until the first frame is decoded.
  // Polling every 100ms with a 3s timeout covers all slow devices.
  Future<bool> _waitForFirstFrame(
      VideoPlayerController controller) async {
    const pollInterval = Duration(milliseconds: 100);
    const timeout = Duration(seconds: 3);
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      if (controller.value.size != Size.zero) return true;
      await Future.delayed(pollInterval);
    }
    return false;
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
    // Fallback: static image with same dark overlay
    if (_error) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            widget.fallbackAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Colors.black),
          ),
          ColoredBox(
            color: Colors.black.withOpacity(
                widget.darkenOpacity.clamp(0.0, 0.95)),
          ),
        ],
      );
    }

    if (!_initialized || _controller == null) {
      return const ColoredBox(color: Colors.black);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: 1.0,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
        ColoredBox(
          color: Colors.black.withOpacity(
              widget.darkenOpacity.clamp(0.0, 0.95)),
        ),
      ],
    );
  }
}
