import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' as drift;

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/state/character_state.dart';

// ── SPACING TOKENS ────────────────────────────────────────────────────────────
const _spaceXS = 8.0;
const _spaceSM = 12.0;
const _spaceMD = 20.0;
const _spaceLG = 32.0;
const _spaceXL = 48.0;

// ── LAYOUT METRICS ────────────────────────────────────────────────────────────
const _headerHeight     = 350.0;
const _avatarRadius     = 85.0;
const _cardBorderRadius = 48.0;
const _avatarTop        = _headerHeight - _avatarRadius; // 265

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
                color: Color(0xFFB71C1C))),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Error: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          // Force-seed and invalidate
          WidgetsBinding.instance
              .addPostFrameCallback((_) async {
            final db = ref.read(databaseProvider);
            await db
                .into(db.characters)
                .insertOnConflictUpdate(
              CharactersCompanion.insert(
                id:          id,
                name:        'Investigator',
                phoneNumber: '+1 (555) 000-0000',
                avatarPath:  const drift.Value(
                    'assets/characters/player_default.png'),
              ),
            );
            ref.invalidate(characterProvider(id));
          });
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFB71C1C))),
          );
        }

        return _PlayerProfileBody(
          profile:           profile,
          isOwnProfile:      isOwnProfile,
          onAddGalleryPhoto: isOwnProfile
              ? () => _pickGalleryPhoto(ref, id)
              : null,
          onChangeAvatar: isOwnProfile
              ? () => _changeAvatar(context, ref, id)
              : null,
          onAddNote: isOwnProfile
              ? () => _showAddNoteSheet(context, ref, id)
              : null,
        );
      },
    );
  }

  Future<void> _pickGalleryPhoto(WidgetRef ref, String id) async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final db = ref.read(databaseProvider);
    await db.into(db.characterPhotos).insert(
      CharacterPhotosCompanion.insert(
        characterId: id,
        photoPath:   picked.path,
        caption:     const drift.Value('Added from device'),
      ),
    );
    ref.invalidate(characterProvider(id));
  }

  Future<void> _changeAvatar(
      BuildContext context, WidgetRef ref, String id) async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final db = ref.read(databaseProvider);
    await (db.update(db.characters)
          ..where((c) => c.id.equals(id)))
        .write(CharactersCompanion(
            avatarPath: drift.Value(picked.path)));
    ref.invalidate(characterProvider(id));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated')));
    }
  }

  void _showAddNoteSheet(
      BuildContext context, WidgetRef ref, String id) {
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left:   24,
          right:  24,
          top:    32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Note',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              maxLines: 6,
              minLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Your observations, clues, thoughts...',
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                filled:    true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon:  const Icon(Icons.save, size: 18),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                ),
                onPressed: () async {
                  final text = ctrl.text.trim();
                  if (text.isEmpty) {
                    Navigator.pop(ctx);
                    return;
                  }
                  final db = ref.read(databaseProvider);
                  await db.into(db.characterNotes).insert(
                    CharacterNotesCompanion.insert(
                      characterId: id,
                      noteText:    text,
                      createdAt:
                          drift.Value(DateTime.now()),
                    ),
                  );
                  ref.invalidate(characterProvider(id));
                  Navigator.pop(ctx);
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

// ── PLAYER PROFILE BODY ────────────────────────────────────────────────────────
// Blueprint layout: same as CharacterProfileScreen + Notes section after Media.

class _PlayerProfileBody extends StatelessWidget {
  final dynamic    profile;
  final bool       isOwnProfile;
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

  @override
  Widget build(BuildContext context) {
    final topPad    = MediaQuery.of(context).padding.top;
    final screenW   = MediaQuery.of(context).size.width;
    final gallery   = (profile.gallery as List?) ?? [];
    final notesRaw  = (profile.notes  as List?) ?? [];

    // Parse notes — support both String and Map shapes
    final noteTexts = notesRaw.map((n) {
      if (n is String) return n;
      if (n is Map)    return n['noteText'] as String? ?? '';
      return '';
    }).where((t) => t.trim().isNotEmpty).toList();

    int gridColumns = 2;
    if (screenW >= 1024) gridColumns = 4;
    else if (screenW >= 600) gridColumns = 3;

    final double maxWidth = screenW > 800 ? 800.0 : screenW;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: maxWidth,
          child: Stack(
            children: [

              // ── L1: BACKGROUND ──────────────────────────────────────
              Positioned.fill(
                child: Image.asset(
                  (profile.headerImage as String?)
                      ?? 'assets/headers/default_header.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFF0F141A)),
                ),
              ),

              // ── L2: SCROLL CONTENT ───────────────────────────────────
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [

                  // Transparent spacer
                  const SliverToBoxAdapter(
                      child: SizedBox(height: _headerHeight)),

                  // White card + Media section header
                  SliverToBoxAdapter(
                    child: Container(
                      constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context)
                                  .size
                                  .height -
                              _headerHeight),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(
                                _cardBorderRadius)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: _spaceMD),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // Avatar space
                            const SizedBox(height: 85),

                            // Name — centred
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                (profile.name as String?)
                                    ?? 'Investigator',
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF111111),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),

                            const SizedBox(height: _spaceXL),

                            // Media badge row
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _MediaBadge(
                                    text: 'Media'),
                                if (isOwnProfile &&
                                    onAddGalleryPhoto !=
                                        null) ...[
                                  const SizedBox(
                                      width: _spaceSM),
                                  GestureDetector(
                                    onTap: onAddGalleryPhoto,
                                    child: Icon(
                                      Icons
                                          .add_a_photo_outlined,
                                      size: 22,
                                      color: Colors
                                          .grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: _spaceLG),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Media grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: _spaceMD),
                    sliver: gallery.isEmpty
                        ? const SliverToBoxAdapter(
                            child: _EmptySlot(
                                text: 'NO MEDIA ADDED'))
                        : SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridColumns,
                              mainAxisSpacing:  _spaceSM,
                              crossAxisSpacing: _spaceSM,
                              childAspectRatio: 0.8,
                            ),
                            delegate:
                                SliverChildBuilderDelegate(
                              (context, i) {
                                final path = gallery[i]
                                    .photoPath as String;
                                return ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(
                                          _spaceXS),
                                  child: Container(
                                    color:
                                        Colors.grey.shade200,
                                    child: path.startsWith(
                                            'assets/')
                                        ? Image.asset(path,
                                            fit: BoxFit.cover)
                                        : Image.file(
                                            File(path),
                                            fit: BoxFit.cover),
                                  ),
                                );
                              },
                              childCount: gallery.length,
                            ),
                          ),
                  ),

                  // Notes section header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          _spaceMD, _spaceXL, _spaceMD, _spaceLG),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _MediaBadge(text: 'Notes'),
                          if (isOwnProfile &&
                              onAddNote != null) ...[
                            const SizedBox(width: _spaceSM),
                            GestureDetector(
                              onTap: onAddNote,
                              child: Icon(
                                Icons.edit_outlined,
                                size: 22,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Notes list
                  noteTexts.isEmpty
                      ? const SliverPadding(
                          padding: EdgeInsets.symmetric(
                              horizontal: _spaceMD),
                          sliver: SliverToBoxAdapter(
                            child: _EmptySlot(
                                text: 'NO NOTES RECORDED'),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: _spaceMD),
                          sliver: SliverList(
                            delegate:
                                SliverChildBuilderDelegate(
                              (context, i) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 18),
                                child: Text(
                                  noteTexts[i],
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    height: 1.58,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                              ),
                              childCount: noteTexts.length,
                            ),
                          ),
                        ),

                  const SliverToBoxAdapter(
                      child: SizedBox(height: 100)),
                ],
              ),

              // ── L3: AVATAR ───────────────────────────────────────────
              Positioned(
                top:  _avatarTop,
                left: maxWidth / 2 - _avatarRadius,
                child: GestureDetector(
                  onTap: onChangeAvatar,
                  child: Hero(
                    tag: 'profile_pic_player',
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
                            color: Colors.black
                                .withOpacity(0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
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
              ),

              // ── L3: BACK BUTTON (only when not own profile) ──────────
              if (characterId != null)
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

  String? get characterId => null;

  Widget _resolveImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.person,
            color: Colors.grey, size: 72),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.person,
                    color: Colors.grey, size: 72),
              ));
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }
}

// ── SHARED SMALL WIDGETS ──────────────────────────────────────────────────────

// MediaBadge — from blueprint component definition
// color: #B71C1C, borderRadius: 2
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

class _EmptySlot extends StatelessWidget {
  final String text;
  const _EmptySlot({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Colors.grey.shade50,
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
