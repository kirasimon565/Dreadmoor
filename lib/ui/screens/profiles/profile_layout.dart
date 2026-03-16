import 'dart:io';
import 'package:flutter/material.dart';

/// Shared profile layout — used by both CharacterProfileScreen
/// and PlayerProfileScreen.
///
/// Stack layers:
///   0 — Background image          (Positioned.fill)
///   1 — White card                (Positioned, FIXED — never moves)
///   1a— ScrollView inside card    (only content scrolls, card stays put)
///   2 — Circular avatar           (Positioned, FIXED)
///   3 — Back button               (Positioned, FIXED — optional)
class ProfileLayout extends StatelessWidget {
  final String?       avatarPath;
  final String?       headerImage;
  final String        heroTag;
  final VoidCallback? onAvatarTap;
  final List<Widget>  cardContent;
  final bool          showBackButton;

  // ── Layout constants ─────────────────────────────────────────────────
  static const double headerHeight = 320.0;
  static const double cardOverlap  = 56.0;
  static const double avatarRadius = 78.0;

  // Top of the card in viewport coordinates
  static const double _cardTop = headerHeight - cardOverlap;

  // Top of the avatar circle in viewport coordinates
  static const double _avatarTop = _cardTop - avatarRadius;

  const ProfileLayout({
    super.key,
    required this.avatarPath,
    required this.headerImage,
    required this.heroTag,
    required this.cardContent,
    this.onAvatarTap,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final topPad  = MediaQuery.of(context).padding.top;
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0F141A),
      body: SizedBox.expand(
        child: Stack(
          children: [

            // ── LAYER 0: background image ──────────────────────────────
            Positioned.fill(
  child: Image.asset(
    headerImage ?? 'assets/media/headers/default_header.jpg',
    fit: BoxFit.cover,
    alignment: Alignment.topCenter,
    errorBuilder: (_, __, ___) {
      return Image.asset(
        'assets/media/headers/default_header.jpg',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    },
  ),
),

            // ── LAYER 1: white card — FIXED to viewport ────────────────
            // Anchored by top/left/right/bottom — never participates in
            // any scroll. The rounded corners are part of this fixed
            // container, so they never move.
            Positioned(
              top:    _cardTop,
              left:   0,
              right:  0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(48),
                  ),
                ),
                // ── LAYER 1a: scrollable content inside the fixed card ──
                // Only this SingleChildScrollView moves. The card itself
                // is the fixed white rounded container above.
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Clear space for the avatar overhanging the top
                        const SizedBox(height: avatarRadius + 24),
                        // Screen-specific content
                        ...cardContent,
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── LAYER 2: avatar — fixed to viewport ────────────────────
            Positioned(
              top:  _avatarTop,
              left: screenW / 2 - avatarRadius,
              child: GestureDetector(
                onTap: onAvatarTap,
                child: Hero(
                  tag: heroTag,
                  child: Container(
                    width:  avatarRadius * 2,
                    height: avatarRadius * 2,
                    decoration: BoxDecoration(
                      shape:  BoxShape.circle,
                      color:  Colors.white,
                      border: Border.all(
                          color: Colors.white, width: 5),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withOpacity(0.18),
                          blurRadius: 16,
                          offset:     const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                        child: _resolveImage(avatarPath)),
                  ),
                ),
              ),
            ),

            // ── LAYER 3: back button — fixed to viewport (optional) ─────
            if (showBackButton)
              Positioned(
                top:  topPad + 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size:  22,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

          ],
        ),
      ),
    );
  }

  Widget _resolveImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.person,
            color: Colors.grey, size: 72),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.person,
              color: Colors.grey, size: 72),
        ),
      );
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }
}
