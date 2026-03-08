import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/core/time/game_clock.dart';

class IncomingCallScreen extends ConsumerWidget {
  final String callerName;
  final String callerNumber;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callerNumber,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DreadmoorColors.scrimDark.withOpacity(0.9), // Dim the rest of OS
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: DreadmoorColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: DreadmoorColors.accentCyan.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: DreadmoorColors.accentCyan.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            Text(
              callerName,
              style: DreadmoorTheme.headingStyle.copyWith(
                fontSize: 28,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              callerNumber,
              style: DreadmoorTheme.bodyStyle.copyWith(
                fontSize: 16,
                color: DreadmoorColors.textSecondary,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "INCOMING CALL",
              style: DreadmoorTheme.bodyStyle.copyWith(
                fontSize: 14,
                color: DreadmoorColors.accentCyan,
                letterSpacing: 4.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 64),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCallButton(
                  icon: Icons.call_end,
                  color: DreadmoorColors.accentRed,
                  label: "Decline",
                  onTap: onDecline,
                ),
                const SizedBox(width: 64),
                _buildCallButton(
                  icon: Icons.call,
                  color: DreadmoorColors.accentCyan,
                  label: "Accept",
                  onTap: onAccept,
                ),
              ],
            ),
          ],
        ),
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
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label.toUpperCase(),
          style: DreadmoorTheme.bodyStyle.copyWith(
            fontSize: 12,
            color: color,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
