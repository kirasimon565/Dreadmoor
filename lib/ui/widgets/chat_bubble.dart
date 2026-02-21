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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Opacity(opacity: value.clamp(0, 1), child: child),
        );
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          margin: EdgeInsets.only(top: 4, bottom: 4, left: isMe ? 48 : 0, right: isMe ? 0 : 48),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMe ? 18 : 4),
              topRight: Radius.circular(isMe ? 4 : 18),
              bottomLeft: const Radius.circular(18),
              bottomRight: const Radius.circular(18),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: isMe ? DreadmoorColors.accentCyan.withOpacity(0.12) : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: isMe ? DreadmoorColors.accentCyan.withOpacity(0.3) : Colors.white.withOpacity(0.07),
                    width: 0.5,
                  ),
                  boxShadow: isMe ? const [BoxShadow(color: DreadmoorColors.glowCyan, blurRadius: 16, offset: Offset(0, 2))] : null,
                ),
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(isMe ? 0.92 : 0.8),
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
    );
  }
}
