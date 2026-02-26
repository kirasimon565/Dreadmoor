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
  // ✅ Capture the actual error message so we can show it on screen
  String _errorMessage = '';

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
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) { await controller.dispose(); return; }

      await controller.play();

      if (controller.value.size == Size.zero) {
        await controller.dispose();
        if (mounted) setState(() {
          _error = true;
          _errorMessage = 'size=zero after init';
        });
        return;
      }

      setState(() {
        _controller = controller;
        _initialized = true;
      });
    } catch (e) {
      await controller.dispose();
      if (mounted) setState(() {
        _error = true;
        _errorMessage = e.toString();
      });
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
    if (_error) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Try fallback image
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
          // ✅ Show error message on screen so we can see it without logcat
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.red.withOpacity(0.7),
              child: Text(
                'VIDEO ERROR:\n$_errorMessage',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
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
              widget.darkenOpacity.clamp(0.0, 0.95)),
        ),
      ],
    );
  }
}
