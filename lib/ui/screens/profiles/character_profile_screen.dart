import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/character_state.dart';
import '../../theme/colors.dart';

class CharacterProfileScreen extends ConsumerWidget {
  final String characterId;

  const CharacterProfileScreen({
    super.key,
    required this.characterId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterAsync = ref.watch(characterProvider(characterId));

    return characterAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error loading profile')),
      ),
      data: (character) {
        if (character == null) {
          return const Scaffold(
            body: Center(child: Text("Character not found")),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [

              /// HEADER
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _ProfileHeader(character),
                ),
              ),

              /// CONTENT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// NAME
                      Text(
                        character.name,
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 6),

                      /// PHONE
                      Text(
                        character.phoneNumber ?? "",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 28),

                      /// SNAPSHOTS GRID
                      if (character.photos.isNotEmpty) ...[
                        _SectionTitle("Snapshots"),
                        const SizedBox(height: 12),
                        _PhotoGrid(character.photos),
                        const SizedBox(height: 30),
                      ],

                      /// PERSONAL INFO
                      if (character.info.isNotEmpty) ...[
                        _SectionTitle("Information"),
                        const SizedBox(height: 12),
                        _InfoSection(character.info),
                        const SizedBox(height: 30),
                      ],

                      /// ABOUT
                      if (character.bio != null && character.bio!.isNotEmpty) ...[
                        _SectionTitle("About"),
                        const SizedBox(height: 10),
                        Text(
                          character.bio!,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],

                      /// INVESTIGATION NOTES
                      if (character.notes.isNotEmpty) ...[
                        _SectionTitle("Investigation Notes"),
                        const SizedBox(height: 10),
                        _NotesSection(character.notes),
                      ],
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

/// HEADER WIDGET
class _ProfileHeader extends StatelessWidget {
  final dynamic character;

  const _ProfileHeader(this.character);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        /// BACKGROUND IMAGE
        Positioned.fill(
          child: Image.asset(
            character.headerImage,
            fit: BoxFit.cover,
          ),
        ),

        /// DARK OVERLAY
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.45),
          ),
        ),

        /// BLUR
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),

        /// AVATAR
        Positioned(
          bottom: -45,
          left: 20,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.black,
            child: CircleAvatar(
              radius: 46,
              backgroundImage: AssetImage(character.avatar),
            ),
          ),
        ),
      ],
    );
  }
}

/// SECTION TITLE
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
        letterSpacing: 1.4,
        color: Colors.white54,
      ),
    );
  }
}

/// PHOTO GRID
class _PhotoGrid extends StatelessWidget {
  final List<String> photos;

  const _PhotoGrid(this.photos);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            photos[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

/// PERSONAL INFO
class _InfoSection extends StatelessWidget {
  final Map<String, String> info;

  const _InfoSection(this.info);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: info.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  entry.key,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  entry.value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// NOTES
class _NotesSection extends StatelessWidget {
  final List<String> notes;

  const _NotesSection(this.notes);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: notes.map((note) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.circle,
                size: 8,
                color: Colors.white54,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }
}
