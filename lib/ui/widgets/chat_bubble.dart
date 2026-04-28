import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/widgets/media_viewer.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/time/game_clock.dart';

class ChatBubble extends ConsumerWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.senderId,
    this.senderName,
    this.timestamp,
    this.isSecret = false,
    this.mediaType,
    this.mediaPath,
    this.isGroup = false,
  });

  final String text;
  final bool isMe;
  final String? senderId;
  final String? senderName;
  final DateTime? timestamp;
  final bool isSecret;
  final String? mediaType;
  final String? mediaPath;
  final bool isGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── SYSTEM EVENTS ─────────────────────────────────────────────────────────
    if (senderId == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: Colors.white54,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
    }

    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    // ── ORIGINAL DREADMOOR COLORS RESTORED ───────────────────────────────────
    final Color bubbleFill = isSecret
        ? const Color(0xFF6B0000).withOpacity(0.55)
        : isMe
            ? const Color(0xFF0D3A4A).withOpacity(0.75)
            : const Color(0xFF0D1A28).withOpacity(0.72);

    final Color borderColor = isSecret
        ? const Color(0xFFCC2A2A).withOpacity(0.6)
        : isMe
            ? const Color(0xFF4A9EBF).withOpacity(0.5)
            : Colors.white.withOpacity(0.14);

    final Color textColor =
        isSecret ? const Color(0xFFFF6B6B) : Colors.white.withOpacity(0.92);

    final Color nameColor =
        isMe ? const Color(0xFF4A9EBF) : const Color(0xFFB0C8D8);

    final Color timestampColor = isSecret
        ? const Color(0xFFFF8A8A).withOpacity(0.45)
        : Colors.white.withOpacity(0.35);

    // ── ORIGINAL BORDER SHAPE RESTORED ───────────────────────────────────────
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isMe ? 14 : 2),
      bottomRight: Radius.circular(isMe ? 2 : 14),
    );

    final timeText = timestamp != null ? _formatTime(timestamp!) : null;

    final showSenderName = !isMe &&
        senderId != null &&
        senderId != 'system' &&
        senderId != 'player';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 220),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 6 * (1 - value)),
          child: child,
        ),
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,

        // ORIGINAL OUTER SPACING RESTORED
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
          decoration: BoxDecoration(
            color: bubbleFill,
            borderRadius: radius,
            border: Border.all(color: borderColor, width: 0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSecret ? 0.35 : 0.22),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              if (isSecret)
                BoxShadow(
                  color: const Color(0xFFCC2A2A).withOpacity(0.18),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── SENDER NAME ───────────────────────────────────────────
                  if (showSenderName) ...[
                    Text(
                      ((senderName?.trim().isNotEmpty ?? false)
                              ? senderName!
                              : senderId!)
                          .toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: nameColor,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // ── VIDEO ────────────────────────────────────────────────
                  if (mediaType == 'video' && mediaPath != null) ...[
                    GestureDetector(
                      onTap: () {
                        ref.read(globalSchedulerProvider).pause();
                        MediaViewer.open(
                          context,
                          items: [
                            GalleryMediaItem(
                              path: mediaPath!,
                              isVideo: true,
                            ),
                          ],
                        );
                      },
                      child: Container(
                        height: 160,
                        width: 220,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white24,
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ]

                  // ── IMAGE ────────────────────────────────────────────────
                  else if (mediaType == 'image' && mediaPath != null) ...[
                    GestureDetector(
                      onTap: () {
                        MediaViewer.open(
                          context,
                          items: [
                            GalleryMediaItem(
                              path: mediaPath!,
                              isVideo: false,
                            ),
                          ],
                        );
                      },
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 200,
                          maxWidth: 220,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: mediaPath!.startsWith('assets/')
                              ? Image.asset(
                                  mediaPath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ]

                  // ── TEXT ─────────────────────────────────────────────────
                  else ...[
                    SelectableText(
                      text,
                      style: GoogleFonts.spectral(
                        fontSize: 15,
                        height: 1.45,
                        color: textColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],

                  // ── TIMESTAMP INSIDE BUBBLE / RIGHT ALIGNED ──────────────
                  if (timeText != null) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        timeText,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          color: timestampColor,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return formatGameTimeFromDate(time);
  }
}
