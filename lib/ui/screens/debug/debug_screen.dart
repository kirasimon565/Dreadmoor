import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/state/game_state.dart';
import '../../../core/scheduler/global_scheduler.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final scheduler = ref.watch(globalSchedulerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('DEV DEBUG PANEL', style: TextStyle(color: Colors.red)),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section("CORE"),
          _action(context, "NUKE DATABASE", Colors.red, () async {
            await db.batch((b) {
              b.deleteAll(db.messages);
              b.deleteAll(db.threads);
              b.deleteAll(db.players);
              b.deleteAll(db.storyState);
              b.deleteAll(db.episodes);
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💣 Database wiped')));
              context.go('/');
            }
          }),

          _section("EPISODES"),
          _action(context, "START EP01 / AMELIA CHAT", Colors.blue, () async {
            await scheduler.startThread('ep01', 'amelia_chat');
            if (context.mounted) context.go('/messenger');
          }),
          _action(context, "REPLAY CURRENT THREAD", Colors.orange, () async {
            final ep = ref.read(currentEpisodeIdProvider);
            final thread = ref.read(activeThreadIdProvider);
            if (ep != null && thread != null) {
              await scheduler.startThread(ep, thread);
              if (context.mounted) context.go('/chat/$thread');
            }
          }),

          _section("FLAGS"),
          _action(context, "UNLOCK ALL FLAGS", Colors.green, () async {
            await db.batch((b) {
              for (final flag in [
                'found_factory_phone',
                'confronted_amelia',
                'visited_factory',
                'saw_highway_crash',
                'found_diary_01',
              ]) {
                b.insert(db.storyState, StoryStateCompanion.insert(key: flag, value: const Value(true)));
              }
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚩 All flags unlocked')));
            }
          }),

          _section("TIME"),
          _action(context, "SIMULATE +7 DAYS", Colors.purple, () async {
            await db.customUpdate(
              'UPDATE story_state SET updated_at = updated_at - 7',
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⏳ Time shifted +7 days')));
            }
          }),

          _section("DB INSPECTOR"),
          _dbInspector(db),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
    );
  }

  Widget _action(BuildContext context, String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _dbInspector(AppDatabase db) {
    return FutureBuilder(
      future: Future.wait([
        db.select(db.players).get(),
        db.select(db.threads).get(),
        db.select(db.messages).get(),
        db.select(db.storyState).get(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final players = snapshot.data![0] as List<Player>;
        final threads = snapshot.data![1] as List<Thread>;
        final messages = snapshot.data![2] as List<Message>;
        final flags = snapshot.data![3] as List<StoryStateData>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dbLine("Players: ${players.length}"),
            _dbLine("Threads: ${threads.length}"),
            _dbLine("Messages: ${messages.length}"),
            _dbLine("Flags: ${flags.map((f) => f.key).join(', ')}"),
          ],
        );
      },
    );
  }

  Widget _dbLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(color: Colors.white70)),
    );
  }
}
