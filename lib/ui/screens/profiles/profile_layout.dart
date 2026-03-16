import 'dart:io';
import 'package:flutter/material.dart';

/// Shared profile layout — used by both CharacterProfileScreen
/// and PlayerProfileScreen.
class ProfileLayout extends StatelessWidget {
  final String? avatarPath;
  final String? headerImage;
  final String heroTag;
  final VoidCallback? onAvatarTap;
  final List<Widget> cardContent;
  final bool showBackButton;

  static const double headerHeight = 320.0;
  static const double cardOverlap = 56.0;
  static const double avatarRadius = 78.0;

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
    final topPad = MediaQuery.of(context).padding.top;
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0F141A),
      body: SizedBox.expand(
        child: Stack(
          children: [

            /// ───── BACKGROUND ─────
            Positioned.fill(
              child: Image.asset(
                headerImage ??
                    'assets/media/headers/default_header.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF0F141A)),
              ),
            ),

            /// ───── SCROLL CONTENT ─────
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [

                          /// Transparent spacer
                          const SizedBox(
                            height:
                                headerHeight - cardOverlap,
                          ),

                          /// White card
                          Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.vertical(
                                top: Radius.circular(48),
                              ),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 24),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [

                                  /// Space for avatar overlap
                                  const SizedBox(
                                      height:
                                          avatarRadius + 24),

                                  ...cardContent,

                                  const SizedBox(
                                      height: 120),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// ───── FIXED AVATAR ─────
            Positioned(
              top: _avatarTop,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: Hero(
                    tag: heroTag,
                    child: Container(
                      width: avatarRadius * 2,
                      height: avatarRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                            color: Colors.white,
                            width: 5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child:
                            _resolveImage(avatarPath),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// ───── BACK BUTTON ─────
            if (showBackButton)
              Positioned(
                top: topPad + 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () =>
                      Navigator.pop(context),
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
