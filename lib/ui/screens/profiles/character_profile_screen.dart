import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/os/components/os_header.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';

class CharacterProfileScreen extends ConsumerStatefulWidget {
  final String? characterId;
  final String? threadId;

  const CharacterProfileScreen({super.key, this.characterId, this.threadId});

  @override
  ConsumerState<CharacterProfileScreen> createState() => _CharacterProfileScreenState();
}

class _CharacterProfileScreenState extends ConsumerState<CharacterProfileScreen> {
  Character? _character;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCharacter();
  }

  Future<void> _loadCharacter() async {
    final db = ref.read(databaseProvider);

    // First, try to find the character directly if characterId was passed
    if (widget.characterId != null) {
      _character = await (db.select(db.characters)..where((c) => c.id.equals(widget.characterId!))).getSingleOrNull();
    }

    // If not found, try to resolve via threadId.
    // As configured in Add Contact, the threadId is often exactly the characterId.
    if (_character == null && widget.threadId != null) {
       _character = await (db.select(db.characters)..where((c) => c.id.equals(widget.threadId!))).getSingleOrNull();

       if (_character == null) {
           // Fallback logic
           final thread = await (db.select(db.threads)..where((t) => t.id.equals(widget.threadId!))).getSingleOrNull();
           if (thread != null) {
               _character = await (db.select(db.characters)..where((c) => c.phoneNumber.equals(thread.title))).getSingleOrNull();
           }
       }
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: DreadmoorColors.background,
        body: Center(child: CircularProgressIndicator(color: DreadmoorColors.accentCyan)),
      );
    }

    final name = _character?.name ?? "UNKNOWN NUMBER";
    final phone = _character?.phoneNumber ?? (widget.threadId ?? "UNKNOWN");
    final bio = _character?.bio;
    final knownInfo = _character?.knownInfo;
    final notes = _character?.investigationNotes;

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
                            child: _character?.avatarPath == null
                                ? const Icon(Icons.person, size: 48, color: Colors.white54)
                                : ClipOval(
                                    // Handle bundled assets vs document directory images
                                    child: _character!.avatarPath!.startsWith('assets/')
                                        ? Image.asset(_character!.avatarPath!, fit: BoxFit.cover)
                                        : FutureBuilder<Directory>(
                                            future: getApplicationDocumentsDirectory(),
                                            builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                    final file = File(p.join(snapshot.data!.path, _character!.avatarPath!));
                                                    if (file.existsSync()) {
                                                        return Image.file(file, fit: BoxFit.cover);
                                                    }
                                                }
                                                return const Icon(Icons.person, size: 48, color: Colors.white54);
                                            }
                                        ),
                                ),
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
                    Expanded(
                      child: TabBarView(
                        children: [
                          _BioTab(bio: bio),
                          _KnownInfoTab(info: knownInfo),
                          const _MediaTab(),
                          _NotesTab(notes: notes),
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
  final String? bio;

  const _BioTab({this.bio});

  @override
  Widget build(BuildContext context) {
    if (bio == null || bio!.isEmpty) {
        return Center(
          child: Text(
            "NO BIOGRAPHICAL DATA",
            style: DreadmoorTheme.bodyStyle.copyWith(
              color: DreadmoorColors.textMeta,
              letterSpacing: 2.0,
            ),
          ),
        );
    }
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
          bio!,
          style: DreadmoorTheme.bodyStyle.copyWith(
            fontSize: 14,
            color: Colors.white70,
            height: 1.6,
          ),
        ),
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
  final String? info;

  const _KnownInfoTab({this.info});

  @override
  Widget build(BuildContext context) {
    if (info == null || info!.isEmpty) {
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          info!,
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
  final String? notes;

  const _NotesTab({this.notes});

  @override
  Widget build(BuildContext context) {
    if (notes == null || notes!.isEmpty) {
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          notes!,
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
