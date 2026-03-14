import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Handles both single-character and group chat headers.
/// Single → transparent white-border pill, one large avatar on the right.
/// Group  → semi-transparent dark-teal pill with stacked mini avatars.
class ChatHeaderNeonGroup extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;
  final List<String> avatarPaths;
  final bool isOnline;

  /// Pass more than one avatar path to trigger the group layout.
  const ChatHeaderNeonGroup({
    super.key,
    required this.title,
    required this.onBackPressed,
    required this.avatarPaths,
    this.isOnline = true,
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
          )
        : _SingleHeader(
            title: title,
            avatarPath: avatarPaths.isNotEmpty ? avatarPaths.first : null,
            onBackPressed: onBackPressed,
            isOnline: isOnline,
          );
  }
}

// ── SINGLE CHARACTER HEADER ───────────────────────────────────────────────────
// Transparent pill, white border, large avatar inside right of title.

class _SingleHeader extends StatelessWidget {
  final String title;
  final String? avatarPath;
  final VoidCallback onBackPressed;
  final bool isOnline;

  const _SingleHeader({
    required this.title,
    required this.avatarPath,
    required this.onBackPressed,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding + 6,
        bottom: 8,
        left: 14,
        right: 14,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── PILL ──────────────────────────────────────────────────────
          Container(
            width: MediaQuery.of(context).size.width * 0.72,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white, width: 1.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spectral(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 10),
                // Single large avatar
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
                            errorBuilder: (_, __, ___) =>
                                const _FallbackAvatar(),
                          )
                        : const _FallbackAvatar(),
                  ),
                ),
              ],
            ),
          ),

          // ── BACK ARROW ────────────────────────────────────────────────
          Positioned(
            left: 0,
            child: _BackButton(onTap: onBackPressed),
          ),

          // ── ONLINE DOT ────────────────────────────────────────────────
          if (isOnline)
            Positioned(
              right: 0,
              child: _OnlineBadge(),
            ),
        ],
      ),
    );
  }
}

// ── GROUP HEADER ──────────────────────────────────────────────────────────────
// Dark teal semi-transparent pill, group name + stacked mini avatars inside.

class _GroupHeader extends StatelessWidget {
  final String title;
  final List<String> avatarPaths;
  final VoidCallback onBackPressed;
  final bool isOnline;

  const _GroupHeader({
    required this.title,
    required this.avatarPaths,
    required this.onBackPressed,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final visible = avatarPaths.take(4).toList();
    final extra = avatarPaths.length - 4;

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding + 6,
        bottom: 8,
        left: 14,
        right: 14,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── PILL (group style: dark teal, slightly wider) ─────────────
          Container(
            width: MediaQuery.of(context).size.width * 0.78,
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
                  spreadRadius: 1,
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
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _StackedAvatars(avatarPaths: visible, extra: extra < 0 ? 0 : extra),
              ],
            ),
          ),

          // ── BACK ARROW ────────────────────────────────────────────────
          Positioned(
            left: 0,
            child: _BackButton(onTap: onBackPressed),
          ),

          // ── ONLINE DOT ────────────────────────────────────────────────
          if (isOnline)
            Positioned(
              right: 0,
              child: _OnlineBadge(),
            ),
        ],
      ),
    );
  }
}

// ── STACKED MINI AVATARS ──────────────────────────────────────────────────────

class _StackedAvatars extends StatelessWidget {
  final List<String> avatarPaths;
  final int extra;

  const _StackedAvatars({required this.avatarPaths, required this.extra});

  static const double _size = 28;
  static const double _overlap = 18;

  @override
  Widget build(BuildContext context) {
    final count = avatarPaths.length;
    final totalWidth = _size + (count - 1) * _overlap + (extra > 0 ? _overlap : 0);

    return SizedBox(
      width: totalWidth,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...List.generate(count, (i) {
            return Positioned(
              left: i * _overlap,
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
                    errorBuilder: (_, __, ___) => const _FallbackAvatar(),
                  ),
                ),
              ),
            );
          }),

          // "+N" overflow badge
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
                  child: Text(
                    '+$extra',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.chevron_left, color: Colors.white, size: 30),
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Online',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: Color(0xFF3DDB5E),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A0A2E),
      child: const Icon(Icons.person, color: Color(0xFF6B3FA0), size: 22),
    );
  }
}
