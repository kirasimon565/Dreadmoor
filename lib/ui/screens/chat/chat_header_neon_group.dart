import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

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
    final topPadding = MediaQuery.of(context).padding.top;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: reduceMotion ? 0 : 14,
          sigmaY: reduceMotion ? 0 : 14,
        ),
        child: Container(
          height: 84 + topPadding,
          padding: EdgeInsets.only(top: topPadding),
          decoration: BoxDecoration(
            color: DreadmoorColors.surface.withOpacity(0.55),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back button
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: DreadmoorColors.accentCyan,
                  size: 18,
                ),
                onPressed: onBackPressed,
                tooltip: 'Back',
              ),

              const SizedBox(width: 4),

              // ── Neon group square icon ──────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  // ✅ Subtle glow kept tasteful — no harsh neon
                  boxShadow: [
                    BoxShadow(
                      color: DreadmoorColors.accentCyan.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/ui/neon_group_square.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        color: DreadmoorColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              DreadmoorColors.accentCyan.withOpacity(0.3),
                          width: 0.8,
                        ),
                      ),
                      child: const Icon(
                        Icons.group_rounded,
                        color: DreadmoorColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ── Title + stacked avatars ─────────────────────────────
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.michroma(
                        fontSize: 13,
                        letterSpacing: 2.0,
                        color: DreadmoorColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (avatarPaths.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _FoldedAvatars(avatarPaths: avatarPaths),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stacked/folded character avatars ──────────────────────────────────────

class _FoldedAvatars extends StatelessWidget {
  final List<String> avatarPaths;
  const _FoldedAvatars({required this.avatarPaths});

  static const double _avatarSize = 20.0;
  static const double _overlap = 13.0;

  @override
  Widget build(BuildContext context) {
    final visible = avatarPaths.take(5).toList();
    // ✅ Explicit width so Positioned children are never clipped
    final totalWidth =
        _avatarSize + (_overlap * (visible.length - 1).clamp(0, 4));

    return SizedBox(
      width: totalWidth,
      height: _avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(visible.length, (i) {
          return Positioned(
            left: i * _overlap,
            child: _SingleAvatar(path: visible[i]),
          );
        }),
      ),
    );
  }
}

class _SingleAvatar extends StatelessWidget {
  final String path;
  const _SingleAvatar({required this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: DreadmoorColors.background,
          width: 1.2,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          path,
          width: 20,
          height: 20,
          fit: BoxFit.cover,
          // Graceful fallback — shows a dim circle, not a crash
          errorBuilder: (_, __, ___) => Container(
            color: DreadmoorColors.surface,
            child: const Icon(
              Icons.person_rounded,
              size: 12,
              color: DreadmoorColors.textMeta,
            ),
          ),
        ),
      ),
    );
  }
}
