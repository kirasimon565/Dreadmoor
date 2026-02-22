import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/routes.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _textSpeed = 1.0;
  bool _haptics = true;
  bool _sounds = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Column(
        children: [
          CustomScreenHeader(title: "SETTINGS", onBackPressed: () => context.pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _section("GAMEPLAY"),
                _toggle("Text Speed", "Adjust message speed", _textSpeed > 0.5,
                    (v) => setState(() => _textSpeed = v ? 1.0 : 0.5)),
                _toggle("Haptic Feedback", "Vibrate on interactions", _haptics,
                    (v) => setState(() => _haptics = v)),

                const SizedBox(height: 32),
                _section("AUDIO"),
                _toggle("Sound Effects", "Enable or disable SFX", _sounds,
                    (v) => setState(() => _sounds = v)),

                const SizedBox(height: 32),
                _section("CONTENT"),
                _nav("Episodes", Routes.episodes),
                _nav("Save / Load", Routes.save),
                _nav("Legal", Routes.legal),

                const SizedBox(height: 32),
                _section("ACCOUNT"),
                _resetButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(t,
            style: GoogleFonts.michroma(
                fontSize: 10,
                color: DreadmoorColors.textMeta,
                letterSpacing: 1.5)),
      );

  Widget _toggle(String t, String s, bool v, ValueChanged<bool> on) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: GestureDetector(
          onTap: () => on(!v),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: GoogleFonts.inter(fontSize: 14, color: Colors.white)),
                const SizedBox(height: 4),
                Text(s,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.54))),
              ]),
              _switch(v),
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
                  : Colors.white.withOpacity(0.2)),
          boxShadow:
              value ? [BoxShadow(color: DreadmoorColors.glowCyan, blurRadius: 8)] : [],
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
        onTap: () => context.push(route),
        title: Text(label,
            style: GoogleFonts.michroma(fontSize: 12, color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      );

  Widget _resetButton() => ListTile(
        onTap: () => _confirmReset(),
        title: Text("Reset Progress",
            style: GoogleFonts.michroma(
                fontSize: 12, color: DreadmoorColors.accentRed)),
        subtitle: Text("This cannot be undone.",
            style:
                GoogleFonts.inter(fontSize: 10, color: Colors.white54)),
        trailing: Icon(Icons.warning, color: DreadmoorColors.accentRed),
      );

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DreadmoorColors.surface,
        title: Text("RESET PROGRESS?",
            style: GoogleFonts.michroma(color: DreadmoorColors.accentRed)),
        content: Text(
          "This will erase all local data and restart the story.",
          style: GoogleFonts.inter(color: DreadmoorColors.textPrimary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL",
                  style: GoogleFonts.michroma(
                      color: DreadmoorColors.textSecondary))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: wire to scheduler.resetAll() + DB wipe
              },
              child: Text("CONFIRM",
                  style: GoogleFonts.michroma(
                      color: DreadmoorColors.accentRed))),
        ],
      ),
    );
  }
}
