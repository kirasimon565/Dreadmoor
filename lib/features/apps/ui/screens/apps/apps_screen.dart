import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/core/time/game_clock.dart';
import 'package:dreadmoor/core/state/game_state.dart';

class AppsScreen extends ConsumerWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalMinutes = ref.watch(gameClockProvider);
    final timeString = formatGameTime(totalMinutes);
    final dateString = formatGameDateFull(totalMinutes);

    // Browser unlocking logic tied directly to the story's "article_read" flag
    final flags = ref.watch(gameFlagsProvider);
    final browserUnlocked = flags['article_read'] == true;

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          // Subtle atmospheric background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.4),
                  radius: 1.2,
                  colors: [
                    DreadmoorColors.surfaceAlt,
                    DreadmoorColors.background,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Lock/Home Screen Clock Widget
                Column(
                  children: [
                    Text(
                      timeString,
                      style: DreadmoorTheme.headingStyle.copyWith(
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        color: DreadmoorColors.textPrimary,
                        letterSpacing: 2,
                        shadows: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 20,
                            )
                        ]
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateString.toUpperCase(),
                      style: DreadmoorTheme.bodyStyle.copyWith(
                        fontSize: 14,
                        color: DreadmoorColors.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Apps Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 4,
                    mainAxisSpacing: 32,
                    crossAxisSpacing: 20,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      if (browserUnlocked)
                        _buildAppIcon(
                          ref,
                          icon: Icons.public,
                          label: "Browser",
                          app: PhoneApp.browser,
                          color: Colors.blueAccent,
                        ),
                      _buildAppIcon(
                        ref,
                        icon: Icons.phone,
                        label: "Phone",
                        app: PhoneApp.phone,
                        color: DreadmoorColors.accentCyan,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48), // Padding above bottom nav
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon(WidgetRef ref, {
    required IconData icon,
    required String label,
    required PhoneApp app,
    required Color color,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(activeAppProvider.notifier).state = app;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: DreadmoorColors.surface, // Solid surface for app icons
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: DreadmoorTheme.bodyStyle.copyWith(
              color: DreadmoorColors.textPrimary,
              fontSize: 11,
              shadows: [
                 BoxShadow(color: Colors.black, blurRadius: 4)
              ]
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
