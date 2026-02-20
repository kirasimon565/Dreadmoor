import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/investigation_state.dart';

class DiaryViewerScreen extends ConsumerWidget {
  const DiaryViewerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evidenceAsync = ref.watch(unlockedEvidenceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('REBECCA\'S DIARY', style: TextStyle(fontFamily: 'Cinzel')),
        backgroundColor: Colors.grey[900],
      ),
      backgroundColor: Colors.black,
      body: evidenceAsync.when(
        data: (evidence) {
          final diaryEntries = evidence.where((e) => e.type == 'diary').toList();
          if (diaryEntries.isEmpty) {
            return const Center(child: Text('No diary fragments recovered.', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: diaryEntries.length,
            itemBuilder: (context, index) {
              final entry = diaryEntries[index];
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: TextStyle(color: Colors.purple[200], fontSize: 18, fontFamily: 'Cinzel'),
                      ),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 10),
                      Text(
                        entry.content,
                        style: const TextStyle(color: Colors.white70, height: 1.6, fontFamily: 'Merriweather'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
