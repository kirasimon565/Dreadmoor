import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';

class ChatHeaderNeonGroup extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;
  final List<String> avatarPaths;

  const ChatHeaderNeonGroup({
    super.key,
    required this.title,
    required this.onBackPressed,
    required this.avatarPaths,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          // ── THE GREY PILL HEADER (From your screenshot) ─────────────────
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              // Using a muted grey to match the "Unknown" header in your photo
              color: isDark ? const Color(0xFF333333) : const Color(0xFFC4C4C4),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Back Button (Left aligned)
                Positioned(
                  left: 10,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, 
                      size: 18, 
                      color: isDark ? Colors.white70 : Colors.black54
                    ),
                    onPressed: onBackPressed,
                  ),
                ),

                // Center Content: Large Avatar + Title
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The Avatar (Matches the "Unknown" masked icon)
                    Container(
                      width: 55,
                      height: 55,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                      child: ClipOval(
                        child: avatarPaths.isNotEmpty
                            ? Image.asset(avatarPaths.first, fit: BoxFit.cover)
                            : const Icon(Icons.group, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title (Matches the "Unknown" text style)
                    Text(
                      title,
                      style: GoogleFonts.spectral(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── GROUP MEMBER SUB-INDICATOR ──────────────────────────────────
          if (avatarPaths.length > 1) ...[
            const SizedBox(height: 12),
            _FoldedAvatars(avatarPaths: avatarPaths),
          ],
        ],
      ),
    );
  }
}

class _FoldedAvatars extends StatelessWidget {
  final List<String> avatarPaths;
  const _FoldedAvatars({required this.avatarPaths});

  @override
  Widget build(BuildContext context) {
    final visible = avatarPaths.take(5).toList();
    final brightness = Theme.of(context).brightness;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 24,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(visible.length, (i) {
              return Padding(
                padding: EdgeInsets.only(left: i * 16.0),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DreadmoorColors.background(brightness), 
                      width: 1.5
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(visible[i], fit: BoxFit.cover),
                  ),
                ),
              );
            }),
          ),
        ),
        if (avatarPaths.length > 5) ...[
          const SizedBox(width: 8),
          Text(
            "+${avatarPaths.length - 5}",
            style: TextStyle(
              fontSize: 10, 
              color: DreadmoorColors.text(brightness).withOpacity(0.5)
            ),
          ),
        ]
      ],
    );
  }
}
