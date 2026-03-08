import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/os/components/os_header.dart';

class CharacterProfileScreen extends ConsumerWidget {
  final String? characterId;
  final String? threadId;

  const CharacterProfileScreen({super.key, this.characterId, this.threadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real implementation we would fetch the character by Thread ID.
    final name = "UNKNOWN";
    final phone = "+1 (555) 816-0000";

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OSHeader(
              title: "CASE FILE",
              subtitle: "SUBJECT PROFILE",
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, color: DreadmoorColors.textSecondary, size: 24),
              ),
            ),
            Expanded(
              child: DefaultTabController(
                length: 4,
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
                              border: Border.all(color: DreadmoorColors.borderSubtle, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.person, size: 48, color: Colors.white54),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            style: DreadmoorTheme.headingStyle.copyWith(
                              fontSize: 24,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            phone,
                            style: DreadmoorTheme.bodyStyle.copyWith(
                              fontSize: 14,
                              color: DreadmoorColors.accentCyan,
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
                        Tab(text: "BIO"),
                        Tab(text: "KNOWN INFO"),
                        Tab(text: "MEDIA"),
                        Tab(text: "NOTES"),
                      ],
                    ),

                    // Tab Content
                    const Expanded(
                      child: TabBarView(
                        children: [
                          _BioTab(),
                          _KnownInfoTab(),
                          _MediaTab(),
                          _NotesTab(),
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

class _BioTab extends StatelessWidget {
  const _BioTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionTitle("PERSONAL DETAILS"),
        _buildDetailRow("Age", "Unknown"),
        _buildDetailRow("Occupation", "Unknown"),
        _buildDetailRow("Last Known Location", "Dreadmoor Factory"),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: DreadmoorTheme.headingStyle.copyWith(
          fontSize: 12,
          color: DreadmoorColors.textSecondary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label.toUpperCase(),
              style: DreadmoorTheme.bodyStyle.copyWith(
                fontSize: 12,
                color: DreadmoorColors.textMeta,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: DreadmoorTheme.bodyStyle.copyWith(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KnownInfoTab extends StatelessWidget {
  const _KnownInfoTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "NO DATA AVAILABLE",
        style: DreadmoorTheme.bodyStyle.copyWith(
          color: DreadmoorColors.textMeta,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class _MediaTab extends StatelessWidget {
  const _MediaTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 48, color: DreadmoorColors.textMeta),
          const SizedBox(height: 16),
          Text(
            "NO MEDIA RECOVERED",
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

class _NotesTab extends StatelessWidget {
  const _NotesTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "NO INVESTIGATION NOTES YET",
        style: DreadmoorTheme.bodyStyle.copyWith(
          color: DreadmoorColors.textMeta,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}
