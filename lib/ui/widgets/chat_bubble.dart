import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.senderId,
    this.timestamp,
    this.isSecret = false,
  });

  final String text;
  final bool isMe;
  final String? senderId;
  final DateTime? timestamp;
  final bool isSecret;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          // Slide in slightly from the bottom while fading and scaling
          offset: Offset(0, 10 * (1 - value)),
          child: Transform.scale(
            scale: 0.95 + (0.05 * value),
            alignment: isMe ? Alignment.bottomRight : Alignment.bottomLeft,
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          ),
        );
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: isMe ? 48 : 0,
            right: isMe ? 0 : 48,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMe ? 18 : 6),
              topRight: Radius.circular(isMe ? 6 : 18),
              bottomLeft: const Radius.circular(18),
              bottomRight: const Radius.circular(18),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isSecret
                      ? DreadmoorColors.accentRed.withOpacity(0.1)
                      : isMe
                      ? DreadmoorColors.accentCyan.withOpacity(0.15)
                      : DreadmoorColors.surfaceAlt.withOpacity(0.6),
                  border: Border.all(
                    color: isSecret
                        ? DreadmoorColors.accentRed.withOpacity(0.4)
                        : isMe
                        ? DreadmoorColors.accentCyan.withOpacity(0.3)
                        : DreadmoorColors.borderSubtle.withOpacity(0.8),
                    width: 0.8,
                  ),
                  boxShadow: isSecret
                      ? [
                          BoxShadow(
                            color: DreadmoorColors.accentRed.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : isMe
                      ? [
                          BoxShadow(
                            color: DreadmoorColors.glowCyan.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SelectableText(
                        text,
                        style: DreadmoorTheme.bodyStyle.copyWith(
                          fontSize: 14,
                          color: isSecret
                              ? DreadmoorColors.accentRed.withOpacity(0.9)
                              : DreadmoorColors.textPrimary.withOpacity(isMe ? 1.0 : 0.9),
                          height: 1.5,
                          letterSpacing: 0.2,
                          fontWeight: isMe ? FontWeight.w400 : FontWeight.w300,
                        ),
                      ),
                      if (timestamp != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _formatTime(timestamp!),
                          style: DreadmoorTheme.bodyStyle.copyWith(
                            fontSize: 10,
                            color: isSecret
                                ? DreadmoorColors.accentRed.withOpacity(0.5)
                                : DreadmoorColors.textMeta.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    // In a real implementation this would format the Game Time rather than the real-world DateTime.
    // However, since Drift DB stores DateTime, we extract the hour/minute from it.
    // The scheduler sets this timestamp from the game clock when it creates the message.
    final hStr = time.hour.toString().padLeft(2, '0');
    final mStr = time.minute.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }
}
