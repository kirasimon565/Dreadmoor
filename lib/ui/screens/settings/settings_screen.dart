import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
          CustomScreenHeader(
            title: "SETTINGS",
            onBackPressed: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSectionHeader("GAMEPLAY"),
                _buildSwitch("Text Speed", "Adjust the typing speed of characters", _textSpeed > 0.5, (v) => setState(() => _textSpeed = v ? 1.0 : 0.5)),
                _buildSwitch("Haptic Feedback", "Vibrate on interactions", _haptics, (v) => setState(() => _haptics = v)),

                const SizedBox(height: 32),
                _buildSectionHeader("AUDIO"),
                _buildSwitch("Sound Effects", "Enable/Disable SFX", _sounds, (v) => setState(() => _sounds = v)),

                const SizedBox(height: 32),
                _buildSectionHeader("ACCOUNT"),
                _buildResetButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.michroma(fontSize: 10, color: DreadmoorColors.textMeta, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildSwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withValues(alpha: 0.54))),
              ],
            ),

            // Custom Toggle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: value ? DreadmoorColors.accentCyan.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                  color: value ? DreadmoorColors.accentCyan : Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: value ? [BoxShadow(color: DreadmoorColors.glowCyan, blurRadius: 8)] : [],
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: value ? DreadmoorColors.accentCyan : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return GestureDetector(
      onTap: () {
        // Show confirmation logic
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Reset Progress", style: GoogleFonts.michroma(fontSize: 12, color: DreadmoorColors.accentRed)),
                  const SizedBox(height: 4),
                  Text("This action cannot be undone.", style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withValues(alpha: 0.54))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: DreadmoorColors.accentRed),
          ],
        ),
      ),
    );
  }
}
