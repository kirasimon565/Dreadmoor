import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/os/components/os_header.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  Future<void> _pickImage(BuildContext context, WidgetRef ref, Player player) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final docDir = await getApplicationDocumentsDirectory();
      final fileName = 'player_avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedImage = await pickedFile.saveTo(p.join(docDir.path, fileName));

      final db = ref.read(databaseProvider);

      // Delete old file if exists to prevent storage leak
      if (player.profilePath != null) {
        final oldFile = File(p.join(docDir.path, player.profilePath!));
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      await (db.update(db.players)..where((tbl) => tbl.id.equals(player.id)))
          .write(PlayersCompanion(profilePath: drift.Value(fileName)));

      // Update riverpod state so UI refreshes immediately
      final updatedPlayer = await (db.select(db.players)..where((tbl) => tbl.id.equals(player.id))).getSingle();
      ref.read(playerStateProvider.notifier).state = updatedPlayer;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerStateProvider);

    if (player == null) {
        return const Scaffold(
            backgroundColor: DreadmoorColors.background,
            body: Center(child: CircularProgressIndicator(color: DreadmoorColors.accentCyan)),
        );
    }

    // Resolve profile image path
    Widget avatarWidget = const Icon(Icons.person, size: 48, color: DreadmoorColors.accentCyan);
    if (player.profilePath != null) {
       // Cannot easily build sync File widget here without futurebuilder, but for UI we can just use FutureBuilder locally
    }

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const OSHeader(
              title: "MY PROFILE",
              subtitle: "INVESTIGATOR PORTAL",
            ),
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    // Profile Header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _pickImage(context, ref, player),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: DreadmoorColors.surfaceAlt,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: DreadmoorColors.accentCyan.withOpacity(0.5), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: DreadmoorColors.accentCyan.withOpacity(0.1),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: player.profilePath == null
                                      ? const Icon(Icons.person, size: 48, color: DreadmoorColors.accentCyan)
                                      : ClipOval(
                                          child: FutureBuilder<Directory>(
                                              future: getApplicationDocumentsDirectory(),
                                              builder: (context, snapshot) {
                                                  if (snapshot.hasData) {
                                                      final file = File(p.join(snapshot.data!.path, player.profilePath!));
                                                      return Image.file(file, fit: BoxFit.cover);
                                                  }
                                                  return const Icon(Icons.person, size: 48, color: DreadmoorColors.accentCyan);
                                              }
                                          )
                                      ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: DreadmoorColors.accentCyan,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: DreadmoorColors.background, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            player.name.toUpperCase(),
                            style: DreadmoorTheme.headingStyle.copyWith(
                              fontSize: 24,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            player.phoneNumber,
                            style: DreadmoorTheme.bodyStyle.copyWith(
                              fontSize: 14,
                              color: DreadmoorColors.textSecondary,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tabs
                    TabBar(
                      indicatorColor: DreadmoorColors.accentCyan,
                      labelColor: DreadmoorColors.accentCyan,
                      unselectedLabelColor: DreadmoorColors.textSecondary,
                      labelStyle: DreadmoorTheme.bodyStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      tabs: const [
                        Tab(text: "ID CARD"),
                        Tab(text: "BIO"),
                        Tab(text: "EVIDENCE"),
                      ],
                    ),

                    // Tab Content
                    const Expanded(
                      child: TabBarView(
                        children: [
                          _IdTab(),
                          _BioTab(),
                          _EvidenceTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdTab extends StatelessWidget {
  const _IdTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DreadmoorColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "DREADMOOR P.D.",
                  style: DreadmoorTheme.headingStyle.copyWith(
                    fontSize: 16,
                    color: DreadmoorColors.accentCyan,
                    letterSpacing: 2.0,
                  ),
                ),
                const Icon(Icons.local_police, color: DreadmoorColors.accentCyan),
              ],
            ),
            const Divider(color: Colors.white24, height: 32),
            _buildDetailRow("Rank", "Detective"),
            _buildDetailRow("Status", "Active"),
            _buildDetailRow("Clearance", "Level 4"),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: DreadmoorTheme.bodyStyle.copyWith(
              fontSize: 12,
              color: DreadmoorColors.textMeta,
            ),
          ),
          Text(
            value,
            style: DreadmoorTheme.bodyStyle.copyWith(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BioTab extends StatelessWidget {
  const _BioTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "PERSONAL DETAILS",
          style: DreadmoorTheme.headingStyle.copyWith(
            fontSize: 12,
            color: DreadmoorColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "You are a detective investigating the disappearance of Rebecca Stone in the town of Dreadmoor. The case has recently gone cold, until tonight.",
          style: DreadmoorTheme.bodyStyle.copyWith(
            fontSize: 14,
            color: Colors.white70,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _EvidenceTab extends StatelessWidget {
  const _EvidenceTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 48, color: DreadmoorColors.textMeta),
          const SizedBox(height: 16),
          Text(
            "NO EVIDENCE RECEIVED",
            style: DreadmoorTheme.bodyStyle.copyWith(
              color: DreadmoorColors.textMeta,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
