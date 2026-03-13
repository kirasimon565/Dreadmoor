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
    this.senderName,
    this.timestamp,
    this.isSecret = false,
  });

  final String text;
  final bool isMe;
  final String? senderId;
  final String? senderName;
  final DateTime? timestamp;
  final bool isSecret;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    // Resolve Colors based on our new Design Language
    final bubbleColor = isSecret
        ? DreadmoorColors.evidenceRed.withOpacity(0.15)
        : isMe
            ? (isDark 
                ? DreadmoorColors.investigatorCyan.withOpacity(0.15) 
                : Colors.black.withOpacity(0.05))
            : (isDark 
                ? DreadmoorColors.slateSurface 
                : Colors.white.withOpacity(0.8));

    final borderColor = isSecret
        ? DreadmoorColors.evidenceRed.withOpacity(0.5)
        : isMe
            ? DreadmoorColors.investigatorCyan.withOpacity(0.4)
            : DreadmoorColors.divider(brightness);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200), // Snappier for OS feel
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 5 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            // SHARP DESIGN: Mirroring the Case File cards
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(2),
              topRight: const Radius.circular(2),
              bottomLeft: Radius.circular(isMe ? 2 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 2),
            ),
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: isSecret ? [
              BoxShadow(
                color: DreadmoorColors.evidenceRed.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sender Name (Only for NPCs)
                if (!isMe && senderId != null && senderId != 'system' && senderId != 'player') ...[
                  Text(
                    (senderName ?? senderId!).toUpperCase(),
                    style: DreadmoorTheme.headingStyle(brightness).copyWith(
                      fontSize: 10,
                      color: isDark ? DreadmoorColors.investigatorCyan : DreadmoorColors.evidenceRed,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                
                // Message Content
                SelectableText(
                  text,
                  style: DreadmoorTheme.bodyStyle(brightness).copyWith(
                    fontSize: 15,
                    height: 1.4,
                    color: isSecret 
                        ? (isDark ? Colors.redAccent : DreadmoorColors.evidenceRed)
                        : DreadmoorColors.text(brightness),
                  ),
                ),

                // Timestamp
                if (timestamp != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(timestamp!),
                    style: DreadmoorTheme.bodyStyle(brightness).copyWith(
                      fontSize: 9,
                      color: DreadmoorColors.text(brightness).withOpacity(0.4),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hStr = time.hour.toString().padLeft(2, '0');
    final mStr = time.minute.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }
}
