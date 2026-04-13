import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/widgets/media_viewer.dart';
import 'package:dreadmoor/ui/widgets/video_thumbnail_image.dart';
import 'package:dreadmoor/core/state/game_state.dart';

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
  });

  final String text;
  final bool isMe;
  final String? senderId;
  final String? senderName;
  final DateTime? timestamp;
  final bool isSecret;
  final String? mediaType;
  final String? mediaPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (senderId == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: Colors.white54,
                letterSpacing: 1.2,
              ),
            ),
            if (timestamp != null)
              Text(
                _formatTime(timestamp!),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9,
                  color: Colors.white38,
                ),
              ),
          ],
        ),
      );
    }

    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    // ── COLOURS ───────────────────────────────────────────────────────────────
    final Color bubbleFill = isSecret
        ? const Color(0xFF1E1E1E) // Dark charcoal for secret chat
        : Colors.white; // White for regular chats
    final Color borderColor =
        isSecret ? const Color(0xFF2E2E2E) : Colors.transparent;
    final Color textColor =
        isSecret ? const Color(0xFFFF6B6B) : const Color(0xFF1B242C); // Red accent for secret, dark for regular
    final Color nameColor =
        isMe ? const Color(0xFF4A9EBF) : const Color(0xFF8FA8B8);

    // ── BORDER RADIUS ─────────────────────────────────────────────────────────
    final radius = BorderRadius.circular(20); // Uniformly rounded corners

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
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
          decoration: BoxDecoration(
            color: bubbleFill,
            borderRadius: radius,
            border: Border.all(color: borderColor, width: 0.9),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── SENDER NAME (NPCs only) ──────────────────────────────
                  if (!isMe &&
                      senderId != null &&
                      senderId != 'system' &&
                      senderId != 'player') ...[
                    Text(
                      (senderName ?? senderId!).toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: nameColor,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // ── MEDIA (IF APPLICABLE) ────────────────────────────────
                  if (mediaType == 'video' && mediaPath != null) ...[
                    GestureDetector(
                      onTap: () {
                        ref.read(globalSchedulerProvider).pause();
                        MediaViewer.open(context, items: [
                          GalleryMediaItem(path: mediaPath!, isVideo: true)
                        ]);
                      },
                      child: Container(
                        height: 160,
                        width: 220,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: VideoThumbnailImage(videoPath: mediaPath!),
                            ),
                            Container(
                              color: Colors.black.withOpacity(0.3),
                              child: const Center(
                                child: Icon(Icons.play_circle_fill,
                                    color: Colors.white, size: 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (mediaType == 'image' && mediaPath != null) ...[
                    GestureDetector(
                      onTap: () {
                        MediaViewer.open(context, items: [
                          GalleryMediaItem(path: mediaPath!, isVideo: false)
                        ]);
                      },
                      child: Container(
                        constraints:
                            const BoxConstraints(maxHeight: 200, maxWidth: 220),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: mediaPath!.startsWith('assets/')
                              ? Image.asset(mediaPath!, fit: BoxFit.cover)
                              : const SizedBox.shrink(),
                          // Or Image.file for local files later
                        ),
                      ),
                    ),
                  ] else ...[
                    // ── MESSAGE TEXT ─────────────────────────────────────────
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
                  // ── TIMESTAMP ────────────────────────────────────────────
                  if (timestamp != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(timestamp!),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        color: isSecret
                            ? Colors.white.withOpacity(0.35)
                            : const Color(0xFF8FA8B8),
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w500,
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
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
