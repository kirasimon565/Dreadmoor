import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/episode_state.dart';
import '../../../core/state/game_state.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';
import '../../widgets/episode_teaser_card.dart';

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
            title: "EPISODES",
            onBackPressed: () => context.pop(),
          ),

          Expanded(
            child: episodesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: DreadmoorColors.accentCyan)),
              error: (e, _) => Center(child: Text("FAILED TO LOAD EPISODES", style: GoogleFonts.michroma(color: Colors.red))),
              data: (episodes) {
                if (episodes.isEmpty) {
                  return Center(
                    child: Text(
                      "NO EPISODES FOUND",
                      style: GoogleFonts.michroma(color: DreadmoorColors.textMeta),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: episodes.length,
                  itemBuilder: (context, index) {
                    final ep = episodes[index];
                    final episode = ep.episode;

                    return EpisodeTeaserCard(
                      episodeId: episode.id,
                      title: _episodeTitle(episode.id),
                      description: _episodeDescription(episode.id),
                      isLocked: !episode.isUnlocked,
                      progress: ep.progress,
                      onTap: () async {
                        if (!episode.isUnlocked) return;

                        final scheduler = ref.read(globalSchedulerProvider);

                        // Resume or start logic
                        if (ep.progress > 0.0 && ep.progress < 1.0) {
                          context.go('/messenger');
                        } else if (ep.progress == 1.0) {
                          context.go('/recap/${episode.id}');
                        } else {
                          await scheduler.startThread(episode.id, 'main');
                          context.go('/messenger');
                        }
                      },
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

  String _episodeTitle(String id) {
    switch (id) {
      case 'ep01': return 'THE VANISHING';
      case 'ep02': return 'SILENT ECHOES';
      case 'ep03': return 'BROKEN GLASS';
      default: return id.toUpperCase();
    }
  }

  String _episodeDescription(String id) {
    switch (id) {
      case 'ep01': return 'The disappearance of Rebecca Stone sends shockwaves through Dreadmoor.';
      case 'ep02': return 'As the investigation deepens, old secrets begin to surface.';
      case 'ep03': return 'Trust no one. The truth is fragmented.';
      default: return 'Classified episode.';
    }
  }
}
