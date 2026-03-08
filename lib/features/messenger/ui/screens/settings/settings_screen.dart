import 'package:flutter/material.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/os/components/os_header.dart';
import 'package:dreadmoor/ui/screens/profiles/player_profile_screen.dart';
import 'package:dreadmoor/ui/screens/save_load/save_load_screen.dart' as dreadmoor_save;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _messageAlerts = true;
  bool _hideContent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OSHeader(
              title: "SETTINGS",
              subtitle: "MESSENGER CONFIGURATION",
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios, color: DreadmoorColors.textSecondary, size: 20),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: [
                  _buildSectionTitle("ACCOUNT"),
                  _buildSettingRow(
                    icon: Icons.person,
                    title: "Profile Settings",
                    subtitle: "Manage avatar and bio",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerProfileScreen()));
                    },
                  ),
                  _buildSettingRow(
                    icon: Icons.security,
                    title: "Privacy",
                    subtitle: "Encryption and connection status",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy settings opened.')));
                    },
                  ),

                  const SizedBox(height: 32),

                  _buildSectionTitle("NOTIFICATIONS"),
                  _buildSettingRow(
                    icon: Icons.notifications,
                    title: "Message Alerts",
                    subtitle: "Sound, vibration, priority",
                    hasSwitch: true,
                    switchValue: _messageAlerts,
                    onTap: () {
                      setState(() {
                        _messageAlerts = !_messageAlerts;
                      });
                    },
                  ),
                  _buildSettingRow(
                    icon: Icons.visibility_off,
                    title: "Hide Content",
                    subtitle: "Hide message content on lock screen",
                    hasSwitch: true,
                    switchValue: _hideContent,
                    onTap: () {
                      setState(() {
                        _hideContent = !_hideContent;
                      });
                    },
                  ),

                  const SizedBox(height: 32),

                  _buildSectionTitle("SYSTEM"),
                  _buildSettingRow(
                    icon: Icons.save,
                    title: "Save / Load",
                    subtitle: "Manage game progress",
                    onTap: () {
                      // We must use rootNavigator to find GoRouter, but go_router uses `context.push()`
                      // Settings is nested deeply in normal nav. Let's just launch a MaterialPageRoute to the UI screen directly.
                      // Wait, we can just import the screen.
                      // Since this is inside an embedded Navigator (MessengerNavigator), we can push standard routes
                      // or push a MaterialPageRoute directly to SaveLoadScreen.
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (_) => const dreadmoor_save.SaveLoadScreen())
                      );
                    }
                  ),

                  const SizedBox(height: 48),

                  Center(
                    child: Text(
                      "MESSENGER OS v1.2.4",
                      style: DreadmoorTheme.bodyStyle.copyWith(
                        color: DreadmoorColors.textMeta,
                        fontSize: 10,
                        letterSpacing: 2.0,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 16),
      child: Text(
        title,
        style: DreadmoorTheme.headingStyle.copyWith(
          color: DreadmoorColors.textSecondary,
          fontSize: 12,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    bool hasSwitch = false,
    bool switchValue = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DreadmoorColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DreadmoorColors.borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DreadmoorColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: DreadmoorColors.accentCyan, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: DreadmoorTheme.bodyStyle.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: DreadmoorTheme.bodyStyle.copyWith(
                          color: DreadmoorColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasSwitch)
                  Switch(
                    value: switchValue,
                    onChanged: (val) => onTap(),
                    activeColor: DreadmoorColors.accentCyan,
                    activeTrackColor: DreadmoorColors.accentCyan.withOpacity(0.3),
                    inactiveThumbColor: DreadmoorColors.textSecondary,
                    inactiveTrackColor: DreadmoorColors.surface,
                  )
                else
                  const Icon(Icons.chevron_right, color: DreadmoorColors.textMeta, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
