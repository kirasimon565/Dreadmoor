import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/state/game_state.dart';
import '../../theme/colors.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  Future<void> _pickPhoto(BuildContext context, WidgetRef ref, Player player) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (result == null) return;

    final db = ref.read(databaseProvider);
    await (db.update(db.players)..where((p) => p.id.equals(player.id))).write(
      PlayersCompanion(profilePath: Value(result.path)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final playerStream = (db.select(db.players)..limit(1)).watchSingleOrNull();

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: StreamBuilder<Player?>(
        stream: playerStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: DreadmoorColors.accentCyan),
            );
          }

          final player = snapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: DreadmoorColors.background,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    player.name.toUpperCase(),
                    style: GoogleFonts.michroma(
                      color: Colors.white,
                      fontSize: 14,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 10),
                      ],
                    ),
                  ),
                  centerTitle: true,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ProfileImage(player: player),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black],
                            stops: [0.6, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 70,
                        right: 20,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: DreadmoorColors.accentCyan,
                          onPressed: () => _pickPhoto(context, ref, player),
                          child: const Icon(Icons.camera_alt, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _info("IDENTITY", player.name),
                      _info("GENDER", player.gender.toUpperCase()),
                      _info("JOINED", _formatDate(player.createdAt)),

                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          color: Colors.white.withOpacity(0.02),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.lock_outline,
                                color: Colors.white.withOpacity(0.3), size: 32),
                            const SizedBox(height: 12),
                            Text(
                              "Identity records are sealed.",
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
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

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.michroma(
                fontSize: 11,
                color: DreadmoorColors.textMeta,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: DreadmoorColors.textPrimary,
              ),
            ),
          ),
          Icon(Icons.lock, size: 14, color: DreadmoorColors.textMeta.withOpacity(0.3)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }
}

class _ProfileImage extends StatelessWidget {
  final Player player;

  const _ProfileImage({required this.player});

  @override
  Widget build(BuildContext context) {
    if (player.profilePath != null && File(player.profilePath!).existsSync()) {
      return Image.file(
        File(player.profilePath!),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: Icon(
          player.gender.toLowerCase() == 'female' ? Icons.female : Icons.male,
          size: 120,
          color: Colors.white24,
        ),
      ),
    );
  }
}
