import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';

import 'package:audioplayers/audioplayers.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  final String callerName;
  final String callerNumber;
  final bool canDecline;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callerNumber,
    this.canDecline = true,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playRingtone();
  }

  Future<void> _playRingtone() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    // AssetSource expects path relative to 'assets/'
    await _audioPlayer.play(AssetSource('media/sfx/phone_ringtone_glitch.mp3'));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: Stack(
        children: [
          // 1. THE CINEMATIC BACKGROUND (Tower/Moon Hero)
          Positioned.fill(
            child: Image.asset(
              'assets/media/images/moon_tower_hero.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Darken overlay for maximum readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          // 2. CALLER IDENTITY LAYER
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // CIRCULAR PORTRAIT (Matches Profile UI)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.black54,
                      // Fallback to the masked "Unknown" avatar from your photos
                      backgroundImage: const AssetImage('assets/avatars/unknown_mask.png'),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // CALLER NAME (Spectral Serif)
                  Text(
                    widget.callerName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spectral(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // CALLER NUMBER (Technical Sans)
                  Text(
                    widget.callerNumber,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      color: Colors.white70,
                      letterSpacing: 2.0,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // STATUS (Investigator Cyan / Pulse)
                  Text(
                    "INCOMING CALL",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: DreadmoorColors.investigatorCyan,
                      letterSpacing: 4.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // 3. ACTION CONTROLS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: widget.canDecline ? 1.0 : 0.3,
                        child: IgnorePointer(
                          ignoring: !widget.canDecline,
                          child: _buildCallButton(
                            icon: Icons.call_end,
                            color: DreadmoorColors.evidenceRed,
                            label: "DECLINE",
                            onTap: widget.onDecline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 64),
                      _buildCallButton(
                        icon: Icons.call,
                        color: DreadmoorColors.investigatorCyan,
                        label: "ACCEPT",
                        onTap: widget.onAccept,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            color: Colors.white70,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
