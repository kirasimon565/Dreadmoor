import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';
import '../../widgets/episode_teaser_card.dart';

class EpisodeSelectScreen extends ConsumerWidget {
  const EpisodeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock Data (until drift is populated)
    final episodes = [
      {
        'id': 'ep01',
        'title': 'The Vanishing',
        'description': 'The disappearance of Rebecca Stone sends shockwaves through Dreadmoor.',
        'locked': false,
        'progress': 0.15,
      },
      {
        'id': 'ep02',
        'title': 'Silent Echoes',
        'description': 'As the investigation deepens, old secrets begin to surface.',
        'locked': true,
        'progress': 0.0,
      },
      {
        'id': 'ep03',
        'title': 'Broken Glass',
        'description': 'Trust no one. The truth is fragmented.',
        'locked': true,
        'progress': 0.0,
      },
    ];

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Column(
        children: [
          CustomScreenHeader(
            title: "EPISODES",
            onBackPressed: () => context.pop(),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                final ep = episodes[index];
                return EpisodeTeaserCard(
                  episodeId: ep['id'] as String,
                  title: ep['title'] as String,
                  description: ep['description'] as String,
                  isLocked: ep['locked'] as bool,
                  progress: ep['progress'] as double,
                  onTap: () {
                    // Check if progress > 0?
                    // If completed, maybe show Recap?
                    // If in progress, resume via GlobalScheduler
                    // Logic:
                    final scheduler = ref.read(globalSchedulerProvider);
                    // scheduler.startEpisode(ep['id']); // Need startEpisode logic
                    // For now, just go to messenger
                    context.go('/messenger');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
