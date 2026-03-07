import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_notification.dart';

class NotificationController extends StateNotifier<List<AppNotification>> {
  NotificationController() : super([]);

  Timer? _timer;

  void push(AppNotification notification) {
    state = [...state, notification];

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 4), () {
      dismiss(notification.id);
    });
  }

  void dismiss(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clear() {
    state = [];
  }
}
