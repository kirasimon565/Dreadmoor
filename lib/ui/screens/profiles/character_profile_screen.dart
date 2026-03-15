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

  const CharacterProfileScreen({super.key, this.characterId, this.threadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveId = characterId ?? threadId ?? 'unknown';
    final profileAsync = ref.watch(characterProvider(effectiveId));

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF0B1220))),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Load error: $err')),
      ),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text('Profile not found.')),
          );
        }
        return _CharacterProfileBody(profile: profile);
      },
    );
  }
}

// ── PROFILE BODY ──────────────────────────────────────────────────────────────
//
// FIX: Avatar scroll bug.
// Old structure:
//   Stack → SingleChildScrollView → Column → Positioned(avatar)
// Problem: Stack sizes to the scroll content height (not viewport).
//          Positioned(top: N) was measured from content top → scrolled.
//
// New structure:
//   Scaffold → Stack (viewport-bounded by Scaffold)
//     ├── CustomScrollView (SliverAppBar header + SliverToBoxAdapter card)
//     ├── Positioned(avatar)   ← OUTSIDE scroll, fixed at viewport top
//     └── Positioned(back btn) ← OUTSIDE scroll, fixed at viewport top
//
// The Scaffold gives Stack tight constraints = viewport size.
// Positioned children are now anchored to the viewport, never scroll.

class _CharacterProfileBody extends StatelessWidget {
  final dynamic profile;

  const _CharacterProfileBody({required this.profile});

  static const double _headerHeight  = 300.0;
  static const double _cardOverlap   = 40.0;
  static const double _avatarRadius  = 65.0;
  // Distance from top of viewport to avatar centre
  static const double _avatarTop =
      _headerHeight - _cardOverlap - _avatarRadius;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── SCROLL CONTENT ─────────────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header image — collapses as user scrolls up
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: _headerHeight,
                pinned: false,
                floating: false,
                backgroundColor: const Color(0xFF1A2535),
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.asset(
                    profile.headerImage
                        ?? 'assets/media/headers/default_header.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF1A2535)),
                  ),
                ),
              ),

              // White card
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -_cardOverlap),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft:  Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Space for floating avatar
                        const SizedBox(height: _avatarRadius + 16),

                        Center(
                          child: Text(
                            profile.name as String? ?? '',
                            style: GoogleFonts.spectral(
                              fontSize: 36,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF555555),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Red Media tag
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                color: const Color(0xFFB71C1C),
                                child: Text(
                                  'Media',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              if ((profile.gallery as List?)?.isEmpty ?? true)
                                _EmptyMedia()
                              else
                                _PhotoGrid(
                                    gallery: profile.gallery as List),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── BACK BUTTON — fixed to viewport ─────────────────────────────
          Positioned(
            top: topPad + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(
                  Icons.chevron_left, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // ── AVATAR — fixed to viewport, never scrolls ────────────────────
          Positioned(
            top: _avatarTop,
            left: MediaQuery.of(context).size.width / 2 - _avatarRadius,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: _avatarRadius,
                backgroundColor: const Color(0xFFDDDDDD),
                backgroundImage: _resolveImage(profile.avatar as String?),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _resolveImage(String? path) {
    if (path == null || path.isEmpty)
      return const AssetImage('assets/characters/unknown.png');
    if (path.startsWith('assets/')) return AssetImage(path);
    return FileImage(File(path));
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
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.88,
      ),
      itemCount: gallery.length,
      itemBuilder: (context, i) {
        final photo   = gallery[i];
        final isVideo = items[i].isVideo;

        return GestureDetector(
          onTap: () =>
              MediaViewer.open(context, items: items, initialIndex: i),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: (photo.photoPath as String).startsWith('assets/')
                    ? Image.asset(photo.photoPath as String,
                        fit: BoxFit.cover)
                    : Image.file(File(photo.photoPath as String),
                        fit: BoxFit.cover),
              ),
              if (isVideo)
                Positioned(
                  bottom: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
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

class _EmptyMedia extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          'NO MEDIA RECOVERED',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            color: Colors.grey,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
