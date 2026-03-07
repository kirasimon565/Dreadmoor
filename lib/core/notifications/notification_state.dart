import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_controller.dart';
import 'app_notification.dart';

final notificationProvider =
    StateNotifierProvider<NotificationController, List<AppNotification>>(
  (ref) => NotificationController(),
);
