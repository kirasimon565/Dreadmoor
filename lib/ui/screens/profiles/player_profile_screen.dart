import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/state/game_state.dart';
import '../../theme/colors.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerStateProvider);

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
              background: _PlayerHeader(player),
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
                    player?.name ?? "Player",
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// GENDER
                  Text(
                    player?.gender ?? "",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _SectionTitle("Profile"),

                  const SizedBox(height: 12),

                  Text(
                    "This is your investigator profile. You can change your photo anytime.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _SectionTitle("Account"),

                  const SizedBox(height: 12),

                  _InfoRow("Name", player?.name ?? ""),
                  _InfoRow("Gender", player?.gender ?? ""),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerHeader extends ConsumerWidget {
  final Player? player;

  const _PlayerHeader(this.player);

  Future<void> _changeAvatar(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final db = ref.read(databaseProvider);

    await (db.update(db.players)..where((p) => p.id.equals(player!.id))).write(
      PlayersCompanion(
        profilePath: Value(image.path),
      ),
    );

    final updated = await (db.select(db.players)
          ..where((p) => p.id.equals(player!.id)))
        .getSingle();

    ref.read(playerStateProvider.notifier).state = updated;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ImageProvider avatar;

    if (player?.profilePath != null) {
      avatar = FileImage(File(player!.profilePath!));
    } else {
      avatar = const AssetImage("assets/characters/player_default.png");
    }

    return Stack(
      children: [

        /// BACKGROUND
        Positioned.fill(
          child: Image.asset(
            "assets/backgrounds/profile_bg.jpg",
            fit: BoxFit.cover,
          ),
        ),

        /// DARK OVERLAY
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),

        /// BLUR
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.transparent),
          ),
        ),

        /// AVATAR
        Positioned(
          bottom: -45,
          left: 20,
          child: GestureDetector(
            onTap: () => _changeAvatar(context, ref),
            child: Stack(
              children: [

                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.black,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundImage: avatar,
                  ),
                ),

                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
