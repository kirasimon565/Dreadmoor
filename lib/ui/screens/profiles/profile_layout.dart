import 'dart:io';
import 'package:flutter/material.dart';

/// Shared profile layout — used by both CharacterProfileScreen
/// and PlayerProfileScreen.
///
/// Owns:
///   • Full-bleed background image
///   • Positioned.fill scroll view (keeps Stack viewport-sized)
///   • padding.top = avatarRadius trick (card slides under avatar,
///     avatar never scrolls)
///   • Fixed circular avatar (Positioned, Layer 2)
///   • Optional back button (Positioned, Layer 3)
///
/// Callers supply only their card content via [cardContent].
class ProfileLayout extends StatelessWidget {
  final String?       avatarPath;
  final String?       headerImage;
  final String        heroTag;
  final VoidCallback? onAvatarTap;
  final List<Widget>  cardContent;
  final bool          showBackButton;

  // ── Layout constants (shared by both screens) ────────────────────────
  static const double headerHeight = 320.0;
  static const double cardOverlap  = 56.0;
  static const double avatarRadius = 78.0;

  // Viewport-relative top of the avatar circle
  static const double _avatarTop =
      headerHeight - cardOverlap - avatarRadius;

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
      // SizedBox.expand gives the Stack explicit viewport-tight constraints.
      // Without this, Stack would expand to content height and the
      // Positioned avatar would scroll with the content.
      body: SizedBox.expand(
        child: Stack(
          children: [

            // ── LAYER 0: background image ────────────────────────────────
            Positioned.fill(
              child: Image.asset(
                headerImage ??
                    'assets/media/headers/default_header.jpg',
                fit:       BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF0F141A)),
              ),
            ),

            // ── LAYER 1: scroll view ─────────────────────────────────────
            // Positioned.fill → scroll view is viewport-sized, not
            // content-sized. The Stack therefore stays viewport-sized.
            //
            // padding.top = avatarRadius is the key scroll trick:
            // the scroll origin starts below the avatar, so as the user
            // scrolls down the card slides under the fixed avatar instead
            // of the avatar moving with the card.
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: avatarRadius),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // Transparent spacer — reveals background image
                    const SizedBox(
                      height: headerHeight - cardOverlap - avatarRadius,
                    ),

                    // White card — full width, rounded top
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(48),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // Clears the avatar that overhangs the card
                            const SizedBox(height: avatarRadius + 24),
                            // Content injected by each screen
                            ...cardContent,
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── LAYER 2: avatar — pinned to viewport, never scrolls ──────
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

            // ── LAYER 3: back button (optional) ─────────────────────────
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
