import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Layout rules:
///   [←]          [  Name  [avatar]  ]          [Online •]
///   outside-left      pill (centred)          outside-right
///
/// [onAvatarTap] — tapping the pill navigates to the character's profile.
class ChatHeaderNeonGroup extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;
  final List<String> avatarPaths;
  final bool isOnline;
  final VoidCallback? onAvatarTap;

  const ChatHeaderNeonGroup({
    super.key,
    required this.title,
    required this.onBackPressed,
    required this.avatarPaths,
    this.isOnline = true,
    this.onAvatarTap,
  });

  bool get _isGroup => avatarPaths.length > 1;

  @override
  Widget build(BuildContext context) {
    return _isGroup
        ? _GroupHeader(
            title: title,
            avatarPaths: avatarPaths,
            onBackPressed: onBackPressed,
            isOnline: isOnline,
            onTap: onAvatarTap,
          )
        : _SingleHeader(
            title: title,
            avatarPath: avatarPaths.isNotEmpty ? avatarPaths.first : null,
            onBackPressed: onBackPressed,
            isOnline: isOnline,
            onTap: onAvatarTap,
          );
  }
}

// ── SINGLE CHARACTER HEADER ───────────────────────────────────────────────────

class _SingleHeader extends StatelessWidget {
  final String title;
  final String? avatarPath;
  final VoidCallback onBackPressed;
  final bool isOnline;
  final VoidCallback? onTap;

  const _SingleHeader({
    required this.title,
    required this.avatarPath,
    required this.onBackPressed,
    required this.isOnline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.only(top: topPad + 8, bottom: 12, left: 8, right: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── PILL ────────────────────────────────────────────────────
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.62,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white, width: 1.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spectral(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A0A2E),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: ClipOval(
                        child: avatarPath != null
                            ? Image.asset(
                                avatarPath!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const _FallbackAvatar(),
                              )
                            : const _FallbackAvatar(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── BACK ARROW — outside pill, absolute left ─────────────────
            Positioned(
              left: 0,
              child: GestureDetector(
                onTap: onBackPressed,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.chevron_left, color: Colors.white, size: 32),
                ),
              ),
            ),

            // ── ONLINE — outside pill, absolute right ────────────────────
            if (isOnline)
              Positioned(right: 0, child: _OnlineBadge()),
          ],
        ),
      ),
    );
  }
}

// ── GROUP HEADER ──────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String title;
  final List<String> avatarPaths;
  final VoidCallback onBackPressed;
  final bool isOnline;
  final VoidCallback? onTap;

  const _GroupHeader({
    required this.title,
    required this.avatarPaths,
    required this.onBackPressed,
    required this.isOnline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final visible = avatarPaths.take(4).toList();
    final extra = (avatarPaths.length - 4).clamp(0, 999);

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.only(top: topPad + 8, bottom: 12, left: 8, right: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── PILL ────────────────────────────────────────────────────
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.70,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3040).withOpacity(0.82),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFF4A9EBF).withOpacity(0.7),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A9EBF).withOpacity(0.18),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spectral(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StackedAvatars(avatarPaths: visible, extra: extra),
                  ],
                ),
              ),
            ),

            // ── BACK ARROW ───────────────────────────────────────────────
            Positioned(
              left: 0,
              child: GestureDetector(
                onTap: onBackPressed,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.chevron_left, color: Colors.white, size: 32),
                ),
              ),
            ),

            // ── ONLINE ───────────────────────────────────────────────────
            if (isOnline)
              Positioned(right: 0, child: _OnlineBadge()),
          ],
        ),
      ),
    );
  }
}

// ── STACKED AVATARS ───────────────────────────────────────────────────────────

class _StackedAvatars extends StatelessWidget {
  final List<String> avatarPaths;
  final int extra;
  const _StackedAvatars({required this.avatarPaths, required this.extra});

  static const double _size = 28;
  static const double _overlap = 18;

  @override
  Widget build(BuildContext context) {
    final count = avatarPaths.length;
    final totalW = _size + (count - 1) * _overlap + (extra > 0 ? _overlap : 0);

    return SizedBox(
      width: totalW,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...List.generate(count, (i) => Positioned(
            left: i * _overlap,
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4A9EBF).withOpacity(0.8), width: 1.2),
                color: const Color(0xFF0D1E2A),
              ),
              child: ClipOval(
                child: Image.asset(avatarPaths[i], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _FallbackAvatar()),
              ),
            ),
          )),
          if (extra > 0)
            Positioned(
              left: count * _overlap,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2A4A5E),
                  border: Border.all(color: const Color(0xFF4A9EBF).withOpacity(0.6), width: 1.2),
                ),
                child: Center(
                  child: Text('+$extra',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── SHARED ────────────────────────────────────────────────────────────────────

class _OnlineBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Online',
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 5),
          Container(
            width: 9, height: 9,
            decoration: const BoxDecoration(color: Color(0xFF3DDB5E), shape: BoxShape.circle),
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
      child: const Icon(Icons.person, color: Color(0xFF8B5CF6), size: 24),
    );
  }
}
