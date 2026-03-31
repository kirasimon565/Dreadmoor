// lib/features/minigame/tracecore/ui/tracecore_layout.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tracecore_controller.dart';
import '../tracecore_state.dart';
import '../models/tracecore_clue.dart';
import 'panels/chat_log_panel.dart';
import 'panels/network_panel.dart';
import 'panels/database_panel.dart';

class TracecoreLayout extends ConsumerWidget {
  const TracecoreLayout({super.key});

  static const _tabs = [
    (panel: CluePanel.chat,     label: 'CHAT',    icon: Icons.chat_bubble_outline),
    (panel: CluePanel.network,  label: 'NETWORK', icon: Icons.wifi_find),
    (panel: CluePanel.database, label: 'DATABASE',icon: Icons.manage_search),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(tracecoreProvider);
    final notifier = ref.read(tracecoreProvider.notifier);
    final active   = state.activePanel;

    return Column(
      children: [

        // ── TAB BAR ────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF1A3A1A), width: 1),
            ),
          ),
          child: Row(
            children: _tabs.map((t) {
              final isActive = active == t.panel;
              return Expanded(
                child: GestureDetector(
                  onTap: () => notifier.switchPanel(t.panel),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF001A00)
                          : Colors.transparent,
                      border: isActive
                          ? const Border(
                              bottom: BorderSide(
                                  color: Color(0xFF00FF41), width: 2))
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          t.icon,
                          size:  14,
                          color: isActive
                              ? const Color(0xFF00FF41)
                              : const Color(0xFF1A4A1A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t.label,
                          style: GoogleFonts.sourceCodePro(
                            fontSize:      11,
                            fontWeight:    FontWeight.w700,
                            letterSpacing: 1.2,
                            color:         isActive
                                ? const Color(0xFF00FF41)
                                : const Color(0xFF1A4A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ── ACTIVE PANEL ───────────────────────────────────────────────
        Expanded(
          child: switch (active) {
            CluePanel.chat     => const ChatLogPanel(),
            CluePanel.network  => const NetworkPanel(),
            CluePanel.database => const DatabasePanel(),
          },
        ),
      ],
    );
  }
}
