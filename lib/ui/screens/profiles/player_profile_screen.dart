import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' as drift;

import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/character_state.dart';

class ProfileScreen extends ConsumerWidget {
  final String? characterId;
  const ProfileScreen({super.key, this.characterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = characterId ?? 'player';
    final isOwnProfile = id == 'player';
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
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final db = ref.read(databaseProvider);
            await db.into(db.characters).insertOnConflictUpdate(
              CharactersCompanion.insert(
                id: id,
                name: 'New Investigator', // should be replaced by game-start name
                avatarPath: const drift.Value('assets/characters/player_default.png'),
              ),
            );
            ref.invalidate(characterProvider(id));
          });
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Color(0xFFC62828))),
          );
        }

        return _PlayerProfileBody(
          profile: profile,
          isOwnProfile: isOwnProfile,
          onAddGalleryPhoto: isOwnProfile ? () => _pickAndAddGalleryPhoto(ref, id) : null,
          onChangeAvatar: isOwnProfile ? () => _pickAndUpdateAvatar(context, ref, id) : null,
          onAddNote: isOwnProfile ? () => _showAddNoteSheet(context, ref, id) : null,
        );
      },
    );
  }

  Future<void> _pickAndAddGalleryPhoto(WidgetRef ref, String id) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final db = ref.read(databaseProvider);
    await db.into(db.characterPhotos).insert(
      CharacterPhotosCompanion.insert(
        characterId: id,
        photoPath: picked.path,
        caption: const drift.Value('Added from device'),
      ),
    );
    ref.invalidate(characterProvider(id));
  }

  Future<void> _pickAndUpdateAvatar(BuildContext context, WidgetRef ref, String id) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final db = ref.read(databaseProvider);
      await (db.update(db.characters)..where((c) => c.id.equals(id))).write(
        CharactersCompanion(avatarPath: drift.Value(picked.path)),
      );
      ref.invalidate(characterProvider(id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update avatar: $e')),
      );
    }
  }

  void _showAddNoteSheet(BuildContext context, WidgetRef ref, String characterId) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Note', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              maxLines: 6,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'Your observations, clues, thoughts...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isEmpty) {
                    Navigator.pop(context);
                    return;
                  }
                  final db = ref.read(databaseProvider);
                  await db.into(db.characterNotes).insert(
                    CharacterNotesCompanion.insert(
                      characterId: characterId,
                      noteText: text,
                      createdAt: drift.Value(DateTime.now()),
                    ),
                  );
                  ref.invalidate(characterProvider(characterId));
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _PlayerProfileBody extends StatelessWidget {
  final dynamic profile;
  final bool isOwnProfile;
  final VoidCallback? onAddGalleryPhoto;
  final VoidCallback? onChangeAvatar;
  final VoidCallback? onAddNote;

  const _PlayerProfileBody({
    required this.profile,
    required this.isOwnProfile,
    this.onAddGalleryPhoto,
    this.onChangeAvatar,
    this.onAddNote,
  });

  static const double headerHeight = 340.0;
  static const double avatarRadius = 78.0;
  static const double curveRadius  = 64.0;
  static const double avatarCenterY = headerHeight - curveRadius / 2;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;

    final notesRaw = (profile.notes as List?)?.cast<Map<String, dynamic>>() ?? [];
    final noteTexts = notesRaw
        .map((n) => n['noteText'] as String?)
        .whereType<String>()
        .where((t) => t.trim().isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: headerHeight,
                pinned: false,
                floating: false,
                backgroundColor: const Color(0xFF0F141A),
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.asset(
                    profile.headerImage as String? ?? 'assets/headers/dark-forest.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F141A)),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: Offset(0, -curveRadius),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(72)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 20,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SizedBox(height: avatarRadius + 28),

                          Text(
                            profile.name as String? ?? 'Investigator',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF111111),
                              letterSpacing: 0.2,
                            ),
                          ),

                          const SizedBox(height: 40),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _SectionBadge(text: 'Media'),
                                if (isOwnProfile && onAddGalleryPhoto != null) ...[
                                  const SizedBox(width: 14),
                                  GestureDetector(
                                    onTap: onAddGalleryPhoto,
                                    child: Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 22,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          if ((profile.gallery as List?)?.isEmpty ?? true)
                            const _EmptyMedia()
                          else
                            _PhotoGrid(gallery: profile.gallery as List),

                          const SizedBox(height: 56),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _SectionBadge(text: 'Notes'),
                                if (isOwnProfile && onAddNote != null) ...[
                                  const SizedBox(width: 14),
                                  GestureDetector(
                                    onTap: onAddNote,
                                    child: Icon(
                                      Icons.edit_outlined, // ← feather-like edit icon
                                      size: 22,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          if (noteTexts.isEmpty)
                            const _EmptyNotes()
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: noteTexts.map((text) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: Text(
                                    text,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      height: 1.58,
                                      color: Color(0xFF2C2C2C),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Fixed avatar – tappable on own profile
          Positioned(
            top: avatarCenterY - avatarRadius,
            left: screenWidth / 2 - avatarRadius,
            child: GestureDetector(
              onTap: onChangeAvatar,
              child: Container(
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _resolveImage(profile.avatar as String?),
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
        color: Colors.grey.shade300,
        child: const Icon(Icons.person, color: Colors.grey, size: 72),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }
}

// ── Reusable small widgets ────────────────────────────────────────────────────

class _SectionBadge extends StatelessWidget {
  final String text;
  const _SectionBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFC62828),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
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
        childAspectRatio: 0.82,
      ),
      itemCount: gallery.length,
      itemBuilder: (context, i) {
        final path = gallery[i].photoPath as String;
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: Colors.grey.shade200,
            child: path.startsWith('assets/')
                ? Image.asset(path, fit: BoxFit.cover)
                : Image.file(File(path), fit: BoxFit.cover),
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
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Text(
        'NO MEDIA ADDED',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Text(
        'NO NOTES RECORDED',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
