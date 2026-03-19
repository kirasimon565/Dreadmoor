import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Original layout preserved exactly:
///   [←]  [ avatar  Name        ]
///                  Online •
///
/// Added: [memberIds] + [onMemberTap] for group threads so each
/// stacked avatar opens its own character profile independently.
class ChatHeaderNeonGroup extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;
  final List<String> avatarPaths;

  /// Character IDs in the same order as [avatarPaths].
  /// Required for per-avatar tap in group headers.
  final List<String> memberIds;

  final bool isOnline;

  /// Single-thread: tap anywhere on the pill → open profile.
  final VoidCallback? onAvatarTap;

  /// Group-thread: { characterId → VoidCallback } — each avatar taps independently.
  final Map<String, VoidCallback>? onMemberTap;

  const ChatHeaderNeonGroup({
    super.key,
    required this.title,
    required this.onBackPressed,
    required this.avatarPaths,
    this.memberIds = const [],
    this.isOnline = true,
    this.onAvatarTap,
    this.onMemberTap,
  });

  bool get _isGroup => avatarPaths.length > 1;

  @override
  Widget build(BuildContext context) {
    return _isGroup
        ? _GroupHeader(
            title:         title,
            avatarPaths:   avatarPaths,
            memberIds:     memberIds,
            onBackPressed: onBackPressed,
            isOnline:      isOnline,
            onTitleTap:    onAvatarTap,
            onMemberTap:   onMemberTap,
          )
        : _SingleHeader(
            title:         title,
            avatarPath:    avatarPaths.isNotEmpty ? avatarPaths.first : null,
            onBackPressed: onBackPressed,
            isOnline:      isOnline,
            onTap:         onAvatarTap,
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
        padding: EdgeInsets.only(
            top: topPad + 8, bottom: 12, left: 8, right: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [

            // ── PILL ──────────────────────────────────────────────────
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.62,
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white, width: 1.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar — 32px, left side of pill
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A0A2E),
                        border: Border.all(
                            color: Colors.white24, width: 1),
                      ),
                      child: ClipOval(
                        child: avatarPath != null
                            ? Image.asset(avatarPath!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const _FallbackAvatar())
                            : const _FallbackAvatar(),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Name + Online stacked vertically
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spectral(
                              color:      Colors.white,
                              fontSize:   18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isOnline)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Online',
                                    style: GoogleFonts.spaceGrotesk(
                                      color:      const Color(0xFF3DDB5E),
                                      fontSize:   11,
                                      fontWeight: FontWeight.w600,
                                    )),
                                const SizedBox(width: 4),
                                Container(
                                  width: 7, height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3DDB5E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── BACK ARROW ────────────────────────────────────────────
            Positioned(
              left: 0,
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
  final List<String> memberIds;
  final VoidCallback onBackPressed;
  final bool isOnline;
  final VoidCallback? onTitleTap;
  final Map<String, VoidCallback>? onMemberTap;

  const _GroupHeader({
    required this.title,
    required this.avatarPaths,
    required this.memberIds,
    required this.onBackPressed,
    required this.isOnline,
    this.onTitleTap,
    this.onMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPad  = MediaQuery.of(context).padding.top;
    final visible = avatarPaths.take(4).toList();
    final visibleIds = memberIds.take(4).toList();
    final extra   = (avatarPaths.length - 4).clamp(0, 999);

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.only(
            top: topPad + 8, bottom: 12, left: 8, right: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [

            // ── PILL ──────────────────────────────────────────────────
            Container(
              width: MediaQuery.of(context).size.width * 0.70,
              padding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 14),
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

                  // Stacked avatars — each independently tappable
                  _StackedAvatars(
                    avatarPaths: visible,
                    memberIds:   visibleIds,
                    extra:       extra,
                    onMemberTap: onMemberTap,
                  ),

                  const SizedBox(width: 10),

                  // Name + Online — tapping name opens first member
                  Flexible(
                    child: GestureDetector(
                      onTap: onTitleTap,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spectral(
                              color:      Colors.white,
                              fontSize:   17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isOnline)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Online',
                                    style: GoogleFonts.spaceGrotesk(
                                      color:      const Color(0xFF3DDB5E),
                                      fontSize:   11,
                                      fontWeight: FontWeight.w600,
                                    )),
                                const SizedBox(width: 4),
                                Container(
                                  width: 7, height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3DDB5E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── BACK ARROW ────────────────────────────────────────────
            Positioned(
              left: 0,
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

  static const double _size    = 26;
  static const double _overlap = 16;

  @override
  Widget build(BuildContext context) {
    final count  = avatarPaths.length;
    final totalW = _size + (count - 1) * _overlap +
        (extra > 0 ? _overlap : 0);

    return SizedBox(
      width: totalW,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Each avatar wrapped in its own GestureDetector
          ...List.generate(count, (i) {
            final id       = i < memberIds.length ? memberIds[i] : null;
            final onTap    = id != null ? onMemberTap?[id] : null;

            return Positioned(
              left: i * _overlap,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: _size, height: _size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4A9EBF)
                          .withOpacity(0.8),
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

          // +N overflow badge (not tappable)
          if (extra > 0)
            Positioned(
              left: count * _overlap,
              child: Container(
                width: _size, height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2A4A5E),
                  border: Border.all(
                    color:
                        const Color(0xFF4A9EBF).withOpacity(0.6),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text('+$extra',
                      style: GoogleFonts.spaceGrotesk(
                        color:      Colors.white,
                        fontSize:   8,
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

// ── SHARED ────────────────────────────────────────────────────────────────────

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2A1A4A),
      child: const Icon(Icons.person,
          color: Color(0xFF8B5CF6), size: 20),
    );
  }
}
