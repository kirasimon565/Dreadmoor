// lib/features/minigame/tracecore/ui/panels/network_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tracecore_controller.dart';
import '../../tracecore_state.dart';
import '../../utils/clue_formatter.dart';
import '../widgets/terminal_text.dart';
import '../widgets/selectable_tile.dart';

class NetworkPanel extends ConsumerWidget {
  const NetworkPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(tracecoreProvider);
    final notifier = ref.read(tracecoreProvider.notifier);
    final clues    = state.networkClues;

    // Extract all unique IPs from network clues for the selection list
    final allIps = clues
        .expand((c) => ClueFormatter.extractIps(c.content))
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Connection logs
        Expanded(
          child: clues.isEmpty
              ? const Center(
                  child: TerminalText('> NO NETWORK DATA',
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
                          '// CONNECTION ${String.fromCharCode(65 + i)}',
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

        // IP selection
        if (allIps.isNotEmpty) ...[
          const Divider(color: Color(0xFF1A3A1A)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TerminalText('// SELECT TARGET IP',
                    fontSize: 10, color: Color(0xFF2A5A2A)),
                const SizedBox(height: 8),
                ...allIps.map((ip) => SelectableTile(
                  label:      ip,
                  isSelected: state.selectedIp == ip,
                  onTap:      () => notifier.selectIp(ip),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
