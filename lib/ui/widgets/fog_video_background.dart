import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FogVideoBackground extends StatefulWidget {
  const FogVideoBackground({
    super.key,
    required this.assetPath,
    this.darkenOpacity = 0.65, // This parameter might be redundant if we enforce max opacity.
                               // But user asked to control it. Let's interpret "fog should be at 0.15 opacity max"
                               // as meaning the video layer itself is faint.
  });

  final String assetPath;
  final double darkenOpacity;

  @override
  State<FogVideoBackground> createState() => _FogVideoBackgroundState();
}

class _FogVideoBackgroundState extends State<FogVideoBackground> {
  late final VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        if (!mounted) return;
        _controller.setLooping(true);
        _controller.setVolume(0);
        _controller.play();
        setState(() {
          _initialized = true;
        });
      }).catchError((error) {
        debugPrint("VideoPlayer error: $error");
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const ColoredBox(color: Colors.black);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base Black
        const ColoredBox(color: Colors.black),

        // Fog Video Layer (Subtle)
        Opacity(
          opacity: 0.15, // Enforcing the max opacity rule
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
