import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: DreadmoorColors.background,
        body: Center(
          child: CircularProgressIndicator(color: DreadmoorColors.accentCyan),
        ),
      ),
      error: (_, __) => const _LockedProfile(),
      data: (profile) {
        if (profile == null) return const _LockedProfile();
        return _ProfileContent(profile: profile);
      },
    );
  }
}

// ── Full profile content ───────────────────────────────────────────────────

class _ProfileContent extends StatelessWidget {
  final CharacterProfile profile;
  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Parallax header ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 440,
            pinned: true,
            stretch: true,
            backgroundColor: DreadmoorColors.background,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding:
                  const EdgeInsets.only(bottom: 16, left: 48, right: 48),
              title: Text(
                profile.name.toUpperCase(),
                style: GoogleFonts.michroma(
                  color: Colors.white,
                  fontSize: 13,
                  letterSpacing: 2.5,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 12),
                    Shadow(color: Colors.black, blurRadius: 24),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Character photo
                  Image.asset(
                    profile.imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    // ✅ errorBuilder — no crash if character asset missing
                    errorBuilder: (_, __, ___) => Container(
                      color: DreadmoorColors.surface,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 80,
                        color: DreadmoorColors.textMeta,
                      ),
                    ),
                  ),

                  // Bottom fade to background
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          DreadmoorColors.background,
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),

                  // Subtle grain on photo
                  IgnorePointer(
                    child: Opacity(
                      opacity: 0.05,
                      child: Image.asset(
                        'assets/ui/glitch_overlay.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Info panel ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic info grid
                  _InfoRow(label: "AGE", value: profile.age),
                  _InfoRow(label: "OCCUPATION", value: profile.job),
                  _InfoRow(
                      label: "RELATION", value: profile.relationToRebecca),

                  const SizedBox(height: 32),
                  const _Divider(),
                  const SizedBox(height: 24),

                  // Known facts
                  _SectionLabel(
                    label: "KNOWN FACTS",
                    color: DreadmoorColors.accentCyan,
                  ),
                  const SizedBox(height: 14),
                  ...profile.facts.map((f) => _FactItem(text: f)),

                  // Contradictions (late-game unlock)
                  if (profile.contradictions.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const _Divider(
                        color: DreadmoorColors.accentRed, opacity: 0.3),
                    const SizedBox(height: 24),
                    _SectionLabel(
                      label: "CONTRADICTIONS",
                      color: DreadmoorColors.accentRed,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "INCONSISTENCIES DETECTED",
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        letterSpacing: 1.5,
                        color: DreadmoorColors.accentRed.withOpacity(0.45),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DreadmoorColors.accentRed.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: DreadmoorColors.accentRed.withOpacity(0.3),
                          width: 0.6,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: profile.contradictions
                            .map((c) => _ContradictionItem(text: c))
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Locked profile ─────────────────────────────────────────────────────────

class _LockedProfile extends StatelessWidget {
  const _LockedProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          // Blurred placeholder
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: DreadmoorColors.surface.withOpacity(0.3)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white54),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.lock_outline_rounded,
                  color: DreadmoorColors.accentRed.withOpacity(0.6),
                  size: 44,
                ),
                const SizedBox(height: 20),
                Text(
                  "PROFILE LOCKED",
                  style: GoogleFonts.michroma(
                    fontSize: 13,
                    color: DreadmoorColors.textMeta,
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "DISCOVER MORE TO UNLOCK",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: DreadmoorColors.textMeta.withOpacity(0.5),
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ───────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.michroma(
                fontSize: 10,
                color: DreadmoorColors.textMeta,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: DreadmoorColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.michroma(
        fontSize: 11,
        color: color,
        letterSpacing: 2.5,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  final double opacity;
  const _Divider({
    this.color = Colors.white,
    this.opacity = 0.07,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      color: color.withOpacity(opacity),
    );
  }
}

class _FactItem extends StatelessWidget {
  final String text;
  const _FactItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: DreadmoorColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: DreadmoorColors.textPrimary,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContradictionItem extends StatelessWidget {
  final String text;
  const _ContradictionItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 12,
              color: DreadmoorColors.accentRed.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: DreadmoorColors.accentRed.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
