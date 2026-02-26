import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FogVideoBackground extends StatefulWidget {
  const FogVideoBackground({
    super.key,
    required this.assetPath,
    this.darkenOpacity = 0.55,
    // âœ… Fallback image shown if video fails to render (e.g. older devices)
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
      // âœ… This is the key fix for Android 10.
      // Without mixWithOthers: true, the video player requests exclusive
      // audio focus on Android 10 which causes the video surface to
      // render black. Setting this makes it share the audio session
      // instead of fighting for it â€” even though this is a muted video.
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(true);
      await controller.setVolume(0);

      // Extra frame for Android 10 surface binding
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.play();

      // âœ… Verify the video is actually producing frames.
      // On some Android 10 devices initialize() succeeds but no frames
      // are decoded. Check size â€” a valid video always has non-zero size.
      if (controller.value.size == Size.zero) {
        debugPrint('ðŸŽ¥ Video initialized but size is zero â€” using fallback');
        await controller.dispose();
        if (mounted) setState(() => _error = true);
        return;
      }

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
    // âœ… Fallback: static image with same dark overlay
    // Shown on devices where video can't render (older Android, low-end)
    if (_error) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            widget.fallbackAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
          ),
          ColoredBox(
            color: Colors.black.withOpacity(
              widget.darkenOpacity.clamp(0.0, 0.95),
            ),
          ),
        ],
      );
    }

    // Loading state â€” black screen, no flash
    if (!_initialized || _controller == null) {
      return const ColoredBox(color: Colors.black);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),

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

        ColoredBox(
          color: Colors.black.withOpacity(
            widget.darkenOpacity.clamp(0.0, 0.95),
          ),
        ),
      ],
    );
  }
}
