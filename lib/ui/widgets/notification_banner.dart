import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import 'package:dreadmoor/features/notifications/notification_state.dart';
import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';

class NotificationBanner extends ConsumerWidget {
  const NotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(activeNotificationsProvider);

    if (notifsAsync.isLoading ||
        notifsAsync.hasError ||
        notifsAsync.value == null ||
        notifsAsync.value!.isEmpty) {
      return const SizedBox();
    }

    final notification = notifsAsync.value!.last;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      right: 10,
      child: GestureDetector(
        onTap: () async {
          // Mark as read in DB
          final db = ref.read(databaseProvider);
          await (db.update(db.notifications)
                ..where((n) => n.id.equals(notification.id)))
              .write(const NotificationsCompanion(isRead: const Value(true)));

          final payload = notification.payload;

          if (payload != null) {
            final route = payload["route"];
            if (route != null) {
              if (route == '/browser') {
                // Unlock the browser by setting the article_read flag
                await db.into(db.storyState).insert(
                      const StoryStateCompanion(
                        key: Value('article_read'),
                        value: Value(true),
                      ),
                      mode: InsertMode.insertOrReplace,
                    );
                ref.read(activeAppProvider.notifier).setApp(PhoneApp.browser);

                // The Browser HomeScreen will automatically display the article
                // based on the story flag we just set. No need for fragile pushNamed routing.
              } else if (route == '/chat') {
                ref.read(activeAppProvider.notifier).setApp(PhoneApp.messenger);
                // The messenger navigator handles pushing the chat screen internally.
                // Usually we'd use a deep link mechanism here, but changing the tab gets them to the app.
              } else {
                // Fallback for other deep links if implemented later
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
              color: const Color(0xFF00FFD1)
                  .withOpacity(0.3), // Cyan tint to make it pop slightly
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
                child:
                    const Icon(Icons.notifications, color: Color(0xFF00FFD1)),
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
