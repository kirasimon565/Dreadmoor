import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/state/game_state.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  Future<void> _updateProfilePic(WidgetRef ref) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      final db = ref.read(databaseProvider);
      await db.update(db.players).write(
        PlayersCompanion(profilePath: Value(result.path)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the first player entry
    final db = ref.watch(databaseProvider);
    final playerStream = db.select(db.players).watchSingleOrNull();

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Column(
        children: [
          CustomScreenHeader(title: "AGENT PROFILE", onBackPressed: () => context.pop()),
          Expanded(
            child: StreamBuilder<Player?>(
              stream: playerStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final player = snapshot.data;

                return Column(
                  children: [
                    const SizedBox(height: 40),
                    GestureDetector(
                      onTap: () => _updateProfilePic(ref),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: DreadmoorColors.accentCyan, width: 2),
                          image: player?.profilePath != null
                              ? DecorationImage(
                                  image: FileImage(File(player!.profilePath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: player?.profilePath == null
                            ? const Icon(Icons.person, size: 60, color: Colors.white54)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      player?.name ?? "UNKNOWN",
                      style: GoogleFonts.michroma(
                        fontSize: 20,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      "Level 1 Investigator",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: DreadmoorColors.textMeta,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
