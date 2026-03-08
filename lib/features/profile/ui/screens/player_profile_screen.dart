import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/os/components/os_header.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const OSHeader(
              title: "MY PROFILE",
              subtitle: "INVESTIGATOR PORTAL",
            ),
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    // Profile Header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: DreadmoorColors.surfaceAlt,
                              shape: BoxShape.circle,
                              border: Border.all(color: DreadmoorColors.accentCyan.withOpacity(0.5), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: DreadmoorColors.accentCyan.withOpacity(0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.person, size: 48, color: DreadmoorColors.accentCyan),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "DETECTIVE",
                            style: DreadmoorTheme.headingStyle.copyWith(
                              fontSize: 24,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "+1 (555) 000-0000",
                            style: DreadmoorTheme.bodyStyle.copyWith(
                              fontSize: 14,
                              color: DreadmoorColors.textSecondary,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tabs
                    TabBar(
                      indicatorColor: DreadmoorColors.accentCyan,
                      labelColor: DreadmoorColors.accentCyan,
                      unselectedLabelColor: DreadmoorColors.textSecondary,
                      labelStyle: DreadmoorTheme.bodyStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      tabs: const [
                        Tab(text: "ID CARD"),
                        Tab(text: "BIO"),
                        Tab(text: "EVIDENCE"),
                      ],
                    ),

                    // Tab Content
                    const Expanded(
                      child: TabBarView(
                        children: [
                          _IdTab(),
                          _BioTab(),
                          _EvidenceTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdTab extends StatelessWidget {
  const _IdTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DreadmoorColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "DREADMOOR P.D.",
                  style: DreadmoorTheme.headingStyle.copyWith(
                    fontSize: 16,
                    color: DreadmoorColors.accentCyan,
                    letterSpacing: 2.0,
                  ),
                ),
                const Icon(Icons.local_police, color: DreadmoorColors.accentCyan),
              ],
            ),
            const Divider(color: Colors.white24, height: 32),
            _buildDetailRow("Rank", "Detective"),
            _buildDetailRow("Status", "Active"),
            _buildDetailRow("Clearance", "Level 4"),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: DreadmoorTheme.bodyStyle.copyWith(
              fontSize: 12,
              color: DreadmoorColors.textMeta,
            ),
          ),
          Text(
            value,
            style: DreadmoorTheme.bodyStyle.copyWith(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BioTab extends StatelessWidget {
  const _BioTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "PERSONAL DETAILS",
          style: DreadmoorTheme.headingStyle.copyWith(
            fontSize: 12,
            color: DreadmoorColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "You are a detective investigating the disappearance of Rebecca Stone in the town of Dreadmoor. The case has recently gone cold, until tonight.",
          style: DreadmoorTheme.bodyStyle.copyWith(
            fontSize: 14,
            color: Colors.white70,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _EvidenceTab extends StatelessWidget {
  const _EvidenceTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 48, color: DreadmoorColors.textMeta),
          const SizedBox(height: 16),
          Text(
            "NO EVIDENCE RECEIVED",
            style: DreadmoorTheme.bodyStyle.copyWith(
              color: DreadmoorColors.textMeta,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
