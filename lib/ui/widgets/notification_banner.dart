import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/features/notifications/notification_state.dart';
import 'package:dreadmoor/ui/os/os_state.dart';

class NotificationBanner extends ConsumerWidget {
  const NotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);

    if (notifState.activeBanners.isEmpty) {
      return const SizedBox();
    }

    final notification = notifState.activeBanners.last;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      right: 10,
      child: GestureDetector(
        onTap: () {
          ref.read(notificationProvider.notifier).dismissBanner(notification.id);

          final payload = notification.payload;

          if (payload != null) {
            final route = payload["route"];
            if (route != null) {
              if (route == '/browser') {
                  ref.read(activeAppProvider.notifier).state = PhoneApp.browser;
              } else if (route == '/chat') {
                  ref.read(activeAppProvider.notifier).state = PhoneApp.messenger;
                  // The messenger navigator handles pushing the chat screen internally.
                  // Usually we'd use a deep link mechanism here, but changing the tab gets them to the app.
              } else {
                  Navigator.of(context).pushNamed(route, arguments: payload);
              }
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF242830), // Surface
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00FFD1).withOpacity(0.3), // Cyan tint to make it pop slightly
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1F26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications, color: Color(0xFF00FFD1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
