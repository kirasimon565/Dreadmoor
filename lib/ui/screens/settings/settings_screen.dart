import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/navigation/routes.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/widgets/custom_screen_header.dart';

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
      // ✅ StoryState.value is BoolColumn — store true as the save flag.
      //    updatedAt is automatically set to now(), giving us the save time.
      await db
          .into(db.storyState)
          .insertOnConflictUpdate(
            StoryStateCompanion.insert(
              key: 'game_saved',
              value: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DreadmoorColors.surface(Theme.of(context).brightness),
            content: Text(
              'Progress saved.',
              style: GoogleFonts.spaceGrotesk(color: DreadmoorColors.text(Theme.of(context).brightness)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DreadmoorColors.surface(Theme.of(context).brightness),
            content: Text(
              'Save failed. Try again.',
              style: GoogleFonts.spaceGrotesk(color: DreadmoorColors.evidenceRed),
            ),
          ),
        );
      }
    }
  }

  // Returns a human-readable last-save time string, or null if never saved
  Future<String?> _getLastSaveTime() async {
    final db = ref.read(databaseProvider);
    try {
      final row = await (db.select(
        db.storyState,
      )..where((s) => s.key.equals('game_saved'))).getSingleOrNull();
      if (row == null || !row.value) return null;
      final dt = row.updatedAt;
      return '${dt.day}/${dt.month}/${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadGame() async {
    HapticFeedback.selectionClick();
    final db = ref.read(databaseProvider);

    try {
      // Verify a save exists
      final saveRow = await (db.select(
        db.storyState,
      )..where((s) => s.key.equals('game_saved'))).getSingleOrNull();

      if (saveRow == null || !saveRow.value) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: DreadmoorColors.surface(Theme.of(context).brightness),
              content: Text(
                'No saved game found.',
                style: GoogleFonts.spaceGrotesk(color: DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.7)),
              ),
            ),
          );
        }
        return;
      }

      // ✅ Find the most recently active thread by latest message timestamp.
      //    This is the correct way since StoryState can't store strings.
      final latestMessage =
          await (db.select(db.messages)
                ..orderBy([(m) => OrderingTerm.desc(m.timestamp)])
                ..limit(1))
              .getSingleOrNull();

      if (mounted) {
        if (latestMessage != null) {
          final threadId = latestMessage.threadId;
          ref.read(activeThreadIdProvider.notifier).state = threadId;
          context.pop();
          context.go(Routes.chat(threadId));
        } else {
          context.pop();
          context.go(Routes.messenger);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DreadmoorColors.surface(Theme.of(context).brightness),
            content: Text(
              'Load failed. Try again.',
              style: GoogleFonts.spaceGrotesk(color: DreadmoorColors.evidenceRed),
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
        backgroundColor: DreadmoorColors.surface(Theme.of(context).brightness),
        title: Text(
          "RESET PROGRESS?",
          style: GoogleFonts.michroma(color: DreadmoorColors.evidenceRed),
        ),
        content: Text(
          "This will erase all local data and restart the story. This cannot be undone.",
          style: GoogleFonts.spaceGrotesk(color: DreadmoorColors.text(Theme.of(context).brightness)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "CANCEL",
              style: GoogleFonts.spaceGrotesk(color: DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _doReset();
            },
            child: Text(
              "CONFIRM",
              style: GoogleFonts.michroma(color: DreadmoorColors.evidenceRed),
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

      // Clear in-memory state so router redirects back to setup
      ref.read(playerStateProvider.notifier).state = null;
      ref.read(activeThreadIdProvider.notifier).state = null;

      if (mounted) context.go(Routes.setup);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DreadmoorColors.surface(Theme.of(context).brightness),
            content: Text(
              'Reset failed. Try again.',
              style: GoogleFonts.spaceGrotesk(color: DreadmoorColors.evidenceRed),
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
      backgroundColor: DreadmoorColors.background(Theme.of(context).brightness),
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
                // ── THEME ──────────────────────────────────────────────
                _section("THEME"),
                _toggle(
                  "Light Mode (Archive)",
                  "Switch between Archive and Slate OS themes",
                  ref.watch(themeModeProvider) == ThemeMode.light,
                  (v) {
                    ref.read(themeModeProvider.notifier).setTheme(
                          v ? ThemeMode.light : ThemeMode.dark,
                        );
                  },
                ),

                const SizedBox(height: 32),

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
                    style: GoogleFonts.spaceGrotesk(
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
        color: DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.4),
        letterSpacing: 1.5,
      ),
    ),
  );

  Widget _toggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Padding(
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
                style: GoogleFonts.spaceGrotesk(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.spaceGrotesk(
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
          ? DreadmoorColors.investigatorCyan.withOpacity(0.2)
          : Colors.white.withOpacity(0.1),
      border: Border.all(
        color: value
            ? DreadmoorColors.investigatorCyan
            : Colors.white.withOpacity(0.2),
      ),
      boxShadow: value
          ? [BoxShadow(color: DreadmoorColors.investigatorCyan.withOpacity(0.5), blurRadius: 8)]
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
          color: value ? DreadmoorColors.investigatorCyan : Colors.white54,
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
  }) => ListTile(
    contentPadding: EdgeInsets.zero,
    onTap: onTap,
    leading: Icon(icon, color: DreadmoorColors.investigatorCyan, size: 20),
    title: Text(
      label,
      style: GoogleFonts.michroma(fontSize: 12, color: Colors.white),
    ),
    subtitle: Text(
      subtitle,
      style: GoogleFonts.spaceGrotesk(
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
          style: GoogleFonts.spaceGrotesk(
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
        color: DreadmoorColors.evidenceRed,
      ),
    ),
    subtitle: Text(
      "Erases all data and restarts the story.",
      style: GoogleFonts.spaceGrotesk(fontSize: 10, color: Colors.white54),
    ),
    trailing: Icon(
      Icons.warning_amber_rounded,
      color: DreadmoorColors.evidenceRed,
    ),
  );
}
