import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatHeaderNeonGroup extends StatelessWidget {
  final String title;
  final List<String> avatarPaths;
  final List<String> memberIds;
  final VoidCallback onBackPressed;
  final bool isOnline;
  final VoidCallback? onAvatarTap;
  final Map<String, VoidCallback>? onMemberTap;

  const ChatHeaderNeonGroup({
    super.key,
    required this.title,
    required this.avatarPaths,
    required this.memberIds,
    required this.onBackPressed,
    required this.isOnline,
    this.onAvatarTap,
    this.onMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final isGroup = memberIds.length > 1;

    final visible = avatarPaths.take(4).toList();
    final visibleIds = memberIds.take(4).toList();
    final extra = (avatarPaths.length - 4).clamp(0, 999);

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.only(
            top: topPad + 12, bottom: 12, left: 8, right: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: onAvatarTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spectral(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isGroup)
                    _StackedAvatars(
                      avatarPaths: visible,
                      memberIds: visibleIds,
                      extra: extra,
                      onMemberTap: onMemberTap,
                    )
                  else if (isOnline)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Live',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            )),
                      ],
                    ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onBackPressed,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.chevron_left,
                        color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── STACKED AVATARS ───────────────────────────────────────────────────────────

class _StackedAvatars extends StatelessWidget {
  final List<String> avatarPaths;
  final List<String> memberIds;
  final int extra;
  final Map<String, VoidCallback>? onMemberTap;

  const _StackedAvatars({
    required this.avatarPaths,
    required this.memberIds,
    required this.extra,
    this.onMemberTap,
  });

  static const double _size = 26;
  static const double _overlap = 16;

  @override
  Widget build(BuildContext context) {
    final count = avatarPaths.length;
    final totalW =
        _size + (count - 1) * _overlap + (extra > 0 ? _overlap : 0);

    return SizedBox(
      width: totalW,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...List.generate(count, (i) {
            VoidCallback? onTap;
            if (i < memberIds.length && onMemberTap != null) {
              onTap = onMemberTap![memberIds[i]];
            }

            return Positioned(
              left: i * _overlap,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4A9EBF).withOpacity(0.8),
                      width: 1.2,
                    ),
                    color: const Color(0xFF0D1E2A),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      avatarPaths[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _FallbackAvatar(),
                    ),
                  ),
                ),
              ),
            );
          }),
          if (extra > 0)
            Positioned(
              left: count * _overlap,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2A4A5E),
                  border: Border.all(
                    color: const Color(0xFF4A9EBF).withOpacity(0.6),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text('+$extra',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2A1A4A),
      child: const Icon(Icons.person, color: Color(0xFF8B5CF6), size: 20),
    );
  }
}
