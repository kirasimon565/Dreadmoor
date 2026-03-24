import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:audioplayers/audioplayers.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/widgets/audio_waveform_glitch.dart';
import 'package:dreadmoor/features/phone/phone_state.dart';

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
  bool _isMuted   = false;
  bool _isSpeaker = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    // FIX: read callAudioPath synchronously once in initState.
    // Previously read inside an async method — by that point the provider
    // state may have already transitioned and the path was null.
    final callAudioPath = ref.read(phoneProvider).callAudioPath;

    if (callAudioPath != null && callAudioPath.isNotEmpty) {
      _playCallAudio(callAudioPath);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  Future<void> _playCallAudio(String path) async {
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.play(AssetSource(path));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds  % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/media/images/moon_tower_hero.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
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

                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.black54,
                    backgroundImage:
                        AssetImage('assets/avatars/unknown_mask.png'),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  widget.callerName.toUpperCase(),
                  style: GoogleFonts.spectral(
                    fontSize:   32,
                    fontWeight: FontWeight.bold,
                    color:      Colors.white,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _formattedTime,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize:   18,
                    color:      DreadmoorColors.investigatorCyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),

                const Spacer(),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: AudioWaveformGlitch(),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon:     _isMuted ? Icons.mic_off : Icons.mic_none,
                        label:    'MUTE',
                        isActive: _isMuted,
                        onTap: () => setState(() => _isMuted = !_isMuted),
                      ),
                      _buildControlButton(
                        icon: _isSpeaker
                            ? Icons.volume_up
                            : Icons.volume_down,
                        label:    'SPEAKER',
                        isActive: _isSpeaker,
                        onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                GestureDetector(
                  onTap: () => widget.onEnd(_seconds),
                  child: Container(
                    width:  80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: DreadmoorColors.evidenceRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_end,
                        color: Colors.white, size: 36),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'END CALL',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize:   10,
                    fontWeight: FontWeight.bold,
                    color:      Colors.white54,
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
    required IconData    icon,
    required String      label,
    required bool        isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width:  64,
            height: 64,
            decoration: BoxDecoration(
              color:  isActive ? Colors.white : Colors.white10,
              shape:  BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size:  28,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize:   10,
            color:      Colors.white70,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
