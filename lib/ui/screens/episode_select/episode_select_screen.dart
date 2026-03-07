import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/episode_state.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/widgets/custom_screen_header.dart';
import 'package:dreadmoor/ui/widgets/episode_teaser_card.dart';

class EpisodeSelectScreen extends ConsumerWidget {
  const EpisodeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(episodesProvider);

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Column(
        children: [
          CustomScreenHeader(
            title: 'EPISODES',
            onBackPressed: () => context.pop(),
          ),

          // Season label strip
          _SeasonHeader(),

          Expanded(
            child: episodesAsync.when(
              loading: () => const _LoadingState(),
              error: (e, _) => _ErrorState(error: e.toString()),
              data: (episodes) {
                if (episodes.isEmpty) {
                  return const _EmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  itemCount: episodes.length,
                  itemBuilder: (context, index) {
                    final ep = episodes[index];
                    final episode = ep.episode;

                    return EpisodeTeaserCard(
                      episodeId: episode.id,
                      title: _episodeTitle(episode.id),
                      description: _episodeDescription(episode.id),
                      isLocked: !episode.isUnlocked,
                      // FIX: DB stores progress as int (0–100), not a double.
                      // episode.progress is used directly from the Episodes table.
                      progress: episode.progress,
                      index: index,
                      onTap: () => _handleEpisodeTap(
                        context: context,
                        ref: ref,
                        episodeId: episode.id,
                        progress: episode.progress,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEpisodeTap({
    required BuildContext context,
    required WidgetRef ref,
    required String episodeId,
    required int progress,
  }) async {
    // FIX: progress is an int (0–100), not a double (0.0–1.0)
    if (progress > 0 && progress < 100) {
      // Episode in progress — resume from messenger
      context.go('/messenger');
    } else if (progress == 100) {
      // Episode complete — go to recap
      context.go('/recap/$episodeId');
    } else {
      // Episode not started — start it
      final scheduler = ref.read(globalSchedulerProvider);
      await scheduler.startThread(episodeId, 'main');
      if (context.mounted) context.go('/messenger');
    }
  }

  String _episodeTitle(String id) {
    return switch (id) {
      'ep01' => 'THE VANISHING',
      'ep02' => 'SILENT ECHOES',
      'ep03' => 'BROKEN GLASS',
      _ => id.toUpperCase(),
    };
  }

  String _episodeDescription(String id) {
    return switch (id) {
      'ep01' =>
        'The disappearance of Rebecca Stone sends shockwaves through Dreadmoor.',
      'ep02' => 'As the investigation deepens, old secrets begin to surface.',
      'ep03' => 'Trust no one. The truth is fragmented.',
      _ => 'Classified episode.',
    };
  }
}

// ─────────────────────────────────────────────
// Season header strip
// ─────────────────────────────────────────────

class _SeasonHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DreadmoorColors.surface,
        border: Border(
          left: BorderSide(color: DreadmoorColors.accentRed, width: 2),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SEASON ONE',
                style: GoogleFonts.michroma(
                  fontSize: 11,
                  letterSpacing: 3,
                  color: DreadmoorColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'CITY OF SHADOWS',
                style: GoogleFonts.michroma(
                  fontSize: 9,
                  letterSpacing: 2,
                  color: DreadmoorColors.accentRed,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Decorative dots representing episode slots
          Row(
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? DreadmoorColors.accentCyan
                        : DreadmoorColors.surface,
                    border: Border.all(
                      color: i == 0
                          ? DreadmoorColors.accentCyan
                          : DreadmoorColors.textMeta.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: i == 0
                        ? [
                            BoxShadow(
                              color: DreadmoorColors.glowCyan.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Loading / Error / Empty states
// ─────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: DreadmoorColors.accentCyan,
            strokeWidth: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'RETRIEVING INTEL...',
          style: GoogleFonts.michroma(
            fontSize: 10,
            letterSpacing: 3,
            color: DreadmoorColors.textMeta,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: DreadmoorColors.accentRed,
            size: 32,
          ),
          const SizedBox(height: 16),
          Text(
            'TRANSMISSION ERROR',
            style: GoogleFonts.michroma(
              fontSize: 12,
              letterSpacing: 2.5,
              color: DreadmoorColors.accentRed,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'FAILED TO LOAD EPISODES',
            style: GoogleFonts.michroma(
              fontSize: 9,
              letterSpacing: 2,
              color: DreadmoorColors.textMeta,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(
                color: DreadmoorColors.textMeta.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.folder_off_outlined,
              color: DreadmoorColors.textMeta.withOpacity(0.4),
              size: 22,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'NO EPISODES FOUND',
            style: GoogleFonts.michroma(
              fontSize: 10,
              letterSpacing: 3,
              color: DreadmoorColors.textMeta,
            ),
          ),
        ],
      ),
    );
  }
}
