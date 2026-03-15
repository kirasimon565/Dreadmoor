import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/character_state.dart';
import 'package:dreadmoor/ui/widgets/media_viewer.dart';

class CharacterProfileScreen extends ConsumerWidget {
  final String? characterId;
  final String? threadId;

  const CharacterProfileScreen({
    super.key,
    this.characterId,
    this.threadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = characterId ?? threadId ?? 'unknown';
    final profileAsync = ref.watch(characterProvider(id));

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFC62828))),
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

class _ProfileBody extends StatelessWidget {
  final dynamic profile;

  const _ProfileBody({required this.profile});

  // Layout constants tuned to match the mockup more closely
  static const double headerHeight    = 340.0;
  static const double avatarRadius     = 78.0;
  static const double curveRadius      = 64.0;     // bigger curve = more dramatic overlap
  static const double avatarCenterY    = headerHeight - curveRadius / 2;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Scrollable content ────────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Collapsing header image
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: headerHeight,
                pinned: false,
                floating: false,
                backgroundColor: const Color(0xFF0F141A),
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.asset(
                    profile.headerImage as String? ?? 'assets/media/headers/night-sky.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F141A)),
                  ),
                ),
              ),

              // White card with big rounded top
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: Offset(0, -curveRadius),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(72)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Clear space for the overlapping avatar
                          SizedBox(height: avatarRadius + 24),

                          // Name (dark grey, centered, slightly lighter weight)
                          Text(
                            profile.name as String? ?? 'Amelia',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF222222),
                              letterSpacing: 0.4,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Red "Media" badge — compact, left-ish aligned like mockup
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _SectionBadge(text: 'Media'),
                          ),

                          const SizedBox(height: 28),

                          // Gallery grid
                          if ((profile.gallery as List?)?.isEmpty ?? true)
                            const _EmptyMedia()
                          else
                            _PhotoGrid(gallery: profile.gallery as List),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Fixed back button ─────────────────────────────────────────
          Positioned(
            top: topPad + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // ── Fixed avatar (does not scroll) ────────────────────────────
          Positioned(
            top: avatarCenterY - avatarRadius,
            left: screenWidth / 2 - avatarRadius,
            child: Container(
              width: avatarRadius * 2,
              height: avatarRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: _resolveImage(profile.avatar as String?),
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
        color: Colors.grey.shade300,
        child: const Icon(Icons.person, color: Colors.grey, size: 70),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.person, color: Colors.grey, size: 70),
        ),
      );
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }
}

// ── Red Media badge ───────────────────────────────────────────────────────────
class _SectionBadge extends StatelessWidget {
  final String text;

  const _SectionBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFC62828),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── 2-column photo grid ───────────────────────────────────────────────────────
class _PhotoGrid extends StatelessWidget {
  final List<dynamic> gallery;

  const _PhotoGrid({required this.gallery});

  @override
  Widget build(BuildContext context) {
    final items = gallery.map<MediaItem>((p) => MediaItem.fromPhoto(p)).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.82, // slightly taller than wide — matches mockup feel
      ),
      itemCount: gallery.length,
      itemBuilder: (context, i) {
        final photo = gallery[i];
        final isVideo = items[i].isVideo;
        final path = photo.photoPath as String;

        return GestureDetector(
          onTap: () => MediaViewer.open(context, items: items, initialIndex: i),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.grey.shade200,
                  child: path.startsWith('assets/')
                      ? Image.asset(path, fit: BoxFit.cover)
                      : Image.file(File(path), fit: BoxFit.cover),
                ),
              ),
              if (isVideo)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
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
  const _EmptyMedia();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Text(
        'NO MEDIA RECOVERED',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
