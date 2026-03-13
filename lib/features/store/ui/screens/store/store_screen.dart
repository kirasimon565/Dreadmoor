import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/os/components/os_header.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          OSHeader(
            title: "PROCUREMENT",
            subtitle: "AUTHORIZED PERSONNEL ONLY",
            trailing: Icon(
              Icons.shield_outlined, 
              color: isDark ? DreadmoorColors.investigatorCyan : DreadmoorColors.evidenceRed,
              size: 20
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionHeader(context, "OPERATIONAL UPGRADES"),
                
                _buildStoreItem(
                  context,
                  title: "TRACE SIGNAL UNIT",
                  description: "Enables real-time typing indicators for encrypted channels.",
                  price: "€1.99",
                  icon: Icons.radar_rounded,
                ),
                
                _buildStoreItem(
                  context,
                  title: "DREADMOOR DAILY: ARCHIVE",
                  description: "Full access to the 1970s Newspaper UI theme permanently.",
                  price: "€0.99",
                  icon: Icons.newspaper_rounded,
                ),

                const SizedBox(height: 32),
                _buildSectionHeader(context, "ADDITIONAL DOSSIERS"),

                _buildStoreItem(
                  context,
                  title: "THE VOSS CONSPIRACY",
                  description: "Unlock the 'Voss' expansion. 4 new characters, 20+ secret files.",
                  price: "€4.99",
                  icon: Icons.folder_shared_rounded,
                  isPremium: true,
                ),

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    "CONNECTED TO: ${isDark ? 'AMAZON SECURE' : 'HUAWEI APPGALLERY'}",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: DreadmoorColors.text(brightness).withOpacity(0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final b = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: DreadmoorTheme.headingStyle(b).copyWith(
              fontSize: 11,
              color: DreadmoorColors.text(b).withOpacity(0.5),
            ),
          ),
          Divider(color: DreadmoorColors.divider(b), thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildStoreItem(
    BuildContext context, {
    required String title,
    required String description,
    required String price,
    required IconData icon,
    bool isPremium = false,
  }) {
    final b = Theme.of(context).brightness;
    final accent = b == Brightness.dark ? DreadmoorColors.investigatorCyan : DreadmoorColors.evidenceRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: isPremium ? accent : DreadmoorColors.divider(b),
          width: isPremium ? 1.5 : 0.5,
        ),
        borderRadius: BorderRadius.circular(4), // Sharp corners
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, color: accent, size: 28),
        title: Text(
          title,
          style: DreadmoorTheme.headingStyle(b).copyWith(fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: DreadmoorTheme.bodyStyle(b).copyWith(fontSize: 12, height: 1.4),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: accent,
          child: Text(
            price,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
