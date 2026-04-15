import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/widgets/media_viewer.dart';
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
    // ── 5. SYSTEM EVENTS: timestamp-free, no bubble ───────────────────────
    if (senderId == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: Colors.white54,
            letterSpacing: 1.2,
          ),
        ),
      );
    }

    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    // ── 3. SENDER NAME RULE: Show for any non-player message ───────────────
    final showSenderName = !isMe && senderId != 'system' && senderId != 'player';

    // ── 1. DYNAMIC TIMESTAMP: Use real DateTime from model ─────────────────
    final String? timeText = timestamp != null ? _formatTime(timestamp!) : null;

    // ── COLOURS ───────────────────────────────────────────────────────────────
    final Color bubbleFill = isSecret
        ? const Color(0xFF111111).withOpacity(0.9)
        : isMe
            ? const Color(0xFF222222).withOpacity(0.9)
            : const Color(0xFF333333).withOpacity(0.7);

    final Color borderColor = isSecret
        ? const Color(0xFF880000).withOpacity(0.6)
        : Colors.white.withOpacity(0.1);

    final Color textColor = isSecret
        ? const Color(0xFFFF4444)
        : Colors.white.withOpacity(0.95);

    final Color nameColor = const Color(0xFFAAAAAA);

    final Color timestampColor = isSecret
        ? const Color(0xFF7A2A2A).withOpacity(0.65)
        : Colors.white.withOpacity(0.55);

    // ── BORDER RADIUS ─────────────────────────────────────────────────────────
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );

    // ── 4. FINAL CORRECT MESSAGE LAYOUT ────────────────────────────────────
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
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── SENDER NAME ──────────────────────────────────────────────
              if (showSenderName) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    (senderName ?? senderId!).toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: nameColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],

              // ── BUBBLE CONTAINER ─────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: bubbleFill,
                  borderRadius: radius,
                  border: Border.all(color: borderColor, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isSecret ? 0.5 : 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── MEDIA ──────────────────────────────────────────
                        if (mediaType == 'video' && mediaPath != null) ...[
                          GestureDetector(
                            onTap: () {
                              ref.read(globalSchedulerProvider).pause();
                              MediaViewer.open(
                                context,
                                items: [
                                  GalleryMediaItem(path: mediaPath!, isVideo: true),
                                ],
                              );
                            },
                            child: Container(
                              height: 160,
                              width: 220,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24, width: 1),
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
                        ] else if (mediaType == 'image' && mediaPath != null) ...[
                          GestureDetector(
                            onTap: () {
                              MediaViewer.open(
                                context,
                                items: [
                                  GalleryMediaItem(path: mediaPath!, isVideo: false),
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
                                    ? Image.asset(mediaPath!, fit: BoxFit.cover)
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ] else ...[
                          // ── MESSAGE TEXT ─────────────────────────────────
                          SelectableText(
                            text,
                            style: GoogleFonts.spectral(
                              fontSize: 16,
                              height: 1.4,
                              color: textColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ── 2. TIMESTAMP OUTSIDE BUBBLE ──────────────────────────────
              if (timeText != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    timeText,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: timestampColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
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
