import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/widgets/custom_screen_header.dart';
import 'package:dreadmoor/ui/widgets/shared_screen_painters.dart';

// FIX: matches the actual DB filename in drift_database.dart
const _dbFileName   = 'dreadmoor_v8.sqlite';
const _slotPrefix   = 'dreadmoor_v8_slot';

class SaveLoadScreen extends ConsumerStatefulWidget {
  const SaveLoadScreen({super.key});

  @override
  ConsumerState<SaveLoadScreen> createState() => _SaveLoadScreenState();
}

class _SaveLoadScreenState extends ConsumerState<SaveLoadScreen> {
  bool _isLoading = false;

  // ── SAVE ──────────────────────────────────────────────────────────────────

  Future<void> _handleSave(int slot) async {
    // FIX: guard against concurrent operations
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final dbFolder   = await getApplicationDocumentsDirectory();
      final sourceFile = File(p.join(dbFolder.path, _dbFileName));
      final destFile   = File(p.join(dbFolder.path, '$_slotPrefix$slot.sqlite'));

      if (!await sourceFile.exists()) {
        _showSnack('No active save file found.');
        return;
      }

      // Stamp the timestamp BEFORE copying so it's in the slot file too
      final db = ref.read(databaseProvider);
      await db.into(db.storyState).insertOnConflictUpdate(
        StoryStateCompanion(
          key:       const Value('game_saved'),
          value:     const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await sourceFile.copy(destFile.path);
      _showSnack('Saved to Slot $slot');
    } catch (e) {
      _showSnack('Failed to save game.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── LOAD ──────────────────────────────────────────────────────────────────

  Future<void> _handleLoad(int slot) async {
    // FIX: guard against concurrent operations
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final dbFolder   = await getApplicationDocumentsDirectory();
      final sourceFile = File(p.join(dbFolder.path, '$_slotPrefix$slot.sqlite'));
      final destFile   = File(p.join(dbFolder.path, _dbFileName));

      if (!await sourceFile.exists()) {
        _showSnack('Slot $slot is empty.');
        return;
      }

      // FIX 1: close the database before overwriting the file.
      // Writing to a live SQLite file that Drift has open causes corruption.
      final db = ref.read(databaseProvider);
      await db.close();

      // FIX 2: copy the slot file over the live DB file
      await sourceFile.copy(destFile.path);

      // FIX 3: invalidate databaseProvider so Drift reopens with the new file
      ref.invalidate(databaseProvider);

      // FIX 4: reset all runtime state so providers reload from the new DB.
      // Using invalidate rather than manual .setId(null) so each notifier
      // re-runs its build() and restores from the freshly loaded database.
      ref.invalidate(globalSchedulerProvider);
      ref.invalidate(activeNodeIdProvider);
      ref.invalidate(activeThreadIdProvider);
      ref.invalidate(playerStateProvider);
      ref.invalidate(gameFlagsProvider);

      // FIX 5: validate that the restored activeNodeId exists in the new DB.
      // If the node is missing (corrupted slot), fall back to the start of
      // episode 1 so the player is never left in a frozen state.
      final restoredDb   = ref.read(databaseProvider);
      final restoredNode = await (restoredDb.select(restoredDb.storyState)
            ..where((t) => t.key.equals('active_node_id')))
          .getSingleOrNull();

      final nodeId = restoredNode?.stringValue;
      if (nodeId == null || nodeId.isEmpty) {
        // No valid node — restart from the beginning
        final scheduler = ref.read(globalSchedulerProvider);
        scheduler.processNode('s2_private_msg');
      }

      // FIX 6: navigate to root so the OS shell reinitialises cleanly.
      // No restart required.
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      _showSnack('Failed to load game: $e');
      // Even on failure, try to recover by navigating to root
      if (mounted) context.go('/');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _loadSaveTimestamp(AppDatabase db) async {
    try {
      final row = await (db.select(db.storyState)
            ..where((s) => s.key.equals('game_saved')))
          .getSingleOrNull();
      if (row == null) return null;
      final dt = row.updatedAt;
      return '${_weekday(dt.weekday)} ${dt.day} ${_month(dt.month)} ${dt.year}'
          '  —  ${dt.hour.toString().padLeft(2, '0')}'
          ':${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
  }

  String _weekday(int d) =>
      ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][d - 1];

  String _month(int m) => [
    'JAN','FEB','MAR','APR','MAY','JUN',
    'JUL','AUG','SEP','OCT','NOV','DEC',
  ][m - 1];

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final db = ref.read(databaseProvider);
    final b  = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: DreadmoorColors.background(b),
      body: Stack(
        children: [
          Positioned.fill(
              child: CustomPaint(painter: const ScanlinePainter())),

          Column(
            children: [
              CustomScreenHeader(
                title: 'SAVE / LOAD',
                onBackPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Auto-save status card
                      DossierCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width:  3,
                              height: 40,
                              color:  DreadmoorColors.investigatorCyan,
                              margin: const EdgeInsets.only(right: 16, top: 2),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AUTO-SAVE ACTIVE',
                                    style: GoogleFonts.michroma(
                                      fontSize:      11,
                                      letterSpacing: 2.5,
                                      color: DreadmoorColors.investigatorCyan,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Progress is saved automatically after every significant event.',
                                    style: GoogleFonts.sourceCodePro(
                                      fontSize: 12,
                                      height:   1.6,
                                      color: DreadmoorColors.text(b).withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.cloud_done_outlined,
                              color: DreadmoorColors.investigatorCyan
                                  .withOpacity(0.6),
                              size: 20,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Last save timestamp
                      const SectionLabel(label: 'LAST CHECKPOINT'),
                      FutureBuilder<String?>(
                        future: _loadSaveTimestamp(db),
                        builder: (context, snapshot) {
                          final timestamp = snapshot.data;
                          return DossierCard(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  color: DreadmoorColors.text(b)
                                      .withOpacity(0.4),
                                  size: 16,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    timestamp ?? 'No save data found',
                                    style: GoogleFonts.sourceCodePro(
                                      fontSize: 12,
                                      color: timestamp != null
                                          ? DreadmoorColors.text(b)
                                              .withOpacity(0.7)
                                          : DreadmoorColors.text(b)
                                              .withOpacity(0.4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Manual save slots
                      const SectionLabel(label: 'MANUAL SAVE SLOTS'),
                      for (int i = 1; i <= 3; i++) ...[
                        _SaveSlot(
                          slot:   i,
                          // FIX: pass _isLoading so buttons disable during operations
                          locked: _isLoading,
                          onSave: () => _handleSave(i),
                          onLoad: () => _handleLoad(i),
                        ),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 32),

                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: DreadmoorColors.investigatorCyan,
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
}

// ── SAVE SLOT ─────────────────────────────────────────────────────────────────

class _SaveSlot extends StatelessWidget {
  final int          slot;
  final bool         locked; // true while any operation is in progress
  final VoidCallback onSave;
  final VoidCallback onLoad;

  const _SaveSlot({
    required this.slot,
    required this.locked,
    required this.onSave,
    required this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border:        Border.all(
            color: DreadmoorColors.investigatorCyan.withOpacity(0.3)),
        color:         DreadmoorColors.surface(b),
        borderRadius:  BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.save,
              size:  18,
              color: DreadmoorColors.investigatorCyan),
          const SizedBox(width: 12),
          Text(
            'SLOT ${slot.toString().padLeft(2, '0')}',
            style: GoogleFonts.sourceCodePro(
              fontSize:      14,
              letterSpacing: 1.5,
              color:         Colors.white,
              fontWeight:    FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            // FIX: null callback disables the button while loading
            onPressed: locked ? null : onLoad,
            child: Text(
              'LOAD',
              style: GoogleFonts.michroma(
                fontSize:      10,
                color:         locked
                    ? DreadmoorColors.text(b).withOpacity(0.3)
                    : DreadmoorColors.text(b).withOpacity(0.7),
                letterSpacing: 1.0,
              ),
            ),
          ),
          TextButton(
            onPressed: locked ? null : onSave,
            child: Text(
              'SAVE',
              style: GoogleFonts.michroma(
                fontSize:      10,
                color:         locked
                    ? DreadmoorColors.investigatorCyan.withOpacity(0.3)
                    : DreadmoorColors.investigatorCyan,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
