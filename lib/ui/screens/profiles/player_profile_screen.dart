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

class PlayerProfileScreen extends ConsumerStatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  ConsumerState<PlayerProfileScreen> createState() =>
      _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends ConsumerState<PlayerProfileScreen> {
  // ✅ Stream created once in initState — not recreated on every rebuild
  late final Stream<Player?> _playerStream;

  @override
  void initState() {
    super.initState();
    final db = ref.read(databaseProvider);
    _playerStream = (db.select(db.players)..limit(1)).watchSingleOrNull();
  }

  Future<void> _updateProfilePic(Player player) async {
    final picker = ImagePicker();
    try {
      final result =
          await picker.pickImage(source: ImageSource.gallery);
      if (result == null) return;

      final db = ref.read(databaseProvider);
      // ✅ WHERE clause scopes update to THIS player's row only
      await (db.update(db.players)..where((p) => p.id.equals(player.id)))
          .write(PlayersCompanion(profilePath: Value(result.path)));

      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('⚠️ Profile pic update failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DreadmoorColors.surface,
            content: Text(
              'Could not update photo.',
              style: GoogleFonts.inter(color: DreadmoorColors.textPrimary),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: StreamBuilder<Player?>(
        stream: _playerStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                  color: DreadmoorColors.accentCyan),
            );
          }

          final player = snapshot.data;
          if (player == null) {
            return const Center(
              child: CircularProgressIndicator(
                  color: DreadmoorColors.accentCyan),
            );
          }

          final hasPhoto = player.profilePath != null &&
              player.profilePath!.isNotEmpty;
          final genderLabel =
              player.gender.toLowerCase() == 'female' ? "FEMALE" : "MALE";

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Parallax header ───────────────────────────────────
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                stretch: true,
                backgroundColor: DreadmoorColors.background,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(
                      bottom: 16, left: 48, right: 48),
                  title: Text(
                    player.name.toUpperCase(),
                    style: GoogleFonts.michroma(
                      color: Colors.white,
                      fontSize: 13,
                      letterSpacing: 2.5,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 12),
                        Shadow(color: Colors.black, blurRadius: 24),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.fadeTitle,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Profile photo or placeholder
                      hasPhoto
                          ? Image.file(
                              File(player.profilePath!),
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (_, __, ___) =>
                                  _PhotoPlaceholder(gender: player.gender),
                            )
                          : _PhotoPlaceholder(gender: player.gender),

                      // Bottom fade
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              DreadmoorColors.background,
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),

                      // Camera button — centered at bottom of photo area
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: GestureDetector(
                          onTap: () => _updateProfilePic(player),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: DreadmoorColors.accentCyan
                                    .withOpacity(0.5),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: DreadmoorColors.accentCyan,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      // Grain overlay
                      IgnorePointer(
                        child: Opacity(
                          opacity: 0.04,
                          child: Image.asset(
                            'assets/ui/glitch_overlay.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Info panel ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Agent info rows
                      _InfoRow(label: "CODENAME", value: player.name),
                      _InfoRow(label: "IDENTITY", value: genderLabel),
                      const _InfoRow(
                          label: "CLEARANCE", value: "LEVEL 1 — INVESTIGATOR"),

                      const SizedBox(height: 24),

                      // Locked notice
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.07),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: DreadmoorColors.textMeta,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "NAME AND IDENTITY ARE PERMANENT AND CANNOT BE CHANGED.",
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: DreadmoorColors.textMeta
                                      .withOpacity(0.6),
                                  letterSpacing: 0.8,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Change photo hint
                      GestureDetector(
                        onTap: () => _updateProfilePic(player),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          decoration: BoxDecoration(
                            color: DreadmoorColors.accentCyan
                                .withOpacity(0.06),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: DreadmoorColors.accentCyan
                                  .withOpacity(0.25),
                              width: 0.6,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.camera_alt_outlined,
                                size: 16,
                                color: DreadmoorColors.accentCyan,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "CHANGE PROFILE PHOTO",
                                style: GoogleFonts.michroma(
                                  fontSize: 11,
                                  color: DreadmoorColors.accentCyan,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Photo placeholder ──────────────────────────────────────────────────────

class _PhotoPlaceholder extends StatelessWidget {
  final String gender;
  const _PhotoPlaceholder({required this.gender});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DreadmoorColors.surface,
      child: Center(
        child: Icon(
          gender.toLowerCase() == 'female'
              ? Icons.person_2_outlined
              : Icons.person_outline_rounded,
          size: 80,
          color: Colors.white.withOpacity(0.15),
        ),
      ),
    );
  }
}

// ── Shared info row ────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.michroma(
                fontSize: 10,
                color: DreadmoorColors.textMeta,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: DreadmoorColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
