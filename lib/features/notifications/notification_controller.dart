import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_notification.dart';

// Stores the history of all received notifications
class NotificationCenterState {
  final List<AppNotification> history;
  final List<AppNotification> activeBanners;

  NotificationCenterState({this.history = const [], this.activeBanners = const []});

  NotificationCenterState copyWith({
    List<AppNotification>? history,
    List<AppNotification>? activeBanners,
  }) {
    return NotificationCenterState(
      history: history ?? this.history,
      activeBanners: activeBanners ?? this.activeBanners,
    );
  }
}

class NotificationController extends Notifier<NotificationCenterState> {
  @override
  NotificationCenterState build() => NotificationCenterState();

  Timer? _timer;

  void push(AppNotification notification) {
    state = state.copyWith(
      history: [notification, ...state.history],
      activeBanners: [...state.activeBanners, notification],
    );

    // Keep banner visible for 4 seconds, then remove from active banners
    // Note: It stays in history forever.
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 4), () {
      dismissBanner(notification.id);
    });
  }

  void dismissBanner(String id) {
    state = state.copyWith(
      activeBanners: state.activeBanners.where((n) => n.id != id).toList(),
    );
  }

  void clearHistory() {
    state = state.copyWith(history: []);
  }
}
