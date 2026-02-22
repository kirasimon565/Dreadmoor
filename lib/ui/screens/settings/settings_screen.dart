import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/persistence/drift_database.dart';
import '../../../core/state/game_state.dart';
import '../../navigation/routes.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _textSpeed = 1.0;
  bool _haptics = true;
  bool _sounds = true;

  // ── Save / Load ──────────────────────────────────────────────────────────

  Future<void> _saveGame() async {
    HapticFeedback.selectionClick();
    final db = ref.read(databaseProvider);

    try {
      // Record a save timestamp in story_state so we know when last saved
      await db.into(db.storyState).insertOnConflictUpdate(
            StoryStateCompanion.insert(
              key: const Value('last_save'),
              value: DateTime.now().toIso8601String(),
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DreadmoorColors.surface,
            content: Text(
              'Progress saved.',
              style: GoogleFonts.inter(color: DreadmoorColors.textPrimary),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DreadmoorColors.surface,
            content: Text(
              'Save failed. Try again.',
              style: GoogleFonts.inter(color: DreadmoorColors.accentRed),
            ),
          ),
        );
      }
    }
  }

  Future<String?> _getLastSaveTime() async {
    final db = ref.read(databaseProvider);
    try {
      final row = await (db.select(db.storyState)
            ..where((s) => s.key.equals('last_save')))
          .getSingleOrNull();
      if (row == null) return null;
      final dt = DateTime.tryParse(row.value);
      if (dt == null) return null;
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadGame() async {
    HapticFeedback.selectionClick();
    final db = ref.read(databaseProvider);

    try {
      // Verify a save exists before loading
      final row = await (db.select(db.storyState)
            ..where((s) => s.key.equals('last_save')))
          .getSingleOrNull();

      if (row == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: DreadmoorColors.surface,
              content: Text(
                'No saved game found.',
                style: GoogleFonts.inter(color: DreadmoorColors.textSecondary),
              ),
            ),
          );
        }
        return;
      }

      // Load active thread from story_state and resume
      final threadRow = await (db.select(db.storyState)
            ..where((s) => s.key.equals('active_thread')))
          .getSingleOrNull();

      if (mounted) {
        if (threadRow != null && threadRow.value.isNotEmpty) {
          ref.read(activeThreadIdProvider.notifier).state = threadRow.value;
          context.pop();
          context.go(Routes.chat(threadRow.value));
        } else {
          context.pop();
          context.go(Routes.messenger);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DreadmoorColors.surface,
            content: Text(
              'Load failed. Try again.',
              style: GoogleFonts.inter(color: DreadmoorColors.accentRed),
            ),
          ),
        );
      }
    }
  }

  // ── Reset ────────────────────────────────────────────────────────────────

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DreadmoorColors.surface,
        title: Text(
          "RESET PROGRESS?",
          style: GoogleFonts.michroma(color: DreadmoorColors.accentRed),
        ),
        content: Text(
          "This will erase all local data and restart the story. This cannot be undone.",
          style: GoogleFonts.inter(color: DreadmoorColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "CANCEL",
              style: GoogleFonts.michroma(color: DreadmoorColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _doReset();
            },
            child: Text(
              "CONFIRM",
              style: GoogleFonts.michroma(color: DreadmoorColors.accentRed),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doReset() async {
    HapticFeedback.heavyImpact();
    try {
      final db = ref.read(databaseProvider);
      await db.resetAllProgress();

      // Clear in-memory player state so router redirects to setup
      ref.read(playerStateProvider.notifier).state = null;
      ref.read(activeThreadIdProvider.notifier).state = null;

      if (mounted) context.go(Routes.setup);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DreadmoorColors.surface,
            content: Text(
              'Reset failed. Try again.',
              style: GoogleFonts.inter(color: DreadmoorColors.accentRed),
            ),
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Column(
        children: [
          CustomScreenHeader(
            title: "SETTINGS",
            onBackPressed: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [

                // ── GAMEPLAY ───────────────────────────────────────────
                _section("GAMEPLAY"),
                _toggle(
                  "Text Speed",
                  "Adjust message appearance speed",
                  _textSpeed > 0.5,
                  (v) => setState(() => _textSpeed = v ? 1.0 : 0.5),
                ),
                _toggle(
                  "Haptic Feedback",
                  "Vibrate on interactions",
                  _haptics,
                  (v) => setState(() => _haptics = v),
                ),

                const SizedBox(height: 32),

                // ── AUDIO ──────────────────────────────────────────────
                _section("AUDIO"),
                _toggle(
                  "Sound Effects",
                  "Enable or disable SFX",
                  _sounds,
                  (v) => setState(() => _sounds = v),
                ),

                const SizedBox(height: 32),

                // ── SAVE / LOAD ────────────────────────────────────────
                _section("SAVE / LOAD"),
                FutureBuilder<String?>(
                  future: _getLastSaveTime(),
                  builder: (context, snapshot) {
                    final saveLabel = snapshot.data != null
                        ? "Last saved: ${snapshot.data}"
                        : "No save found";
                    return Column(
                      children: [
                        _actionTile(
                          label: "Save Game",
                          subtitle: saveLabel,
                          icon: Icons.save_outlined,
                          onTap: _saveGame,
                        ),
                        _actionTile(
                          label: "Load Game",
                          subtitle: "Resume from last save",
                          icon: Icons.download_outlined,
                          onTap: _loadGame,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // ── CONTENT ────────────────────────────────────────────
                _section("CONTENT"),
                _nav("Episodes", Routes.episodes),
                _nav("Legal", Routes.legal),

                const SizedBox(height: 32),

                // ── CREDITS ───────────────────────────────────────────
                _section("CREDITS"),
                _creditEntry("Story & Direction", "Blackmoon Studio"),
                _creditEntry("Development", "Blackmoon Studio"),
                _creditEntry("Art & Design", "Blackmoon Studio"),
                _creditEntry("Music & Sound", "Blackmoon Studio"),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "© 2025 Blackmoon Studio. All rights reserved.",
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.25),
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // ── ACCOUNT ───────────────────────────────────────────
                _section("ACCOUNT"),
                _resetButton(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable widgets ─────────────────────────────────────────────────────

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          title,
          style: GoogleFonts.michroma(
            fontSize: 10,
            color: DreadmoorColors.textMeta,
            letterSpacing: 1.5,
          ),
        ),
      );

  Widget _toggle(
          String title, String subtitle, bool value, ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(!value);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.54),
                    ),
                  ),
                ],
              ),
              _switch(value),
            ],
          ),
        ),
      );

  Widget _switch(bool value) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value
              ? DreadmoorColors.accentCyan.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: value
                ? DreadmoorColors.accentCyan
                : Colors.white.withOpacity(0.2),
          ),
          boxShadow: value
              ? [BoxShadow(color: DreadmoorColors.glowCyan, blurRadius: 8)]
              : [],
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? DreadmoorColors.accentCyan : Colors.white54,
            ),
          ),
        ),
      );

  Widget _nav(String label, String route) => ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => context.push(route),
        title: Text(
          label,
          style: GoogleFonts.michroma(fontSize: 12, color: Colors.white),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      );

  Widget _actionTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: Icon(icon, color: DreadmoorColors.accentCyan, size: 20),
        title: Text(
          label,
          style: GoogleFonts.michroma(fontSize: 12, color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white.withOpacity(0.45),
          ),
        ),
      );

  Widget _creditEntry(String role, String name) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              role,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withOpacity(0.45),
              ),
            ),
            Text(
              name,
              style: GoogleFonts.michroma(
                fontSize: 11,
                color: Colors.white.withOpacity(0.75),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      );

  Widget _resetButton() => ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: _confirmReset,
        title: Text(
          "Reset Progress",
          style: GoogleFonts.michroma(
            fontSize: 12,
            color: DreadmoorColors.accentRed,
          ),
        ),
        subtitle: Text(
          "Erases all data and restarts the story.",
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white54,
          ),
        ),
        trailing: Icon(Icons.warning_amber_rounded,
            color: DreadmoorColors.accentRed),
      );
}
