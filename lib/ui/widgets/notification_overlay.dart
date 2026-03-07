import 'package:flutter/material.dart';
import 'notification_banner.dart';

class NotificationOverlay extends StatelessWidget {
  final Widget child;

  const NotificationOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [child, const NotificationBanner()]);
  }
}
