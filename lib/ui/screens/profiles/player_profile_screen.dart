import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' as drift;

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/state/character_state.dart';

class ProfileScreen extends ConsumerWidget {
  final String? characterId;
  const ProfileScreen({super.key, this.characterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id           = characterId ?? 'player';
    final isOwnProfile = id == 'player';
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
          // Force-insert and retry
          WidgetsBinding.instance
              .addPostFrameCallback((_) async {
            final db = ref.read(databaseProvider);
            await db.into(db.characters).insertOnConflictUpdate(
              CharactersCompanion.insert(
                id:          id,
                name:        'Investigator',
                bio:         const drift.Value('Active Case Lead'),
                avatarPath:  const drift.Value(
                    'assets/characters/player_default.png'),
                phoneNumber: '+1 (555) 000-0000',
              ),
            );
            ref.invalidate(characterProvider(id));
          });
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFC62828))),
          );
        }

        return _PlayerProfileBody(
          profile:      profile,
          isOwnProfile: isOwnProfile,
          onAddPhoto: isOwnProfile
              ? () => _uploadPhoto(ref, id)
              : null,
        );
      },
    );
  }

  Future<void> _uploadPhoto(WidgetRef ref, String id) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final db = ref.read(databaseProvider);
    await db.into(db.characterPhotos).insert(
      CharacterPhotosCompanion.insert(
        characterId: id,
        photoPath:   picked.path,
        caption: const drift.Value('Uploaded by Investigator'),
      ),
    );
    ref.invalidate(characterProvider(id));
  }
}

// ── PLAYER PROFILE BODY ────────────────────────────────────────────────────────
// Same design as CharacterProfileScreen + Notes section after Media.

class _PlayerProfileBody extends StatelessWidget {
  final dynamic    profile;
  final bool       isOwnProfile;
  final VoidCallback? onAddPhoto;

  const _PlayerProfileBody({
    required this.profile,
    required this.isOwnProfile,
    this.onAddPhoto,
  });

  static const double _headerHeight = 320.0;
  static const double _avatarRadius = 80.0;
  static const double _curveHeight  = 64.0;
  static const double _avatarCentreY =
      _headerHeight - _curveHeight / 2;

  String? get _characterId => null;

  @override
  Widget build(BuildContext context) {
    final topPad  = MediaQuery.of(context).padding.top;
    final screenW = MediaQuery.of(context).size.width;
    final notes   = (profile.notes as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── SCROLL ────────────────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: _headerHeight,
                pinned: false,
                floating: false,
                backgroundColor: const Color(0xFF1A2535),
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.asset(
                    (profile.headerImage as String?) ??
                        'assets/headers/default_header.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1A2535)),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -_curveHeight),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(48)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                              height: _avatarRadius + 16),

                          // Name
                          Center(
                            child: Text(
                              (profile.name as String?) ??
                                  'Investigator',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.5,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Media section header
                          Row(
                            children: [
                              _SectionBadge(text: 'Media'),
                              if (isOwnProfile &&
                                  onAddPhoto != null) ...[
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: onAddPhoto,
                                  child: Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 20,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 24),

                          if ((profile.gallery as List?)
                                  ?.isEmpty ??
                              true)
                            _EmptyMedia()
                          else
                            _PhotoGrid(
                                gallery:
                                    profile.gallery as List),

                          // ── NOTES — player only ──────────────────
                          const SizedBox(height: 40),

                          _SectionBadge(text: 'Notes'),

                          const SizedBox(height: 20),

                          if (notes.isEmpty)
                            Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100),
                              alignment: Alignment.center,
                              child: const Text(
                                'NO NOTES RECORDED',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  letterSpacing: 1.6,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: notes.map((n) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 16),
                                child: Text(
                                  n,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.6,
                                    color: Color(0xFF444444),
                                  ),
                                ),
                              )).toList(),
                            ),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── BACK BUTTON (only when viewing someone else) ───────────
          if (_characterId != null)
            Positioned(
              top: topPad + 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ),

          // ── AVATAR — fixed to viewport ─────────────────────────────
          Positioned(
            top: _avatarCentreY - _avatarRadius,
            left: screenW / 2 - _avatarRadius,
            child: GestureDetector(
              onTap: isOwnProfile ? onAddPhoto : null,
              child: Container(
                width: _avatarRadius * 2,
                height: _avatarRadius * 2,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 4)),
                ),
                child: ClipOval(
                  child: _resolveImage(
                      profile.avatar as String?),
                ),
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

// ── SHARED WIDGETS ────────────────────────────────────────────────────────────

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

class _PhotoGrid extends StatelessWidget {
  final List<dynamic> gallery;
  const _PhotoGrid({required this.gallery});

  @override
  Widget build(BuildContext context) {
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
        final path = gallery[i].photoPath as String;
        return Container(
          color: Colors.grey.shade200,
          child: path.startsWith('assets/')
              ? Image.asset(path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade200))
              : Image.file(File(path), fit: BoxFit.cover),
        );
      },
    );
  }
}

class _EmptyMedia extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.grey.shade100,
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
