import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/colors.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
  });

  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    return TweenAnimationBuilder<double>(
      // Stable tween prevents flicker on rebuilds
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          margin: EdgeInsets.only(
            top: 6,
            bottom: 6,
            left: isMe ? 48 : 12,
            right: isMe ? 12 : 48,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMe ? 18 : 6),
              topRight: Radius.circular(isMe ? 6 : 18),
              bottomLeft: const Radius.circular(18),
              bottomRight: const Radius.circular(18),
            ),
            child: BackdropFilter(
              // Performance: lighter blur still looks glassy
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isMe
                      ? DreadmoorColors.accentCyan.withOpacity(0.12)
                      : DreadmoorColors.surface.withOpacity(0.35),
                  border: Border.all(
                    color: isMe
                        ? DreadmoorColors.accentCyan.withOpacity(0.28)
                        : Colors.white.withOpacity(0.08),
                    width: 0.6,
                  ),
                  boxShadow: isMe
                      ? const [
                          BoxShadow(
                            color: DreadmoorColors.glowCyan,
                            blurRadius: 14,
                            offset: Offset(0, 2),
                          )
                        ]
                      : const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          )
                        ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: SelectableText(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(isMe ? 0.95 : 0.85),
                      height: 1.5,
                      letterSpacing: 0.2,
                      fontWeight: isMe ? FontWeight.w400 : FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
