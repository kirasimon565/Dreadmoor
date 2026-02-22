import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/character_state.dart';
import '../../theme/colors.dart';

class CharacterProfileScreen extends ConsumerWidget {
  final String characterId;

  const CharacterProfileScreen({super.key, required this.characterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(unlockedCharactersProvider(characterId));

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DreadmoorColors.accentCyan),
        ),
        error: (e, _) => _LockedProfile(context),
        data: (profile) {
          if (profile == null) return _LockedProfile(context);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 420,
                pinned: true,
                backgroundColor: DreadmoorColors.background,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    profile.name,
                    style: GoogleFonts.michroma(
                      color: Colors.white,
                      fontSize: 14,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 10),
                      ],
                    ),
                  ),
                  centerTitle: true,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        profile.imagePath,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black,
                            ],
                            stops: [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _info("AGE", profile.age),
                      _info("OCCUPATION", profile.job),
                      _info("RELATION", profile.relationToRebecca),

                      const SizedBox(height: 32),
                      Text(
                        "KNOWN FACTS",
                        style: GoogleFonts.michroma(
                          fontSize: 12,
                          color: DreadmoorColors.accentCyan,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...profile.facts.map(_factItem),

                      if (profile.contradictions.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: DreadmoorColors.accentRed.withOpacity(0.5),
                            ),
                            color: DreadmoorColors.accentRed.withOpacity(0.05),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "CONTRADICTIONS",
                                style: GoogleFonts.michroma(
                                  fontSize: 12,
                                  color: DreadmoorColors.accentRed,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...profile.contradictions.map(_contradictionItem),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.michroma(
                fontSize: 11,
                color: DreadmoorColors.textMeta,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: DreadmoorColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _factItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(Icons.circle, size: 6, color: DreadmoorColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: DreadmoorColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _contradictionItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          "• $text",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: DreadmoorColors.accentRed.withOpacity(0.8),
            height: 1.5,
          ),
        ),
      );
}

class _LockedProfile extends StatelessWidget {
  const _LockedProfile(this.context);
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Center(
        child: Text(
          "PROFILE LOCKED\n\nDISCOVER MORE TO UNLOCK",
          textAlign: TextAlign.center,
          style: GoogleFonts.michroma(
            fontSize: 12,
            letterSpacing: 2,
            color: DreadmoorColors.textMeta,
          ),
        ),
      ),
    );
  }
}
