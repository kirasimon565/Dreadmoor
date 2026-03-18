import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/character_state.dart';
import 'package:dreadmoor/ui/widgets/media_viewer.dart';
import 'profile_layout.dart';

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
        body: Center(child: CircularProgressIndicator(
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

        final gallery = (profile.gallery as List?) ?? [];
        final screenW = MediaQuery.of(context).size.width;
        int cols = 2;
        if (screenW >= 1024) cols = 4;
        else if (screenW >= 600) cols = 3;

        return ProfileLayout(
          avatarPath:     profile.avatar    as String?,
          headerImage:    profile.headerImage as String?,
          heroTag:        'profile_pic_${profile.id}',
          showBackButton: true,
          cardContent: [

            // Name
            Center(
              child: Text(
                (profile.name as String?) ?? '',
                style: const TextStyle(
                  fontSize:      34,
                  fontWeight:    FontWeight.w400,
                  color:         Color(0xFF222222),
                  letterSpacing: 0.4,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Media section
            const ProfileBadge(text: 'Media'),
            const SizedBox(height: 24),

            if (gallery.isEmpty)
              const ProfileEmptySlot(text: 'NO MEDIA RECOVERED')
            else
              ProfilePhotoGrid(gallery: gallery, cols: cols),

            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}

// ── REUSABLE CARD WIDGETS (also used by player profile) ──────────────────────

class ProfileBadge extends StatelessWidget {
  final String text;
  const ProfileBadge({super.key, required this.text});

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
          color:         Colors.white,
          fontWeight:    FontWeight.bold,
          fontSize:      15,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class ProfileEmptySlot extends StatelessWidget {
  final String text;
  const ProfileEmptySlot({super.key, required this.text});

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
          fontSize:      12,
          color:         Colors.grey,
          letterSpacing: 1.5,
          fontWeight:    FontWeight.w600,
        ),
      ),
    );
  }
}

class ProfilePhotoGrid extends StatelessWidget {
  final List<dynamic> gallery;
  final int           cols;

  const ProfilePhotoGrid({
    super.key,
    required this.gallery,
    required this.cols,
  });

  @override
  Widget build(BuildContext context) {
    final items =
        gallery.map<GalleryMediaItem>((p) => GalleryMediaItem.fromPhoto(p)).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics:    const NeverScrollableScrollPhysics(),
      padding:    EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   cols,
        mainAxisSpacing:  12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: gallery.length,
      itemBuilder: (context, i) {
        final path    = (gallery[i] as dynamic).filePath as String? ?? (gallery[i] as dynamic).photoPath as String;
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
                      ? Image.asset(path, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey.shade200))
                      : Image.file(File(path), fit: BoxFit.cover),
                ),
                if (isVideo)
                  Positioned(
                    bottom: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:        Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 16),
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
