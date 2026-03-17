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

    // Make Android system status bar completely transparent
    SystemChrome.setSystemUIOverlayStyle(
      brightness == Brightness.dark
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
    );

    // Removing the explicit height binding so SafeArea can handle the sizing
    // or just leaving a fixed minimal padding
    return Container(
      height: 32, // Fixed height since safe area handles the notch above it
      color: Colors.transparent, // Ensure it's perfectly transparent
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          /// Clock (tap opens notification center)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const d_nc.NotificationCenterScreen(),
                ),
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

          /// Signal / WiFi / Battery
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const d_nc.NotificationCenterScreen(),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.signal_cellular_4_bar,
                  size: 14,
                  color: DreadmoorColors.text(brightness).withOpacity(0.75),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.wifi,
                  size: 14,
                  color: DreadmoorColors.text(brightness).withOpacity(0.75),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.battery_full,
                  size: 14,
                  color: DreadmoorColors.text(brightness).withOpacity(0.75),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
