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
    final effectiveId  = characterId ?? 'player';
    final isOwnProfile = effectiveId == 'player';
    final profileAsync = ref.watch(characterProvider(effectiveId));

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF0B1220))),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Data error: $err')),
      ),
      data: (profile) {
        if (profile == null) {
          // Force-insert player row and re-watch
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final db = ref.read(databaseProvider);
            await db.into(db.characters).insertOnConflictUpdate(
              CharactersCompanion.insert(
                id:          effectiveId,
                name:        'Investigator',
                bio:         const drift.Value('Active Case Lead'),
                avatarPath:  const drift.Value(
                    'assets/characters/player_default.png'),
                phoneNumber: '+1 (555) 000-0000',
              ),
            );
            ref.invalidate(characterProvider(effectiveId));
          });

          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF0B1220))),
          );
        }

        return _PlayerProfileBody(
          profile:      profile,
          isOwnProfile: isOwnProfile,
          onAddPhoto:   isOwnProfile
              ? () => _uploadPhoto(ref, effectiveId)
              : null,
        );
      },
    );
  }

  Future<void> _uploadPhoto(WidgetRef ref, String id) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final db = ref.read(databaseProvider);
    await db.into(db.characterPhotos).insert(
      CharacterPhotosCompanion.insert(
        characterId: id,
        photoPath:   picked.path,
        caption:     const drift.Value('Uploaded by Investigator'),
      ),
    );
    ref.invalidate(characterProvider(id));
  }
}

// ── PLAYER PROFILE BODY ────────────────────────────────────────────────────────
// Same avatar-scroll fix as CharacterProfileScreen.

class _PlayerProfileBody extends StatelessWidget {
  final dynamic profile;
  final bool isOwnProfile;
  final VoidCallback? onAddPhoto;

  const _PlayerProfileBody({
    required this.profile,
    required this.isOwnProfile,
    this.onAddPhoto,
  });

  static const double _headerHeight = 300.0;
  static const double _cardOverlap  = 40.0;
  static const double _avatarRadius = 65.0;
  static const double _avatarTop =
      _headerHeight - _cardOverlap - _avatarRadius;

  @override
  Widget build(BuildContext context) {
    final topPad     = MediaQuery.of(context).padding.top;
    final gameNumber = profile.gameNumber as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── SCROLL CONTENT ───────────────────────────────────────────────
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
                    profile.headerImage
                        ?? 'assets/headers/default_header.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF1A2535)),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -_cardOverlap),
                  child: Container(
                    width: double.infinity,
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
                        const SizedBox(height: _avatarRadius + 16),

                        // NAME
                        Center(
                          child: Text(
                            (profile.name as String?) ?? 'Investigator',
                            style: GoogleFonts.spectral(
                              fontSize: 36,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF555555),
                            ),
                          ),
                        ),

                        // GAME NUMBER
                        if (gameNumber != null && gameNumber.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              gameNumber,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Media header
                              Row(
                                children: [
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
                                  if (isOwnProfile &&
                                      onAddPhoto != null) ...[
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: onAddPhoto,
                                      child: Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 20,
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 18),

                              if ((profile.gallery as List?)?.isEmpty ??
                                  true)
                                _EmptyMedia()
                              else
                                _PhotoGrid(
                                    gallery: profile.gallery as List),

                              const SizedBox(height: 36),
                              _SectionDivider(
                                  label: 'INVESTIGATION NOTES'),
                              const SizedBox(height: 14),

                              if ((profile.notes as List?)?.isEmpty ??
                                  true)
                                _EmptyNotes()
                              else
                                _NotesList(
                                    notes: (profile.notes as List)
                                        .cast<String>()),

                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── BACK BUTTON (only when viewing another profile) ──────────────
          if (characterId != null)
            Positioned(
              top: topPad + 8,
              left: 8,
              child: IconButton(
                icon: const Icon(
                    Icons.chevron_left, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),

          // ── AVATAR — fixed to viewport ───────────────────────────────────
          Positioned(
            top: _avatarTop,
            left:
                MediaQuery.of(context).size.width / 2 - _avatarRadius,
            child: GestureDetector(
              onTap: isOwnProfile ? onAddPhoto : null,
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
          ),
        ],
      ),
    );
  }

  // Expose for back button visibility check
  String? get characterId => null;

  ImageProvider _resolveImage(String? path) {
    if (path == null || path.isEmpty)
      return const AssetImage('assets/characters/player_default.png');
    if (path.startsWith('assets/')) return AssetImage(path);
    return FileImage(File(path));
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────────────────────

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
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.88,
      ),
      itemCount: gallery.length,
      itemBuilder: (context, i) {
        final photo = gallery[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: (photo.photoPath as String).startsWith('assets/')
              ? Image.asset(photo.photoPath as String,
                  fit: BoxFit.cover)
              : Image.file(File(photo.photoPath as String),
                  fit: BoxFit.cover),
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

class _EmptyNotes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'No investigation notes recorded yet.',
      style: GoogleFonts.spectral(
        fontSize: 14,
        color: Colors.grey.shade400,
        height: 1.6,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade400,
            letterSpacing: 1.8,
          )),
      const SizedBox(width: 12),
      Expanded(
          child:
              Divider(thickness: 1, color: Colors.grey.shade200)),
    ]);
  }
}

class _NotesList extends StatelessWidget {
  final List<String> notes;
  const _NotesList({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: notes
          .map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(n,
                    style: GoogleFonts.spectral(
                      fontSize: 14,
                      height: 1.65,
                      color: const Color(0xFF444444),
                    )),
              ))
          .toList(),
    );
  }
}
