import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' as drift;

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/state/character_state.dart';
import 'profile_layout.dart';
import 'character_profile_screen.dart' show ProfileBadge, ProfileEmptySlot, ProfilePhotoGrid;

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
        body: Center(child: CircularProgressIndicator(
            color: Color(0xFFB71C1C))),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Error: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          // Seed from Players table and retry
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final db     = ref.read(databaseProvider);
            final player =
                await (db.select(db.players)..limit(1)).getSingleOrNull();
            final name  = (player?.name?.trim().isNotEmpty == true)
                ? player!.name : 'Investigator';
            final phone = player?.phoneNumber ?? '+1 (555) 000-0000';
            await db.into(db.characters).insertOnConflictUpdate(
              CharactersCompanion.insert(
                id:          id,
                name:        name,
                phoneNumber: phone,
                avatarPath:  const drift.Value(
                    'assets/characters/player_default.png'),
              ),
            );
            ref.invalidate(characterProvider(id));
          });
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(
                color: Color(0xFFB71C1C))),
          );
        }

        final gallery  = (profile.gallery as List?) ?? [];
        final notes    = ((profile.notes as List?) ?? [])
            .map((n) {
              if (n is String) return n;
              if (n is Map)    return (n['noteText'] as String?) ?? '';
              return '';
            })
            .where((t) => t.trim().isNotEmpty)
            .toList();

        final screenW = MediaQuery.of(context).size.width;
        int cols = 2;
        if (screenW >= 1024) cols = 4;
        else if (screenW >= 600) cols = 3;

        return ProfileLayout(
          avatarPath:     profile.avatar     as String?,
          headerImage:    profile.headerImage as String?,
          heroTag:        'profile_pic_player',
          showBackButton: true,
          // Own profile → tap avatar to change it
          onAvatarTap:    isOwnProfile
              ? () => _changeAvatar(context, ref, id)
              : null,
          cardContent: [

            // Name
            Center(
              child: Text(
                (profile.name as String?) ?? 'Investigator',
                style: const TextStyle(
                  fontSize:      34,
                  fontWeight:    FontWeight.w400,
                  color:         Color(0xFF111111),
                  letterSpacing: 0.2,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── Media ──────────────────────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ProfileBadge(text: 'Media'),
                if (isOwnProfile) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _addGalleryPhoto(ref, id),
                    child: Icon(Icons.add_a_photo_outlined,
                        size: 22, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            if (gallery.isEmpty)
              const ProfileEmptySlot(text: 'NO MEDIA ADDED')
            else
              ProfilePhotoGrid(gallery: gallery, cols: cols),

            const SizedBox(height: 48),

            // ── Notes ──────────────────────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ProfileBadge(text: 'Notes'),
                if (isOwnProfile) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _addNote(context, ref, id),
                    child: Icon(Icons.edit_outlined,
                        size: 22, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            if (notes.isEmpty)
              const ProfileEmptySlot(text: 'NO NOTES RECORDED')
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: notes
                    .map((t) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: 18),
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontSize: 15.5,
                              height:   1.58,
                              color:    Color(0xFF2C2C2C),
                            ),
                          ),
                        ))
                    .toList(),
              ),

            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────

  Future<void> _addGalleryPhoto(WidgetRef ref, String id) async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
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
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final db = ref.read(databaseProvider);
    await (db.update(db.characters)..where((c) => c.id.equals(id)))
        .write(CharactersCompanion(
            avatarPath: drift.Value(picked.path)));
    ref.invalidate(characterProvider(id));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated')));
    }
  }

  void _addNote(BuildContext context, WidgetRef ref, String id) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24, right: 24, top: 32,
        ),
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Note',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              maxLines: 6, minLines: 3,
              decoration: InputDecoration(
                hintText:  'Your observations, clues, thoughts...',
                border:    OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
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
                      createdAt:   drift.Value(DateTime.now()),
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
