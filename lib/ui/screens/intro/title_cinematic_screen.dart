import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
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

class _TitleCinematicScreenState extends ConsumerState<TitleCinematicScreen>
    with TickerProviderStateMixin {
  final String _word = "DREADMOOR";
  final List<Color> _colors = const [
    Color(0xFF00FFFF), // neon blue
    Colors.white, // cold white
    Colors.cyan, // cyan
    Colors.grey, // grey
    Color(0xFF00008B), // deep blue
    Colors.blueGrey, // steel grey
    Color(0xFF00FFFF), // neon blue
    Colors.cyan, // cyan
    Colors.white, // white
  ];

  late List<AnimationController> _letterControllers;
  late List<Animation<double>> _letterFades;
  late List<Animation<double>> _letterScales;

  late AnimationController _cameraController;
  late Animation<double> _cameraScale;

  late AnimationController _fadeToBlackController;
  late Animation<double> _fadeToBlackOpacity;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _letterControllers = List.generate(
      _word.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );

    _letterFades = _letterControllers.map((ctrl) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic),
      );
    }).toList();

    _letterScales = _letterControllers.map((ctrl) {
      return Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic),
      );
    }).toList();

    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _cameraScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _cameraController, curve: Curves.easeOut),
    );

    _fadeToBlackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeToBlackOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeToBlackController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    for (int i = 0; i < _word.length; i++) {
      await Future.delayed(const Duration(milliseconds: 220));
      if (mounted) _letterControllers[i].forward();
    }

    if (mounted) {
      _audioPlayer.play(AssetSource('media/sfx/title_hit.mp3'));
      _cameraController.forward();
    }

    // Hold for 1 second as requested
    await Future.delayed(const Duration(seconds: 1));

    // Fade to black
    if (mounted) {
      await _fadeToBlackController.forward();
    }

    if (mounted) {
      // Transition to OS, resume scheduler
      final scheduler = ref.read(globalSchedulerProvider);
      scheduler.resume();
      context.go(Routes.os);
    }
  }

  @override
  void dispose() {
    for (var ctrl in _letterControllers) {
      ctrl.dispose();
    }
    _cameraController.dispose();
    _fadeToBlackController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _cameraScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _cameraScale.value,
                  child: child,
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_word.length, (index) {
                  return AnimatedBuilder(
                    animation: _letterControllers[index],
                    builder: (context, child) {
                      return Opacity(
                        opacity: _letterFades[index].value,
                        child: Transform.scale(
                          scale: _letterScales[index].value,
                          child: Text(
                            _word[index],
                            style: TextStyle(
                              fontFamily: 'NoirDisplay',
                              fontSize: 48,
                              letterSpacing: 4.0,
                              color: _colors[index],
                              shadows: [
                                Shadow(
                                  color: _colors[index].withOpacity(0.5),
                                  blurRadius: 10.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ),

          // Fade to black overlay
          AnimatedBuilder(
            animation: _fadeToBlackOpacity,
            builder: (context, child) {
              return IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity(_fadeToBlackOpacity.value),
                ),
              );
            }
          ),
        ],
      ),
    );
  }
}
