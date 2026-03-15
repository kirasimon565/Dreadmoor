import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' as drift;

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
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC62828)),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("Error: $e")),
      ),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text("Profile not found")),
          );
        }

        return _PlayerProfileBody(
          profile: profile,
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
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final db = ref.read(databaseProvider);

    await db.into(db.characterPhotos).insert(
      CharacterPhotosCompanion.insert(
        characterId: id,
        photoPath: picked.path,
        caption: const drift.Value("Uploaded"),
      ),
    );

    ref.invalidate(characterProvider(id));
  }
}

class _PlayerProfileBody extends ConsumerWidget {
  final dynamic profile;
  final bool isOwnProfile;
  final VoidCallback? onAddPhoto;

  const _PlayerProfileBody({
    required this.profile,
    required this.isOwnProfile,
    this.onAddPhoto,
  });

  static const double headerHeight = 320;
  static const double avatarRadius = 80;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;
    final notes = (profile.notes as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [

          /// SCROLL AREA
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              /// HEADER
              SliverAppBar(
                expandedHeight: headerHeight,
                pinned: true,
                backgroundColor: const Color(0xFF1A2535),
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.asset(
                    profile.headerImage ??
                        "assets/media/headers/default_header.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              /// CARD
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: avatarRadius),
                  padding: const EdgeInsets.fromLTRB(
                      24,
                      avatarRadius + 16,
                      24,
                      80),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(64),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// PLAYER NAME
                      Center(
                        child: Text(
                          profile.name ?? "Player",
                          style: const TextStyle(
                            fontSize: 32,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      /// MEDIA
                      Row(
                        children: [
                          const _SectionBadge(text: "Media"),
                          if (isOwnProfile && onAddPhoto != null) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: onAddPhoto,
                              child: Icon(
                                Icons.add_a_photo_outlined,
                                size: 20,
                                color: Colors.grey.shade600,
                              ),
                            )
                          ]
                        ],
                      ),

                      const SizedBox(height: 24),

                      if ((profile.gallery as List?)?.isEmpty ?? true)
                        const _EmptyMedia()
                      else
                        _PhotoGrid(gallery: profile.gallery),

                      const SizedBox(height: 40),

                      /// NOTES
                      Row(
                        children: [
                          const _SectionBadge(text: "Notes"),
                          const SizedBox(width: 12),

                          /// FEATHER ICON
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                barrierColor: Colors.black54,
                                builder: (_) => _NotebookDialog(
                                  existingNotes: notes,
                                  characterId: "player",
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      if (notes.isEmpty)
                        Container(
                          height: 80,
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: const Text(
                            "NO NOTES RECORDED",
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: notes.map((n) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              n,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),
                          )).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          /// BACK BUTTON
          Positioned(
            top: topPad + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          /// AVATAR
          Positioned(
            top: headerHeight - avatarRadius,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: isOwnProfile ? onAddPhoto : null,
                child: Container(
                  width: avatarRadius * 2,
                  height: avatarRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: ClipOval(
                    child: _resolveImage(profile.avatar),
                  ),
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
        child: const Icon(Icons.person, size: 60),
      );
    }

    if (path.startsWith("assets/")) {
      return Image.asset(path, fit: BoxFit.cover);
    }

    return Image.file(File(path), fit: BoxFit.cover);
  }
}

class _NotebookDialog extends ConsumerStatefulWidget {
  final List<String> existingNotes;
  final String characterId;

  const _NotebookDialog({
    required this.existingNotes,
    required this.characterId,
  });

  @override
  ConsumerState<_NotebookDialog> createState() => _NotebookDialogState();
}

class _NotebookDialogState extends ConsumerState<_NotebookDialog> {

  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.existingNotes.join("\n\n"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/ui/notebook_paper.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [

            const Text(
              "Investigation Notes",
              style: TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                final db = ref.read(databaseProvider);

                await db.update(db.characters)
                  ..where((tbl) => tbl.id.equals(widget.characterId))
                  ..write(
                    CharactersCompanion(
                      bio: drift.Value(controller.text),
                    ),
                  );

                Navigator.pop(context);
              },
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}

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
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List gallery;
  const _PhotoGrid({required this.gallery});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: .8,
      ),
      itemCount: gallery.length,
      itemBuilder: (context, i) {
        final path = gallery[i].photoPath as String;

        return Container(
          color: Colors.grey.shade200,
          child: path.startsWith("assets/")
              ? Image.asset(path, fit: BoxFit.cover)
              : Image.file(File(path), fit: BoxFit.cover),
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
      height: 100,
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: const Text(
        "NO MEDIA RECOVERED",
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}
