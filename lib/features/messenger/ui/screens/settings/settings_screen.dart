import 'package:flutter/material.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/os/components/os_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                  _buildSettingRow(Icons.person, "Profile Settings", "Manage avatar and bio"),
                  _buildSettingRow(Icons.security, "Privacy", "Encryption and connection status"),

                  const SizedBox(height: 32),

                  _buildSectionTitle("NOTIFICATIONS"),
                  _buildSettingRow(Icons.notifications, "Message Alerts", "Sound, vibration, priority", hasSwitch: true, switchValue: true),
                  _buildSettingRow(Icons.visibility_off, "Hide Content", "Hide message content on lock screen", hasSwitch: true, switchValue: false),

                  const SizedBox(height: 32),

                  _buildSectionTitle("STORAGE & DATA"),
                  _buildSettingRow(Icons.storage, "Storage Usage", "0.4 GB used"),
                  _buildSettingRow(Icons.delete_outline, "Clear Cache", "Delete temporary files"),

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

  Widget _buildSettingRow(IconData icon, String title, String subtitle, {bool hasSwitch = false, bool switchValue = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DreadmoorColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DreadmoorColors.borderSubtle),
      ),
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
              onChanged: (val) {},
              activeColor: DreadmoorColors.accentCyan,
              activeTrackColor: DreadmoorColors.accentCyan.withOpacity(0.3),
              inactiveThumbColor: DreadmoorColors.textSecondary,
              inactiveTrackColor: DreadmoorColors.surface,
            )
          else
            const Icon(Icons.chevron_right, color: DreadmoorColors.textMeta, size: 20),
        ],
      ),
    );
  }
}
