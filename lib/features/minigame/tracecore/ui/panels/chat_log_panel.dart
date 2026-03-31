// lib/features/minigame/tracecore/ui/panels/chat_log_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tracecore_controller.dart';
import '../../utils/clue_formatter.dart';
import '../widgets/terminal_text.dart';

class ChatLogPanel extends ConsumerWidget {
  const ChatLogPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clues = ref.watch(tracecoreProvider).chatClues;

    if (clues.isEmpty) {
      return const Center(
        child: TerminalText('> NO CHAT DATA RECOVERED',
            color: Color(0xFF1A4A1A)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: clues.length,
      separatorBuilder: (_, __) => const Divider(
        color: Color(0xFF0A2A0A), height: 24),
      itemBuilder: (context, i) {
        final lines = ClueFormatter.format(clues[i].content);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalText(
              '// LOG ENTRY ${String.fromCharCode(65 + i)}',
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
    );
  }
}
