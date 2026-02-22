import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FogVideoBackground extends StatefulWidget {
  const FogVideoBackground({
    super.key,
    required this.assetPath,
    this.darkenOpacity = 0.55, // Dark overlay on top of the video.
    // Adjust this in the parent to tune visibility:
    // 0.0 = full video visible, 1.0 = fully black. 0.55 is cinematic default.
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

    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        if (!mounted) return;
        _controller
          ..setLooping(true)
          ..setVolume(0)
          ..play();
        setState(() => _initialized = true);
      }).catchError((error) {
        debugPrint('ðŸŽ¥ VideoPlayer error: $error');
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
    // Always show a black base â€” never a blank white flash while loading
    if (_error || !_initialized) {
      return const ColoredBox(color: Colors.black);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // â”€â”€ Base black so screen edges never flash white â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        const ColoredBox(color: Colors.black),

        // â”€â”€ Video at full opacity with cinematic fade-in â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        // âœ… Removed the fogOpacity clamp that was hiding the video.
        //    The darkenOpacity overlay below is the only brightness control.
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

        // â”€â”€ Dark overlay â€” keeps UI text readable over the video â”€â”€â”€â”€â”€â”€â”€
        Container(
          color: Colors.black.withOpacity(
            widget.darkenOpacity.clamp(0.0, 0.95),
          ),
        ),
      ],
    );
  }
}
