import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/core/time/game_clock.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  final String callerName;
  final String callerNumber;
  final VoidCallback onEnd;

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

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: DreadmoorColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.person, size: 50, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Text(
              widget.callerName,
              style: DreadmoorTheme.headingStyle.copyWith(
                fontSize: 24,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formattedTime,
              style: DreadmoorTheme.bodyStyle.copyWith(
                fontSize: 16,
                color: DreadmoorColors.textSecondary,
                letterSpacing: 2.0,
              ),
            ),
            const Spacer(),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  label: "Mute",
                  isActive: _isMuted,
                  onTap: () {
                    setState(() {
                      _isMuted = !_isMuted;
                    });
                  },
                ),
                _buildControlButton(
                  icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                  label: "Speaker",
                  isActive: _isSpeaker,
                  onTap: () {
                    setState(() {
                      _isSpeaker = !_isSpeaker;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 64),
            // End Call
            GestureDetector(
              onTap: widget.onEnd,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: DreadmoorColors.accentRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DreadmoorColors.accentRed.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.call_end, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? Colors.white : Colors.white54;
    final bgColor = isActive ? Colors.white.withOpacity(0.2) : DreadmoorColors.surfaceAlt;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: DreadmoorTheme.bodyStyle.copyWith(
              fontSize: 12,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
