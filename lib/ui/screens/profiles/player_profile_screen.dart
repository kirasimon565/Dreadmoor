import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' as drift;

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/state/character_state.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';

class ProfileScreen extends ConsumerWidget {
  final String? characterId; // Null if viewing own Player profile

  const ProfileScreen({super.key, this.characterId});

  Future<void> _uploadPlayerPhoto(WidgetRef ref) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final db = ref.read(databaseProvider);
      final player = ref.read(playerStateProvider);
      if (player == null) return;

      // In a real scenario, we save to local storage and record in CharacterPhotos table
      // linked to a special 'player' ID or character ID
      await db.into(db.characterPhotos).insert(
        CharacterPhotosCompanion.insert(
          characterId: 'player', 
          photoPath: pickedFile.path,
          caption: const drift.Value('Uploaded by Investigator'),
        ),
      );
      // Refresh state
      ref.invalidate(characterProvider('player'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine which ID to fetch (the passed NPC ID or the local 'player' ID)
    final effectiveId = characterId ?? 'player';
    final profileAsync = ref.watch(characterProvider(effectiveId));

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Data Error: $err'))),
      data: (profile) {
        if (profile == null) return const Scaffold(body: Center(child: Text('File Not Found')));

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // 1. HERO HEADER IMAGE (The Landscape)
                  SliverAppBar(
                    expandedHeight: 280,
                    backgroundColor: Colors.black,
                    leading: characterId != null 
                      ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))
                      : null,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Image.asset(
                        profile.headerImage ?? 'assets/headers/default_header.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // 2. THE FLOATING CONTENT CARD
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -40), // Creates the overlap
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 70), // Space for the floating avatar

                            // NAME
                            Text(
                              profile.name,
                              style: DreadmoorTheme.headingStyle.copyWith(
                                fontSize: 28,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            
                            const SizedBox(height: 32),

                            // MEDIA SECTION
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        color: const Color(0xFFB71C1C), // Red Tag
                                        child: const Text(
                                          "Media",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      if (effectiveId == 'player')
                                        IconButton(
                                          icon: const Icon(Icons.add_a_photo, size: 20),
                                          onPressed: () => _uploadPlayerPhoto(ref),
                                        ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 20),

                                  // THE PHOTO GRID
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.85,
                                    ),
                                    itemCount: profile.gallery.length,
                                    itemBuilder: (context, index) {
                                      final photo = profile.gallery[index];
                                      return _buildGalleryItem(photo);
                                    },
                                  ),

                                  const SizedBox(height: 40),

                                  // NOTES SECTION
                                  Text(
                                    "INVESTIGATION NOTES",
                                    style: DreadmoorTheme.bodyStyle.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: DreadmoorColors.textSecondary,
                                    ),
                                  ),
                                  const Divider(height: 24),
                                  Text(
                                    profile.notes.isNotEmpty 
                                        ? profile.notes.join('\n\n') 
                                        : "No internal notes recorded for this subject.",
                                    style: DreadmoorTheme.bodyStyle.copyWith(
                                      height: 1.6,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 100),
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

              // 3. THE FLOATING CIRCULAR AVATAR
              // Positioned exactly between the header and the card
              Positioned(
                top: 210, // Adjust based on AppBar height
                left: MediaQuery.of(context).size.width / 2 - 65,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 65,
                    backgroundImage: _resolveAvatar(profile.avatar),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ImageProvider _resolveAvatar(String? path) {
    if (path == null) return const AssetImage('assets/characters/default.png');
    if (path.startsWith('assets/')) return AssetImage(path);
    return FileImage(File(path));
  }

  Widget _buildGalleryItem(CharacterPhoto photo) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: photo.photoPath.startsWith('assets/')
            ? Image.asset(photo.photoPath, fit: BoxFit.cover)
            : Image.file(File(photo.photoPath), fit: BoxFit.cover),
      ),
    );
  }
}
