import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/state/game_state.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';

import '../../widgets/shared_screen_widgets.dart';

// FIX: Removed unused `import 'dart:ui'` present in original.
// FIX: Converted to ConsumerWidget — needs DB access to show real save timestamp.

class SaveLoadScreen extends ConsumerWidget {
  const SaveLoadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          // FIX: Original Opacity+Image.asset was NOT wrapped in Positioned.fill,
          // so it rendered at intrinsic image size in the top-left, not full-screen.
          // Replaced with a pure-Flutter scanline painter — no asset dependency.
          Positioned.fill(
            child: CustomPaint(painter: _ScanlinePainter()),
          ),

          Column(
            children: [
              CustomScreenHeader(
                title: 'SAVE / LOAD',
                onBackPressed: () => context.pop(),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Auto-save status card ──────────────────────
                      _DossierCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 3,
                              height: 40,
                              color: DreadmoorColors.accentCyan,
                              margin: const EdgeInsets.only(right: 16, top: 2),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AUTO-SAVE ACTIVE',
                                    style: GoogleFonts.michroma(
                                      fontSize: 11,
                                      letterSpacing: 2.5,
                                      color: DreadmoorColors.accentCyan,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Progress is saved automatically after every significant event.',
                                    style: GoogleFonts.sourceCodePro(
                                      fontSize: 12,
                                      height: 1.6,
                                      color: DreadmoorColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.cloud_done_outlined,
                              color: DreadmoorColors.accentCyan.withOpacity(0.6),
                              size: 20,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Last save timestamp ────────────────────────
                      _SectionLabel(label: 'LAST CHECKPOINT'),
                      FutureBuilder(
                        future: _loadSaveTimestamp(db),
                        builder: (context, snapshot) {
                          final timestamp = snapshot.data;
                          return _DossierCard(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  color: DreadmoorColors.textMeta,
                                  size: 16,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    timestamp ?? 'No save data found',
                                    style: GoogleFonts.sourceCodePro(
                                      fontSize: 12,
                                      color: timestamp != null
                                          ? DreadmoorColors.textSecondary
                                          : DreadmoorColors.textMeta,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── Manual save slots — locked ──────────────────
                      _SectionLabel(label: 'MANUAL SAVE SLOTS'),
                      for (int i = 1; i <= 3; i++) ...[
                        _LockedSlot(slot: i),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 32),

                      // ── Redacted footer ────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            _RedactedBar(width: 160),
                            const SizedBox(height: 8),
                            Text(
                              'MANUAL SAVE SLOTS DISABLED IN THIS BUILD',
                              style: GoogleFonts.michroma(
                                fontSize: 8,
                                letterSpacing: 2,
                                color: DreadmoorColors.textMeta.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String?> _loadSaveTimestamp(AppDatabase db) async {
    try {
      final rows = await (db.select(db.storyState)
            ..where((s) => s.key.equals('game_saved')))
          .getSingleOrNull();
      if (rows == null) return null;
      final dt = rows.updatedAt;
      return '${_weekday(dt.weekday)} ${dt.day} ${_month(dt.month)} ${dt.year}  —  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
  }

  String _weekday(int d) =>
      ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][d - 1];

  String _month(int m) => [
        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
      ][m - 1];
}

class _LockedSlot extends StatelessWidget {
  final int slot;
  const _LockedSlot({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        color: Colors.white.withOpacity(0.02),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 14,
            color: DreadmoorColors.textMeta.withOpacity(0.3),
          ),
          const SizedBox(width: 12),
          Text(
            'SLOT ${slot.toString().padLeft(2, '0')}',
            style: GoogleFonts.sourceCodePro(
              fontSize: 11,
              letterSpacing: 1.5,
              color: DreadmoorColors.textMeta.withOpacity(0.3),
            ),
          ),
          const Spacer(),
          Text(
            '— EMPTY —',
            style: GoogleFonts.sourceCodePro(
              fontSize: 10,
              letterSpacing: 1,
              color: DreadmoorColors.textMeta.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}
