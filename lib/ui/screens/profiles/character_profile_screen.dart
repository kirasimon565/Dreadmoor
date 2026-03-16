import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/character_state.dart';
import 'package:dreadmoor/ui/widgets/media_viewer.dart';

// ── SPACING TOKENS (from blueprint) ──────────────────────────────────────────
const _spaceXS = 8.0;
const _spaceSM = 12.0;
const _spaceMD = 20.0;
const _spaceLG = 32.0;
const _spaceXL = 48.0;

// ── LAYOUT METRICS (from blueprint) ──────────────────────────────────────────
const _headerHeight      = 350.0;
const _avatarRadius      = 85.0;
const _cardBorderRadius  = 48.0;
// avatarTop = headerHeight - avatarRadius = 265
const _avatarTop         = _headerHeight - _avatarRadius;

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
    final id           = characterId ?? threadId ?? 'unknown';
    final profileAsync = ref.watch(characterProvider(id));

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: CircularProgressIndicator(
                color: Color(0xFFB71C1C))),
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
//
// Z-INDEX ORDER (from blueprint):
//   0 — Background image        (Positioned.fill)
//   1 — CustomScrollView        (scrollable content)
//   2 — Avatar overlay          (Positioned at _avatarTop)
//   3 — Back button             (Positioned top-left)
//
// SCROLL MODEL:
//   SliverToBoxAdapter  →  transparent spacer (headerHeight) so background shows
//   SliverToBoxAdapter  →  white card (name + Media badge)
//   SliverPadding       →  SliverGrid (media gallery)

class _ProfileBody extends StatelessWidget {
  final dynamic profile;

  const _ProfileBody({required this.profile});

  @override
  Widget build(BuildContext context) {
    final topPad    = MediaQuery.of(context).padding.top;
    final screenW   = MediaQuery.of(context).size.width;
    final gallery   = (profile.gallery as List?) ?? [];

    // Responsive grid columns (from blueprint constraints)
    int gridColumns = 2;
    if (screenW >= 1024) gridColumns = 4;
    else if (screenW >= 600) gridColumns = 3;

    // LayoutWrapper: maxWidth 800, centred
    final double maxWidth = screenW > 800 ? 800 : screenW;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: maxWidth,
          child: Stack(
            children: [

              // ── L1: BACKGROUND IMAGE (Positioned.fill) ────────────────
              Positioned.fill(
                child: Image.asset(
                  (profile.headerImage as String?)
                      ?? 'assets/media/headers/default_header.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFF0F141A)),
                ),
              ),

              // ── L2: SCROLLABLE CONTENT ────────────────────────────────
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [

                  // Transparent spacer — lets background show through
                  const SliverToBoxAdapter(
                    child: SizedBox(height: _headerHeight),
                  ),

                  // White card header — name + Media badge
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(_cardBorderRadius),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: _spaceMD),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // Space for avatar overlap
                            const SizedBox(height: 85),

                            // Name — centred
                            Align(
                              alignment: Alignment.center,
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

                            const SizedBox(height: _spaceXL),

                            // Media badge — left aligned
                            const _MediaBadge(text: 'Media'),

                            const SizedBox(height: _spaceLG),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Media gallery grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: _spaceMD),
                    sliver: gallery.isEmpty
                        ? const SliverToBoxAdapter(
                            child: _EmptyMedia())
                        : SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridColumns,
                              mainAxisSpacing:  _spaceSM,
                              crossAxisSpacing: _spaceSM,
                              childAspectRatio: 0.8,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final items = gallery
                                    .map<MediaItem>((p) =>
                                        MediaItem.fromPhoto(p))
                                    .toList();
                                return _GridItem(
                                  photo:  gallery[i],
                                  items:  items,
                                  index:  i,
                                );
                              },
                              childCount: gallery.length,
                            ),
                          ),
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(
                      child: SizedBox(height: 80)),
                ],
              ),

              // ── L3: AVATAR OVERLAY (does not scroll) ─────────────────
              Positioned(
                top: _avatarTop,
                left: maxWidth / 2 - _avatarRadius,
                child: Hero(
                  tag: 'profile_pic_${profile.id}',
                  child: Container(
                    width:  _avatarRadius * 2,
                    height: _avatarRadius * 2,
                    decoration: BoxDecoration(
                      shape:  BoxShape.circle,
                      color:  Colors.white,
                      border: Border.all(
                          color: Colors.white, width: 5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _resolveImage(
                          profile.avatar as String?),
                    ),
                  ),
                ),
              ),

              // ── L3: BACK BUTTON ───────────────────────────────────────
              Positioned(
                top: topPad + 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resolveImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.person,
            color: Colors.grey, size: 70),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.person,
                    color: Colors.grey, size: 70),
              ));
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }
}

// ── GRID ITEM (from blueprint) ────────────────────────────────────────────────
//
// GestureDetector → ClipRRect → AspectRatio(0.8) → Image

class _GridItem extends StatelessWidget {
  final dynamic         photo;
  final List<MediaItem> items;
  final int             index;

  const _GridItem({
    required this.photo,
    required this.items,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final path    = photo.photoPath as String;
    final isVideo = items[index].isVideo;

    return GestureDetector(
      onTap: () => MediaViewer.open(
          context, items: items, initialIndex: index),
      onLongPress: () => _showContextMenu(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_spaceXS),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Container(
              color: Colors.grey.shade200,
              child: path.startsWith('assets/')
                  ? Image.asset(path,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey.shade200))
                  : Image.file(File(path),
                      fit: BoxFit.cover),
            ),

            // Video badge
            if (isVideo)
              Positioned(
                bottom: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius:
                        BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save_alt_outlined),
              title: const Text('Save'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ── MEDIA BADGE (from blueprint component definition) ─────────────────────────
// color: #B71C1C, borderRadius: 2, padding: (horizontal:12, vertical:8)

class _MediaBadge extends StatelessWidget {
  final String text;
  const _MediaBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: _spaceSM, vertical: _spaceXS),
      decoration: const BoxDecoration(
        color: Color(0xFFB71C1C),
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color:       Colors.white,
          fontWeight:  FontWeight.bold,
          fontSize:    15,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── EMPTY MEDIA ───────────────────────────────────────────────────────────────

class _EmptyMedia extends StatelessWidget {
  const _EmptyMedia();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Colors.grey.shade50,
      alignment: Alignment.center,
      child: const Text(
        'NO MEDIA RECOVERED',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
