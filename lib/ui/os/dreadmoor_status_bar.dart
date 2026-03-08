import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';

class DreadmoorStatusBar extends ConsumerWidget {
  const DreadmoorStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: DreadmoorColors.surfaceAlt,
        border: Border(
          bottom: BorderSide(
            color: DreadmoorColors.divider,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Time
          Text(
            '23:42', // Mock phone time
            style: DreadmoorTheme.bodyStyle.copyWith(
              fontSize: 12,
              color: DreadmoorColors.textSecondary,
            ),
          ),

          // Icons (Signal, WiFi, Battery)
          Row(
            children: [
              const Icon(
                Icons.signal_cellular_4_bar,
                size: 14,
                color: DreadmoorColors.textSecondary,
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.wifi,
                size: 14,
                color: DreadmoorColors.textSecondary,
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.battery_full,
                size: 14,
                color: DreadmoorColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
