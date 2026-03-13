import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' hide Column;

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/os/components/os_header.dart';
import 'package:dreadmoor/core/time/game_clock.dart';
import 'package:dreadmoor/features/notifications/notification_state.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/features/notifications/app_notification.dart';
import 'package:dreadmoor/core/state/game_state.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final historyAsync = ref.watch(activeNotificationsProvider);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            OSHeader(
              title: "LOGS",
              subtitle: "RECENT ACTIVITY",
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.clear_all, size: 24),
                onPressed: () async {
                  await (db.update(db.notifications))
                      .write(const NotificationsCompanion(isRead: Value(true)));
                },
              ),
            ),
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text("Sync Error: $err")),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return Center(
                      child: Text(
                        "SYSTEM CLEAR",
                        style: GoogleFonts.spaceGrotesk(
                          letterSpacing: 4,
                          color: DreadmoorColors.text(brightness).withOpacity(0.3),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => Divider(
                      color: DreadmoorColors.divider(brightness),
                      height: 32,
                    ),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final timeStr = formatGameTime(notif.createdAtMinutes);
                      final accent = isDark ? DreadmoorColors.investigatorCyan : DreadmoorColors.evidenceRed;

                      return GestureDetector(
                        onTap: () {
                          final payload = notif.payload;
                          if (payload != null && payload["route"] != null) {
                            Navigator.of(context).pushNamed(payload["route"], arguments: payload);
                          }
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── ICON BLOCK (Sharp) ──
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                border: Border.all(color: DreadmoorColors.divider(brightness)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                _getIcon(notif.type),
                                color: accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // ── CONTENT ──
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        notif.title.toUpperCase(),
                                        style: GoogleFonts.spectral(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: DreadmoorColors.text(brightness),
                                        ),
                                      ),
                                      Text(
                                        timeStr,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: DreadmoorColors.text(brightness).withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.message,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: DreadmoorColors.text(brightness).withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message: return Icons.chat_bubble_outline;
      case NotificationType.article: return Icons.newspaper_outlined;
      case NotificationType.system: return Icons.settings_input_component_outlined;
    }
  }
}
