import 'package:flutter/material.dart';

enum NotificationType { chat, article, system }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final int createdAtMinutes; // Uses GameClock totalMinutes
  final Map<String, dynamic>? payload;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAtMinutes,
    this.payload,
  });
}
