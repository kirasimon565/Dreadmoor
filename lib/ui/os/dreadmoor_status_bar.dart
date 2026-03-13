import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/core/time/game_clock.dart';
import 'package:dreadmoor/features/notifications/ui/screens/notification_center_screen.dart' as d_nc;

class DreadmoorStatusBar extends ConsumerWidget {
  const DreadmoorStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeString = ref.watch(gameClockStringProvider);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: DreadmoorColors.surface(Theme.of(context).brightness),
        border: Border(
          bottom: BorderSide(
            color: DreadmoorColors.divider(Theme.of(context).brightness),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Time
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const d_nc.NotificationCenterScreen())
              );
            },
            child: Text(
              timeString,
              style: DreadmoorTheme.bodyStyle.copyWith(
                fontSize: 12,
                color: DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.7),
              ),
            ),
          ),

          // Icons (Signal, WiFi, Battery)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const d_nc.NotificationCenterScreen())
              );
            },
            child: Row(
              children: [
                const Icon(
                  Icons.signal_cellular_4_bar,
                  size: 14,
                  color: DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.wifi,
                  size: 14,
                  color: DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.battery_full,
                  size: 14,
                  color: DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
