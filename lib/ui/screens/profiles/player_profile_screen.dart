import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/state/game_state.dart';
import '../../theme/colors.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final playerStream = (db.select(db.players)..limit(1)).watchSingleOrNull();

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: StreamBuilder<Player?>(
        stream: playerStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: DreadmoorColors.accentCyan));
          final player = snapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: DreadmoorColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    player.name.toUpperCase(),
                    style: GoogleFonts.michroma(
                      color: Colors.white,
                      fontSize: 16,
                      shadows: [const Shadow(color: Colors.black, blurRadius: 10)],
                    ),
                  ),
                  centerTitle: true,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Profile Photo
                      player.profilePath != null
                          ? Image.asset(player.profilePath!, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.grey[800]))
                          : Container(
                              color: Colors.grey[900],
                              child: Center(
                                child: Icon(
                                  player.gender.toLowerCase() == 'female' ? Icons.female : Icons.male,
                                  size: 100,
                                  color: Colors.white24,
                                ),
                              ),
                            ),

                      // Gradient Overlay
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

                      // Edit Photo Button
                      Positioned(
                        bottom: 60,
                        right: 20,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: DreadmoorColors.accentCyan,
                          onPressed: () {
                            // TODO: Pick image logic
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo picking not implemented yet')));
                          },
                          child: const Icon(Icons.camera_alt, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow("IDENTITY", player.name),
                      _buildInfoRow("GENDER", player.gender.toUpperCase()),
                      _buildInfoRow("JOINED", _formatDate(player.createdAt)),

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
                            Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.3), size: 32),
                            const SizedBox(height: 12),
                            Text(
                              "Identity records are sealed.",
                              style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5), fontSize: 12),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.michroma(fontSize: 11, color: DreadmoorColors.textMeta),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 16, color: DreadmoorColors.textPrimary),
            ),
          ),
          Icon(Icons.lock, size: 14, color: DreadmoorColors.textMeta.withOpacity(0.3)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    // Simple format
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }
}
