import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/core/time/game_clock.dart';
import 'package:dreadmoor/features/notifications/ui/screens/notification_center_screen.dart'
    as d_nc;

class DreadmoorStatusBar extends ConsumerWidget {
  const DreadmoorStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeString = ref.watch(gameClockStringProvider);
    final brightness = Theme.of(context).brightness;

    // Make the system status bar (battery/wifi/time at very top) transparent
    // so it matches the app status bar visually.
    SystemChrome.setSystemUIOverlayStyle(
      brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
    );

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // FIX: transparent — no background, no border.
      // The status bar now floats over whatever screen is beneath it,
      // exactly like a real phone OS status bar.
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Game clock — taps open notification centre
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const d_nc.NotificationCenterScreen()),
            ),
            child: Text(
              timeString,
              style: DreadmoorTheme.bodyStyle(brightness).copyWith(
                fontSize: 12,
                color: DreadmoorColors.text(brightness).withOpacity(0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Signal / WiFi / Battery icons
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const d_nc.NotificationCenterScreen()),
            ),
            child: Row(
              children: [
                Icon(Icons.signal_cellular_4_bar,
                    size: 14,
                    color: DreadmoorColors.text(brightness).withOpacity(0.75)),
                const SizedBox(width: 6),
                Icon(Icons.wifi,
                    size: 14,
                    color: DreadmoorColors.text(brightness).withOpacity(0.75)),
                const SizedBox(width: 6),
                Icon(Icons.battery_full,
                    size: 14,
                    color: DreadmoorColors.text(brightness).withOpacity(0.75)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
