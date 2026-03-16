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
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
        ),
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

  static const double _headerHeight = 320.0;
  static const double _cardOverlap  = 56.0;
  static const double _avatarRadius = 78.0;
  static const double _avatarTop    = _headerHeight - _cardOverlap - _avatarRadius - 10;

  @override
  Widget build(BuildContext context) {
    final topPad  = MediaQuery.of(context).padding.top;
    final screenW = MediaQuery.of(context).size.width;
    final gallery = (profile.gallery as List?) ?? [];

    int cols = 2;
    if (screenW >= 1024) cols = 4;
    else if (screenW >= 600) cols = 3;

    return Scaffold(
      backgroundColor: const Color(0xFF0F141A),
      body: SizedBox.expand(
        child: Stack(
          children: [

            // Layer 0 — background image
            Positioned.fill(
              child: Image.asset(
                (profile.headerImage as String?) ??
                    'assets/media/headers/default_header.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF0F141A)),
              ),
            ),

            // Layer 1 — scrollable content (Positioned.fill constrains it
            // to viewport size so Positioned avatar/back-button siblings
            // are always anchored to the viewport, never to content height)
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(top: _avatarRadius),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // Transparent spacer
                  SizedBox(height: _headerHeight - _cardOverlap),

                  // White card — contains EVERYTHING
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(48),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Space for avatar
                          SizedBox(height: _avatarRadius + 24),

                          // Name
                          Center(
                            child: Text(
                              (profile.name as String?) ?? '',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF222222),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Media badge
                          const _MediaBadge(text: 'Media'),

                          const SizedBox(height: 24),

                          // Gallery or empty slot
                          if (gallery.isEmpty)
                            const _EmptySlot(text: 'NO MEDIA RECOVERED')
                          else
                            _PhotoGrid(gallery: gallery, cols: cols),

                          const SizedBox(height: 64),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ), // SingleChildScrollView
            ), // Positioned.fill

            // Layer 2 — avatar fixed to viewport
            Positioned(
              top:  _avatarTop,
              left: screenW / 2 - _avatarRadius,
              child: Hero(
                tag: 'profile_pic_${profile.id}',
                child: Container(
                  width:  _avatarRadius * 2,
                  height: _avatarRadius * 2,
                  decoration: BoxDecoration(
                    shape:  BoxShape.circle,
                    color:  Colors.white,
                    border: Border.all(color: Colors.white, width: 5),
                    boxShadow: [
                      BoxShadow(
                        color:      Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset:     const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _resolveImage(profile.avatar as String?),
                  ),
                ),
              ),
            ),

            // Layer 3 — back button
            Positioned(
              top:  topPad + 8,
              left: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 22,
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

// ── PHOTO GRID ────────────────────────────────────────────────────────────────

class _PhotoGrid extends StatelessWidget {
  final List<dynamic> gallery;
  final int           cols;

  const _PhotoGrid({required this.gallery, required this.cols});

  @override
  Widget build(BuildContext context) {
    final items =
        gallery.map<MediaItem>((p) => MediaItem.fromPhoto(p)).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   cols,
        mainAxisSpacing:  12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: gallery.length,
      itemBuilder: (context, i) {
        final path    = gallery[i].photoPath as String;
        final isVideo = items[i].isVideo;

        return GestureDetector(
          onTap: () =>
              MediaViewer.open(context, items: items, initialIndex: i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Colors.grey.shade200,
                  child: path.startsWith('assets/')
                      ? Image.asset(
                          path,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey.shade200),
                        )
                      : Image.file(File(path), fit: BoxFit.cover),
                ),
                if (isVideo)
                  Positioned(
                    bottom: 8,
                    right:  8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:        Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size:  16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── SHARED ────────────────────────────────────────────────────────────────────

class _MediaBadge extends StatelessWidget {
  final String text;
  const _MediaBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color:        Color(0xFFB71C1C),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color:        Colors.white,
          fontWeight:   FontWeight.bold,
          fontSize:     15,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final String text;
  const _EmptySlot({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color:        Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize:     12,
          color:        Colors.grey,
          letterSpacing: 1.5,
          fontWeight:   FontWeight.w600,
        ),
      ),
    );
  }
}
