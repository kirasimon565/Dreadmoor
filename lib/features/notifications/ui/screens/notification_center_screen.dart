import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/os/components/os_header.dart';
import 'package:dreadmoor/core/time/game_clock.dart';
import 'package:dreadmoor/features/notifications/notification_state.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final history = state.history;

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OSHeader(
              title: "NOTIFICATIONS",
              subtitle: "RECENT ACTIVITY",
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios, color: DreadmoorColors.textSecondary, size: 20),
              ),
              trailing: GestureDetector(
                onTap: () => ref.read(notificationProvider.notifier).clearHistory(),
                child: const Icon(Icons.delete_outline, color: DreadmoorColors.textSecondary, size: 20),
              ),
            ),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Text(
                        "No recent notifications",
                        style: DreadmoorTheme.bodyStyle.copyWith(
                          color: DreadmoorColors.textMeta,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.white.withOpacity(0.05),
                        height: 24,
                      ),
                      itemBuilder: (context, index) {
                        final notif = history[index];
                        final timeStr = formatGameTime(notif.createdAtMinutes);

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
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: DreadmoorColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.notifications, color: DreadmoorColors.accentCyan, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          notif.title,
                                          style: DreadmoorTheme.headingStyle.copyWith(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          timeStr,
                                          style: DreadmoorTheme.bodyStyle.copyWith(
                                            color: DreadmoorColors.textSecondary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.message,
                                      style: DreadmoorTheme.bodyStyle.copyWith(
                                        color: DreadmoorColors.textSecondary,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
