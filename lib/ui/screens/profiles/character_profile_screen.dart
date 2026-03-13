import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/state/character_state.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';

class CharacterProfileScreen extends ConsumerWidget {
  final String? characterId;
  final String? threadId;

  const CharacterProfileScreen({super.key, this.characterId, this.threadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve the correct character ID to watch
    final effectiveId = characterId ?? threadId ?? 'unknown';
    final profileAsync = ref.watch(characterProvider(effectiveId));

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: DreadmoorColors.accentCyan)),
      ),
      error: (err, stack) => Scaffold(body: Center(child: Text('Load Error: $err'))),
      data: (profile) {
        if (profile == null) return const Scaffold(body: Center(child: Text('Profile not found.')));

        return Scaffold(
          // Uses the Newspaper Yellow or Slate Blue based on theme
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // 1. HERO HEADER IMAGE (The Landscape/Cinematic)
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    backgroundColor: Colors.black,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Image.asset(
                        profile.headerImage ?? 'assets/headers/default_case.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // 2. THE OVERLAPPING CONTENT CARD
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -40),
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
                            const SizedBox(height: 70), // Space for floating avatar

                            // SUBJECT NAME
                            Text(
                              profile.name.toUpperCase(),
                              style: DreadmoorTheme.headingStyle.copyWith(
                                fontSize: 26,
                                letterSpacing: 2.0,
                              ),
                            ),
                            
                            // PHONE NUMBER / ID
                            const SizedBox(height: 4),
                            Text(
                              profile.phoneNumber ?? "ID: HIDDEN",
                              style: DreadmoorTheme.bodyStyle.copyWith(
                                fontSize: 13,
                                color: DreadmoorColors.accentCyan,
                                letterSpacing: 1.5,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // MEDIA & EVIDENCE SECTION
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Red Tag from Screenshot
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    color: const Color(0xFFB71C1C), 
                                    child: const Text(
                                      "Media",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),

                                  // EVIDENCE GRID (Populated by Drift DB)
                                  if (profile.gallery.isEmpty)
                                    _buildEmptyState("NO EVIDENCE RECOVERED")
                                  else
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 0.85,
                                      ),
                                      itemCount: profile.gallery.length,
                                      itemBuilder: (context, index) {
                                        final item = profile.gallery[index];
                                        return _buildMediaItem(item);
                                      },
                                    ),

                                  const SizedBox(height: 40),

                                  // INVESTIGATION NOTES (From Character DB)
                                  Text(
                                    "INVESTIGATION NOTES",
                                    style: DreadmoorTheme.bodyStyle.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      color: DreadmoorColors.textSecondary,
                                    ),
                                  ),
                                  const Divider(height: 24, thickness: 1),
                                  
                                  Text(
                                    profile.notes.isNotEmpty 
                                        ? profile.notes.join('\n\n') 
                                        : "No internal notes have been recorded for this subject yet.",
                                    style: DreadmoorTheme.bodyStyle.copyWith(
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 100), // Bottom padding for scroll
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

              // 3. FLOATING CIRCULAR AVATAR (Anchored between header and card)
              Positioned(
                top: 210, 
                left: MediaQuery.of(context).size.width / 2 - 65,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: DreadmoorColors.surfaceAlt,
                    backgroundImage: _resolveImage(profile.avatar),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- HELPERS ---

  ImageProvider _resolveImage(String? path) {
    if (path == null) return const AssetImage('assets/characters/unknown.png');
    if (path.startsWith('assets/')) return AssetImage(path);
    return FileImage(File(path));
  }

  Widget _buildMediaItem(CharacterPhoto photo) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: photo.photoPath.startsWith('assets/')
            ? Image.asset(photo.photoPath, fit: BoxFit.cover)
            : Image.file(File(photo.photoPath), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          message,
          style: DreadmoorTheme.bodyStyle.copyWith(
            color: Colors.grey,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
