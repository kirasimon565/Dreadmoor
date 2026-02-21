import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

class ChatHeaderNeonGroup extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;

  const ChatHeaderNeonGroup({
    super.key,
    required this.title,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          height: 88,
          decoration: const BoxDecoration(
            color: Color(0x05FFFFFF), // white.02 approx
            border: Border(
              bottom: BorderSide(
                color: Color(0x0FFFFFFF), // white.06 approx
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: DreadmoorColors.accentCyan, size: 20),
                  onPressed: onBackPressed,
                ),
                const SizedBox(width: 8),
                // Neon Group Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(color: DreadmoorColors.accentCyan.withOpacity(0.2), blurRadius: 10),
                    ],
                  ),
                  child: Image.asset(
                    'assets/ui/neon_group_square.png',
                    fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => const Icon(Icons.group, color: DreadmoorColors.accentCyan),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.michroma(
                          fontSize: 14,
                          letterSpacing: 2.0,
                          color: DreadmoorColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Folded avatars placeholder
                      // Ideally use a FoldedAvatars widget here
                      Row(
                        children: [
                          _buildMiniAvatar(Colors.red),
                          Transform.translate(offset: const Offset(-8, 0), child: _buildMiniAvatar(Colors.blue)),
                          Transform.translate(offset: const Offset(-16, 0), child: _buildMiniAvatar(Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniAvatar(Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1.5),
      ),
    );
  }
}
