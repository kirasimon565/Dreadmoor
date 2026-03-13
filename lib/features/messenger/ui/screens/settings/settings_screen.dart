import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/os/components/os_header.dart';
import 'package:dreadmoor/ui/screens/profiles/player_profile_screen.dart';

// Assuming you have a provider to manage theme mode
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _messageAlerts = true;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            OSHeader(
              title: "SETTINGS",
              subtitle: "SYSTEM CONFIGURATION",
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  _buildSectionTitle(context, "INTERFACE"),
                  
                  // NEW: THEME TOGGLE (Archive vs Slate)
                  _buildSettingRow(
                    context,
                    icon: isDark ? Icons.dark_mode : Icons.newspaper,
                    title: isDark ? "Tactical Slate" : "The Archive",
                    subtitle: "Toggle between OS modes",
                    trailing: Switch(
                      value: isDark,
                      activeColor: DreadmoorColors.investigatorCyan,
                      onChanged: (val) {
                        ref.read(themeProvider.notifier).state = 
                            val ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                    onTap: () {},
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle(context, "ACCOUNT"),
                  _buildSettingRow(
                    context,
                    icon: Icons.account_circle_outlined,
                    title: "Investigator Profile",
                    subtitle: "Manage ID and credentials",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerProfileScreen()));
                    },
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle(context, "NOTIFICATIONS"),
                  _buildSettingRow(
                    context,
                    icon: Icons.notifications_none_outlined,
                    title: "Signal Alerts",
                    subtitle: "Connection ping and vibration",
                    trailing: Switch(
                      value: _messageAlerts,
                      activeColor: isDark ? DreadmoorColors.investigatorCyan : DreadmoorColors.evidenceRed,
                      onChanged: (val) => setState(() => _messageAlerts = val),
                    ),
                    onTap: () {},
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle(context, "DATA MANAGEMENT"),
                  _buildSettingRow(
                    context,
                    icon: Icons.Sd_storage_outlined,
                    title: "Save State",
                    subtitle: "Commit current progress to disk",
                    onTap: () {
                      // Launch Save/Load UI
                    },
                  ),

                  const SizedBox(height: 60),
                  Center(
                    child: Text(
                      "DREADMOOR OS // BUILD 2026.4.12",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: DreadmoorColors.text(brightness).withOpacity(0.4),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: DreadmoorTheme.headingStyle(brightness).copyWith(
              fontSize: 11,
              color: DreadmoorColors.text(brightness).withOpacity(0.5),
            ),
          ),
          Divider(color: DreadmoorColors.divider(brightness), thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final brightness = Theme.of(context).brightness;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: DreadmoorColors.divider(brightness), width: 0.5),
        borderRadius: BorderRadius.circular(4), // Sharp corners like Case File
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: DreadmoorColors.text(brightness), size: 22),
        title: Text(
          title.toUpperCase(),
          style: DreadmoorTheme.headingStyle(brightness).copyWith(fontSize: 13),
        ),
        subtitle: Text(
          subtitle,
          style: DreadmoorTheme.bodyStyle(brightness).copyWith(fontSize: 11),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right, color: DreadmoorColors.text(brightness).withOpacity(0.3)),
      ),
    );
  }
}
