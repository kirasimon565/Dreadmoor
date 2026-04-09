import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/core/time/game_clock.dart';
import 'package:dreadmoor/core/state/game_state.dart';

class AppsScreen extends ConsumerWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FIX: replaced gameClockProvider (in-game minutes, static after load)
    // with clockProvider (StreamProvider<DateTime>, ticks every second).
    final timeAsync = ref.watch(clockProvider);
    final b         = Theme.of(context).brightness;

    // Browser unlock logic — unchanged
    final flagsAsync       = ref.watch(gameFlagsProvider);
    final globalScheduler  = ref.watch(globalSchedulerProvider);
    final browserUnlocked  = flagsAsync.value?['article_read'] == true ||
        globalScheduler.hasProcessed('SCENE_1_NOTIFICATION_TRIGGER');

    return Scaffold(
      backgroundColor: DreadmoorColors.background(b),
      body: Stack(
        children: [
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // ── THE INVESTIGATOR CLOCK ──────────────────────────────
                  timeAsync.when(
                    data: (time) {
                      final timeString =
                          '${time.hour.toString().padLeft(2, '0')}'
                          ':${time.minute.toString().padLeft(2, '0')}';

                      final months = [
                        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
                      ];
                      final dateString =
                          '${_dayName(time.weekday)}, '
                          '${time.day} ${months[time.month - 1]} ${time.year}';

                      return Column(
                        children: [
                          Text(
                            timeString,
                            style: GoogleFonts.spectral(
                              fontSize:   82,
                              fontWeight: FontWeight.w200,
                              color:      DreadmoorColors.text(b),
                              letterSpacing: -2,
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -10),
                            child: Text(
                              dateString.toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize:   12,
                                fontWeight: FontWeight.bold,
                                color:      DreadmoorColors.text(b).withOpacity(0.5),
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(height: 120),
                    error:   (_, __) => const SizedBox(height: 120),
                  ),

                  const Spacer(),

                  // ── TACTICAL APP GRID ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Wrap(
                      spacing:   24,
                      runSpacing: 32,
                      alignment:  WrapAlignment.center,
                      children: [
                        _buildAppIcon(
                          ref,
                          icon:  Icons.phone_outlined,
                          label: 'DIALER',
                          app:   PhoneApp.phone,
                          b:     b,
                        ),
                        if (browserUnlocked)
                          TweenAnimationBuilder<double>(
                            tween:    Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve:    Curves.easeOutBack,
                            builder:  (context, value, child) {
                              return Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 0.8 + (0.2 * value),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildAppIcon(
                              ref,
                              icon:  Icons.language_outlined,
                              label: 'BROWSER',
                              app:   PhoneApp.browser,
                              b:     b,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _dayName(int weekday) {
    const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return names[(weekday - 1).clamp(0, 6)];
  }

  Widget _buildAppIcon(
    WidgetRef ref, {
    required IconData  icon,
    required String    label,
    required PhoneApp  app,
    required Brightness b,
  }) {
    final isDark = b == Brightness.dark;
    final accent = isDark
        ? DreadmoorColors.investigatorCyan
        : DreadmoorColors.evidenceRed;

    return GestureDetector(
      onTap: () => ref.read(activeAppProvider.notifier).state = app,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 64,
            width:  64,
            decoration: BoxDecoration(
              color:         isDark ? Colors.black26 : Colors.white54,
              borderRadius:  BorderRadius.circular(4),
              border:        Border.all(
                color: DreadmoorColors.divider(b), width: 1),
            ),
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color:      DreadmoorColors.text(b),
              fontSize:   9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
