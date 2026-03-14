import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
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
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white54)),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Load error: $err')),
      ),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(body: Center(child: Text('Profile not found.')));
        }
        return _ProfileBody(profile: profile, isPlayer: false);
      },
    );
  }
}

// ── SHARED BODY ───────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final dynamic profile;   // your CharacterProfile model
  final bool isPlayer;
  final VoidCallback? onAddPhoto;

  const _ProfileBody({
    required this.profile,
    required this.isPlayer,
    this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context) {
    // How tall the background image section is
    const double headerHeight = 300.0;
    // How much the white card overlaps the image
    const double cardOverlap = 40.0;
    // Avatar radius
    const double avatarRadius = 65.0;
    // Avatar sits centred on the card's top edge
    const double avatarTop = headerHeight - cardOverlap - avatarRadius;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── SCROLLABLE CONTENT ──────────────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER IMAGE ──────────────────────────────────────────
                SizedBox(
                  height: headerHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                    profile.headerImage ?? 'assets/media/headers/default_header.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF1A2535),
                        ),
                      ),
                      // Subtle bottom fade so card edge blends
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.15),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── WHITE CARD ────────────────────────────────────────────
                Transform.translate(
                  offset: const Offset(0, -cardOverlap),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Space for avatar that floats above
                        const SizedBox(height: avatarRadius + 16),

                        // ── NAME ────────────────────────────────────────
                        Center(
                          child: Text(
                            profile.name,
                            style: GoogleFonts.spectral(
                              fontSize: 36,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF555555),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── MEDIA SECTION ──────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Red "Media" tag
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
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // ── PHOTO GRID ───────────────────────────
                              if (profile.gallery.isEmpty)
                                _EmptyMedia()
                              else
                                _PhotoGrid(gallery: profile.gallery),
                            ],
                          ),
                        ),

                        // Notes section intentionally omitted for characters
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── BACK BUTTON ─────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // ── FLOATING CIRCULAR AVATAR ─────────────────────────────────────
          Positioned(
            top: avatarTop,
            left: MediaQuery.of(context).size.width / 2 - avatarRadius,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: const Color(0xFFDDDDDD),
                backgroundImage: _resolveImage(profile.avatar),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _resolveImage(String? path) {
    if (path == null) return const AssetImage('assets/characters/unknown.png');
    if (path.startsWith('assets/')) return AssetImage(path);
    return FileImage(File(path));
  }
}

// ── PHOTO GRID ─────────────────────────────────────────────────────────────────

class _PhotoGrid extends StatelessWidget {
  final List<dynamic> gallery; // List<CharacterPhoto>

  const _PhotoGrid({required this.gallery});

  @override
  Widget build(BuildContext context) {
    // Build MediaItem list once so we can pass the full list + index to viewer
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
        final photo = gallery[i];
        final isVideo = items[i].isVideo;

        return GestureDetector(
          onTap: () => MediaViewer.open(context, items: items, initialIndex: i),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: photo.photoPath.startsWith('assets/')
                    ? Image.asset(photo.photoPath, fit: BoxFit.cover)
                    : Image.file(File(photo.photoPath), fit: BoxFit.cover),
              ),
              // Video badge
              if (isVideo)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── EMPTY MEDIA ────────────────────────────────────────────────────────────────

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
