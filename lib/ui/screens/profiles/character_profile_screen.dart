import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/character_state.dart';
import 'package:dreadmoor/ui/widgets/media_viewer.dart';

class CharacterProfileScreen extends ConsumerWidget {
  final String? characterId;
  final String? threadId;

  const CharacterProfileScreen(
      {super.key, this.characterId, this.threadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = characterId ?? threadId ?? 'unknown';
    final profileAsync = ref.watch(characterProvider(id));

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: CircularProgressIndicator(
                color: Color(0xFFC62828))),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Error: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text('Profile not found.')),
          );
        }
        return _ProfileBody(profile: profile);
      },
    );
  }
}

// ── PROFILE BODY ──────────────────────────────────────────────────────────────
// Exact mockup design:
//   - Full-bleed header image
//   - White rounded overlay creates the curve
//   - Circular avatar overlaps header/card seam
//   - Avatar is OUTSIDE the scroll — fixed to viewport
//   - Name centred in grey, red Media badge, 2-col grid

class _ProfileBody extends StatelessWidget {
  final dynamic profile;

  const _ProfileBody({required this.profile});

  // From mockup
  static const double _headerHeight  = 320.0;
  static const double _avatarRadius  = 80.0;
  static const double _curveHeight   = 64.0;
  // Where the avatar centre sits relative to viewport top
  static const double _avatarCentreY =
      _headerHeight - _curveHeight / 2;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── SCROLL CONTENT ──────────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header image via SliverAppBar so it collapses naturally
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: _headerHeight,
                pinned: false,
                floating: false,
                backgroundColor: const Color(0xFF1A2535),
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.asset(
                    (profile.headerImage as String?) ??
                        'assets/media/headers/default_header.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF1A2535)),
                  ),
                ),
              ),

              // White rounded card — starts with space for avatar
              SliverToBoxAdapter(
                child: Transform.translate(
                  // Pull up to overlap the header image
                  offset: const Offset(0, -_curveHeight),
                  child: Container(
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
                          // Space to clear the overlapping avatar
                          const SizedBox(
                              height: _avatarRadius + 16),

                          // Name — centred, grey, from mockup
                          Center(
                            child: Text(
                              (profile.name as String?) ?? '',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.5,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Red Media badge
                          _SectionBadge(text: 'Media'),

                          const SizedBox(height: 24),

                          // Photo grid
                          if ((profile.gallery as List?)
                                  ?.isEmpty ??
                              true)
                            _EmptyMedia()
                          else
                            _PhotoGrid(
                                gallery:
                                    profile.gallery as List),

                          const SizedBox(height: 64),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── BACK BUTTON — fixed to viewport ───────────────────────
          Positioned(
            top: topPad + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // ── AVATAR — fixed to viewport, never scrolls ──────────────
          // Centred horizontally, sits at the header/card seam
          Positioned(
            top: _avatarCentreY - _avatarRadius,
            left: screenW / 2 - _avatarRadius,
            child: Container(
              width: _avatarRadius * 2,
              height: _avatarRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                // White ring border (from mockup)
                border: Border.all(
                    color: Colors.white, width: 4),
              ),
              child: ClipOval(
                child: _resolveImage(
                    profile.avatar as String?),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resolveImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.person,
            color: Colors.grey, size: 60),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.person,
                    color: Colors.grey, size: 60),
              ));
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }
}

// ── SECTION BADGE ─────────────────────────────────────────────────────────────

class _SectionBadge extends StatelessWidget {
  final String text;
  const _SectionBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFC62828),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── PHOTO GRID ────────────────────────────────────────────────────────────────

class _PhotoGrid extends StatelessWidget {
  final List<dynamic> gallery;
  const _PhotoGrid({required this.gallery});

  @override
  Widget build(BuildContext context) {
    final items = gallery
        .map<MediaItem>((p) => MediaItem.fromPhoto(p))
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: gallery.length,
      itemBuilder: (context, i) {
        final photo   = gallery[i];
        final isVideo = items[i].isVideo;
        final path    = photo.photoPath as String;

        return GestureDetector(
          onTap: () =>
              MediaViewer.open(context, items: items, initialIndex: i),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.grey.shade200,
                child: path.startsWith('assets/')
                    ? Image.asset(path,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey.shade200))
                    : Image.file(File(path), fit: BoxFit.cover),
              ),
              if (isVideo)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── EMPTY MEDIA ───────────────────────────────────────────────────────────────

class _EmptyMedia extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
      ),
      alignment: Alignment.center,
      child: const Text(
        'NO MEDIA RECOVERED',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
