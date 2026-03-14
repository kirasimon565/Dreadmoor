import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/widgets/audio_waveform_glitch.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  final String callerName;
  final String callerNumber;
  final Function(int) onEnd;

  const ActiveCallScreen({
    super.key,
    required this.callerName,
    required this.callerNumber,
    required this.onEnd,
  });

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> {
  int _seconds = 0;
  Timer? _timer;
  bool _isMuted = false;
  bool _isSpeaker = false;
  final AudioPlayer _ringtonePlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playBackgroundGlitches();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  Future<void> _playBackgroundGlitches() async {
    await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
    await _ringtonePlayer.setVolume(0.3);
    // AssetSource expects path relative to 'assets/', so we pass 'media/sfx/...'
    await _ringtonePlayer.play(AssetSource('media/sfx/phone_ringtone_glitch.mp3'));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringtonePlayer.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: Stack(
        children: [
          // 1. CINEMATIC BACKGROUND (Matches your Profile/Call redesign)
          Positioned.fill(
            child: Image.asset(
              'assets/media/images/moon_tower_hero.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay for text contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // 2. CALLER IDENTITY (Large Portrait Circle)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.black54,
                    // Use a generic mask or resolve character avatar
                    backgroundImage: const AssetImage('assets/avatars/unknown_mask.png'),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  widget.callerName.toUpperCase(),
                  style: GoogleFonts.spectral(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  _formattedTime,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    color: DreadmoorColors.investigatorCyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),

                const Spacer(),

                // ── ANIMATED WAVEFORM GLITCH ────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: AudioWaveformGlitch(),
                ),

                const Spacer(),

                // 3. MID-CALL CONTROLS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic_none,
                        label: "MUTE",
                        isActive: _isMuted,
                        onTap: () => setState(() => _isMuted = !_isMuted),
                      ),
                      _buildControlButton(
                        icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                        label: "SPEAKER",
                        isActive: _isSpeaker,
                        onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // 4. END CALL ACTION (The Big Red Button)
                GestureDetector(
                  onTap: () => widget.onEnd(_seconds),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: DreadmoorColors.evidenceRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  "END CALL",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54,
                    letterSpacing: 2,
                  ),
                ),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
