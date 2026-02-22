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
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: reduceMotion ? 0 : 14,
          sigmaY: reduceMotion ? 0 : 14,
        ),
        child: Container(
          height: 84 + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: DreadmoorColors.surface.withOpacity(0.55),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.6),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: DreadmoorColors.accentCyan, size: 20),
                onPressed: onBackPressed,
              ),
              const SizedBox(width: 6),

              // Neon Group Square
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: DreadmoorColors.accentCyan.withOpacity(0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/ui/neon_group_square.png',
                    fit: BoxFit.cover,
                  ),
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
                    const SizedBox(height: 6),

                    _FoldedAvatars(avatarPaths: avatarPaths),
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

class _FoldedAvatars extends StatelessWidget {
  final List<String> avatarPaths;

  const _FoldedAvatars({required this.avatarPaths});

  @override
  Widget build(BuildContext context) {
    final visible = avatarPaths.take(4).toList();

    return SizedBox(
      height: 20,
      child: Stack(
        children: List.generate(visible.length, (i) {
          return Positioned(
            left: i * 14.0,
            child: ClipOval(
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Colors.white, Colors.white],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  visible[i],
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
