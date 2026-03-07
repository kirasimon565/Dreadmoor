import 'package:flutter/material.dart';

enum NotificationType {
  message,
  article,
  system,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final Map<String, dynamic>? payload;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.payload,
  });
}
