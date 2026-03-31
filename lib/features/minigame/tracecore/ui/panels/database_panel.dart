// lib/features/minigame/tracecore/ui/panels/database_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tracecore_controller.dart';
import '../../utils/clue_formatter.dart';
import '../widgets/terminal_text.dart';
import '../widgets/selectable_tile.dart';

class DatabasePanel extends ConsumerWidget {
  const DatabasePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(tracecoreProvider);
    final notifier = ref.read(tracecoreProvider.notifier);
    final clues    = state.databaseClues;

    // Extract all unique names from database clues
    final allNames = clues
        .expand((c) => ClueFormatter.extractNames(c.content))
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile entries
        Expanded(
          child: clues.isEmpty
              ? const Center(
                  child: TerminalText('> DATABASE EMPTY',
                      color: Color(0xFF1A4A1A)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  itemCount: clues.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: Color(0xFF0A2A0A), height: 24),
                  itemBuilder: (context, i) {
                    final lines = ClueFormatter.format(clues[i].content);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TerminalText(
                          '// PROFILE ${String.fromCharCode(65 + i)}',
                          fontSize: 10,
                          color: const Color(0xFF2A5A2A),
                        ),
                        const SizedBox(height: 6),
                        ...lines.map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: TerminalText(l),
                        )),
                      ],
                    );
                  },
                ),
        ),

        // Name selection
        if (allNames.isNotEmpty) ...[
          const Divider(color: Color(0xFF1A3A1A)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TerminalText('// SELECT TARGET IDENTITY',
                    fontSize: 10, color: Color(0xFF2A5A2A)),
                const SizedBox(height: 8),
                ...allNames.map((name) => SelectableTile(
                  label:      name,
                  isSelected: state.selectedName == name,
                  onTap:      () => notifier.selectName(name),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
