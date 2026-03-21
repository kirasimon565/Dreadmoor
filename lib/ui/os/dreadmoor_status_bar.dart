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

    SystemChrome.setSystemUIOverlayStyle(
      brightness == Brightness.dark
          ? const SystemUiOverlayStyle(
              statusBarColor:            Colors.transparent,
              statusBarIconBrightness:   Brightness.light,
              statusBarBrightness:       Brightness.dark,
            )
          : const SystemUiOverlayStyle(
              statusBarColor:            Colors.transparent,
              statusBarIconBrightness:   Brightness.dark,
              statusBarBrightness:       Brightness.light,
            ),
    );

    return SafeArea(
      bottom: false,
      child: Container(
        height: 24,
        // FIX: fully transparent — no solid colour, no tint.
        // The single global status bar from DreadmoorOS floats
        // over all screens without obscuring any background.
        color:   Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
                  fontSize:   12,
                  color:      DreadmoorColors.text(brightness).withOpacity(0.75),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const d_nc.NotificationCenterScreen(),
                ),
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
      ),
    );
  }
}
