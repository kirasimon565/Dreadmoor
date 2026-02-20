import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/persistence/drift_database.dart';
import '../../../core/state/game_state.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final scheduler = ref.watch(globalSchedulerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DEBUG', style: TextStyle(color: Colors.red)),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[900],
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAction(
            context,
            'RESET DATABASE (NUKE)',
            Colors.red,
            () async {
              // Delete everything
              await db.delete(db.messages).go();
              await db.delete(db.threads).go();
              await db.delete(db.players).go();
              await db.delete(db.storyState).go();
              await db.delete(db.episodes).go();
              if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database Nuked')));
                 context.go('/');
              }
            },
          ),
          _buildAction(
            context,
            'START EP1: AMELIA',
            Colors.blue,
            () {
              scheduler.startThread('ep01', 'amelia_chat');
              context.go('/messenger');
            },
          ),
           _buildAction(
            context,
            'UNLOCK ALL EVIDENCE',
            Colors.green,
            () {
              // TODO: Implement unlock logic
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unlock Logic not connected yet')));
            },
          ),

          const Divider(color: Colors.grey),
          const Text('DB INSPECTOR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),

          FutureBuilder<List<Player>>(
            future: db.select(db.players).get(),
            builder: (c, s) {
              if (!s.hasData) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: s.data!.map((p) => Text('Player: ${p.name} (${p.gender})', style: const TextStyle(color: Colors.white70))).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
