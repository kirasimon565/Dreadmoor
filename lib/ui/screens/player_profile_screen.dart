import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/player_state.dart';
import '../../core/persistence/drift_database.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('PLAYER PROFILE', style: TextStyle(fontFamily: 'Cinzel', letterSpacing: 2)),
        backgroundColor: Colors.grey[900],
      ),
      body: playerAsync.when(
        data: (player) {
          if (player == null) {
            return const Center(child: Text('No player data found.', style: TextStyle(color: Colors.grey)));
          }

          return Column(
            children: [
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo update not implemented yet.')));
                },
                child: Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: player.profilePath != null ? AssetImage(player.profilePath!) : null,
                        child: player.profilePath == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildInfoRow('NAME', player.name),
              _buildInfoRow('GENDER', player.gender.toUpperCase()),
              _buildInfoRow('STATUS', 'ACTIVE INVESTIGATOR'),

              const Spacer(),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Identity locked by BlackMoon Protocol.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cinzel')),
        ],
      ),
    );
  }
}
