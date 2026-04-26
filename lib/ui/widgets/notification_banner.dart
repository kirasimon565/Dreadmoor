import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/features/notifications/notification_state.dart';
import 'package:dreadmoor/features/notifications/app_notification.dart';
import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:flutter/foundation.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/navigation/app_router.dart';
import 'package:dreadmoor/ui/navigation/routes.dart';

class NotificationBanner extends ConsumerStatefulWidget {
  const NotificationBanner({super.key});

  @override
  ConsumerState<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends ConsumerState<NotificationBanner> {
  Timer? _dismissTimer;
  String? _currentNotifId;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _markAsRead(String id) async {
    if (!mounted) return;
    final db = ref.read(databaseProvider);
    await (db.update(db.notifications)..where((n) => n.id.equals(id)))
        .write(const NotificationsCompanion(isRead: Value(true)));
  }

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(activeNotificationsProvider);

    if (notifsAsync.isLoading ||
        notifsAsync.hasError ||
        notifsAsync.value == null ||
        notifsAsync.value!.isEmpty) {
      _dismissTimer?.cancel();
      _currentNotifId = null;
      return const SizedBox();
    }

    final notification = notifsAsync.value!.last;

    // Restart timer if notification changes
    if (_currentNotifId != notification.id) {
      _currentNotifId = notification.id;
      _dismissTimer?.cancel();
    }

    final activeApp = ref.watch(activeAppProvider);
    final activeThreadId = ref.watch(activeThreadIdProvider);

    final payloadMap = notification.payload;

    bool isAlreadyViewing = false;

    if (notification.type == NotificationType.chat) {
      final threadId = payloadMap?['threadId'];
      isAlreadyViewing =
          (activeApp == PhoneApp.messenger) && (activeThreadId == threadId);
    } else if (notification.type == NotificationType.article) {
      // TODO: match article id/headline when available in payload identity
      isAlreadyViewing = (activeApp == PhoneApp.browser);
    }

    if (isAlreadyViewing) {
      // Auto dismiss logic
      if (_dismissTimer == null || !_dismissTimer!.isActive) {
         _dismissTimer = Timer(const Duration(seconds: 2), () {
            _markAsRead(notification.id);
         });
      }

      return Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'New Message',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    // Standard Full Notification UI
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      right: 10,
      child: GestureDetector(
        onTap: () {
          // 1. Validate payload
          if (notification.type == NotificationType.chat) {
             final threadId = payloadMap?['threadId'];
             if (threadId == null) {
               if (kDebugMode) {
                 print("DreadmoorOS ⚠ Notification missing threadId payload.");
               }
               _markAsRead(notification.id);
               return;
             }
             // 2. Set App State
             ref.read(activeAppProvider.notifier).setApp(PhoneApp.messenger);
             ref.read(activeThreadIdProvider.notifier).setId(threadId);

             // 3. Navigate
             ref.read(appRouterProvider).go(Routes.chat(threadId));

             // 4. Mark as Read
             _markAsRead(notification.id);

          } else if (notification.type == NotificationType.article) {
             // 2. Set App State
             ref.read(activeAppProvider.notifier).setApp(PhoneApp.browser);

             // 4. Mark as Read
             _markAsRead(notification.id);
          } else {
             // System or other fallback
             _markAsRead(notification.id);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF14161A), // Deep blue/black
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: Colors.white.withOpacity(0.6), // Subtle accent bar
                width: 3,
              ),
              top: BorderSide(color: Colors.white.withOpacity(0.05)),
              right: BorderSide(color: Colors.white.withOpacity(0.05)),
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1F26),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: (payloadMap != null && payloadMap['avatarPath'] != null)
                    ? Image.asset(
                        payloadMap['avatarPath'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            color: Colors.white30,
                            size: 24),
                      )
                    : const Icon(Icons.person, color: Colors.white30, size: 24),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.3,
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
