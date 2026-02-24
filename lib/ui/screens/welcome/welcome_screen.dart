import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/game_state.dart';
import '../../navigation/routes.dart';
import '../../theme/colors.dart';
import '../../widgets/fog_video_background.dart';

bool get isDebugMode {
  bool inDebug = false;
  assert(inDebug = true);
  return inDebug;
}

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // â”€â”€ Music â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _musicPlayer = AudioPlayer();
  bool _musicReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _initMusic();
  }

  Future<void> _initMusic() async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.55);

      // âœ… AudioContextAndroid.none = don't request audio focus at all.
      // This lets the video player keep running alongside the music
      // without one pausing the other. Both streams play concurrently.
      await _musicPlayer.setAudioContext(
        const AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            // âœ… none = no focus request â†’ video player not interrupted
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: [
              // âœ… mixWithOthers = play alongside other audio (video player)
              AVAudioSessionOptions.mixWithOthers,
            ],
          ),
        ),
      );

      await _musicPlayer.play(AssetSource('music/welcome_theme.mp3'));
      if (mounted) setState(() => _musicReady = true);
    } catch (e) {
      debugPrint('ðŸŽµ Welcome music unavailable: $e');
    }
  }

  Future<void> _stopMusicAndNavigate(VoidCallback navigate) async {
    // Fade out before navigating so the cut isn't jarring
    try {
      for (double v = 0.55; v >= 0; v -= 0.05) {
        await Future.delayed(const Duration(milliseconds: 30));
        await _musicPlayer.setVolume(v.clamp(0.0, 1.0));
      }
      await _musicPlayer.stop();
    } catch (_) {}
    navigate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breathingController.dispose();
    _musicPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _breathingController.stop();
      _musicPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      _breathingController.repeat(reverse: true);
      _musicPlayer.resume();
    }
  }

  bool get _hasActiveGame => ref.read(playerStateProvider) != null;

  void _onMainAction() {
    HapticFeedback.selectionClick();
    if (_hasActiveGame) {
      _continueGame();
    } else {
      _stopMusicAndNavigate(() => context.go(Routes.setup));
    }
  }

  void _continueGame() {
    final threadId = ref.read(activeThreadIdProvider);
    _stopMusicAndNavigate(() {
      if (threadId != null) {
        context.go(Routes.chat(threadId));
      } else {
        context.go(Routes.messenger);
      }
    });
  }

  void _openDebug() {
    if (!isDebugMode) return;
    HapticFeedback.heavyImpact();
    context.push(Routes.debug);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final player = ref.watch(playerStateProvider);
    final hasGame = player != null;

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          // â”€â”€ Video background â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const Positioned.fill(
            child: FogVideoBackground(
              assetPath: 'assets/backgrounds/welcome_fog_loop.mp4',
              darkenOpacity: 0.65,
            ),
          ),

          // â”€â”€ Glitch overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          IgnorePointer(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/ui/glitch_overlay.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // â”€â”€ Main content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // â”€â”€ Logo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Center(
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: reduceMotion ? 1.0 : _scaleAnimation.value,
                      child: GestureDetector(
                        onLongPress: _openDebug,
                        child: Image.asset(
                          'assets/branding/dreadmore_logo.png',
                          width: 200,
                          errorBuilder: (_, __, ___) => Text(
                            "DREADMOOR",
                            style: GoogleFonts.cinzel(
                              fontSize: 40,
                              color: Colors.white,
                              letterSpacing: 4.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // â”€â”€ Hero action button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _HeroButton(
                    label: hasGame ? "CONTINUE" : "START GAME",
                    onTap: _onMainAction,
                    reduceMotion: reduceMotion,
                  ),
                ),

                const Spacer(flex: 3),

                // â”€â”€ Bottom bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "BLACKMOON",
                        style: GoogleFonts.michroma(
                          fontSize: 10,
                          letterSpacing: 2.0,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),

                      // Settings icon
                      GestureDetector(
                        onTap: () => context.push(Routes.settings),
                        child: Icon(
                          Icons.settings_outlined,
                          size: 20,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),

                      // Music indicator â€” subtle, shows music is playing
                      _MusicIndicator(playing: _musicReady),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Music indicator â€” three tiny animated bars â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MusicIndicator extends StatefulWidget {
  final bool playing;
  const _MusicIndicator({required this.playing});

  @override
  State<_MusicIndicator> createState() => _MusicIndicatorState();
}

class _MusicIndicatorState extends State<_MusicIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _bars;

  @override
  void initState() {
    super.initState();
    // Three bars with staggered durations for organic feel
    _bars = [
      AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500)),
      AnimationController(
          vsync: this, duration: const Duration(milliseconds: 700)),
      AnimationController(
          vsync: this, duration: const Duration(milliseconds: 600)),
    ];
    if (widget.playing) {
      for (var c in _bars) {
        c.repeat(reverse: true);
      }
    }
  }

  @override
  void didUpdateWidget(_MusicIndicator old) {
    super.didUpdateWidget(old);
    if (widget.playing && !old.playing) {
      for (var c in _bars) {
        c.repeat(reverse: true);
      }
    } else if (!widget.playing && old.playing) {
      for (var c in _bars) {
        c.stop();
      }
    }
  }

  @override
  void dispose() {
    for (var c in _bars) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.playing) {
      // Show static "v1.0.0" when music hasn't loaded
      return Text(
        "v1.0.0",
        style: GoogleFonts.inter(
          fontSize: 10,
          letterSpacing: 1.5,
          color: Colors.white.withOpacity(0.25),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 2,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _bars[i],
          builder: (_, __) => Container(
            width: 2,
            height: 6 + (_bars[i].value * 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.28),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      }),
    );
  }
}

// â”€â”€ Hero glass button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HeroButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool reduceMotion;

  const _HeroButton({
    required this.label,
    required this.onTap,
    required this.reduceMotion,
  });

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed && !widget.reduceMotion ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 64,
              decoration: BoxDecoration(
                color: _pressed
                    ? DreadmoorColors.accentCyan.withOpacity(0.12)
                    : DreadmoorColors.surface.withOpacity(0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: DreadmoorColors.accentCyan
                      .withOpacity(_pressed ? 0.8 : 0.4),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: DreadmoorColors.accentCyan.withOpacity(0.9),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: GoogleFonts.michroma(
                      fontSize: 15,
                      letterSpacing: 3.0,
                      color: DreadmoorColors.accentCyan.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
