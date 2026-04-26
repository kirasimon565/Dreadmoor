import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'app_notification.dart';

final activeNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final db = ref.read(databaseProvider);
  return (db.select(db.notifications)..where((n) => n.isRead.equals(false)))
      .watch()
      .map((rows) => rows.map((row) {
            final typeStr = row.type;
            NotificationType type = NotificationType.system;
            if (typeStr == 'chat') type = NotificationType.chat;
            if (typeStr == 'article') type = NotificationType.article;

            Map<String, dynamic>? payload;
            if (row.payload != null) {
              try {
                payload = jsonDecode(row.payload!);
              } catch (_) {}
            }

            return AppNotification(
              id: row.id,
              type: type,
              title: row.title,
              message: row.message,
              createdAtMinutes: row.createdAtMinutes,
              payload: payload,
            );
          }).toList());
});
