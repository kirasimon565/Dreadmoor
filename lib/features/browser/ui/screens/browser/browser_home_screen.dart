import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/features/browser/article_model.dart';
import 'package:dreadmoor/core/state/game_state.dart';

class BrowserHomeScreen extends ConsumerWidget {
  const BrowserHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reveal the article content only once the story triggers the specific flag.
    final flags = ref.watch(gameFlagsProvider);
    final hasArticle = flags['article_read'] == true;

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: hasArticle
                ? _buildContent(context)
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.public_off, size: 64, color: DreadmoorColors.textMeta.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(
            "NO SIGNAL",
            style: DreadmoorTheme.headingStyle.copyWith(
              color: DreadmoorColors.textMeta,
              letterSpacing: 4.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Check your connection or wait for updates.",
            style: DreadmoorTheme.bodyStyle.copyWith(
              color: DreadmoorColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final storyArticle = Article(
      id: '1',
      headline: 'Woman Missing After Factory Party',
      subheadline: 'Police begin investigation after strange events at an abandoned factory.',
      photo: 'assets/branding/dreadmoor_daily_logo.png', // Placeholder
      caption: 'The abandoned factory on the outskirts of town.',
      body: [
        'Late last night, authorities received multiple reports of a disturbance at the old textile factory. What started as an unauthorized gathering quickly escalated into a chaotic scene.',
        'Eyewitnesses claim to have seen flashing lights and heard unidentifiable noises originating from the main production floor before the power was abruptly cut.',
        'The investigation is ongoing. If you have any information, please contact the local authorities immediately.'
      ],
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        const Divider(color: DreadmoorColors.divider, height: 1),
        const SizedBox(height: 24),
        _buildArticleCard(context, storyArticle),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: DreadmoorColors.surfaceAlt,
        border: Border(
          bottom: BorderSide(
            color: DreadmoorColors.divider,
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.arrow_back_ios, color: DreadmoorColors.textDisabled, size: 18),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: DreadmoorColors.background,
                borderRadius: BorderRadius.circular(6), // Less rounded for realism
                border: Border.all(color: DreadmoorColors.borderSubtle),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 12, color: DreadmoorColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'dreadmoor-daily.local',
                    style: DreadmoorTheme.bodyStyle.copyWith(
                      fontSize: 13,
                      color: DreadmoorColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.refresh, color: DreadmoorColors.textSecondary, size: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Using a serif font specifically for the newspaper header if possible, else michroma
        Text(
          'DREADMOOR DAILY',
          textAlign: TextAlign.center,
          style: DreadmoorTheme.headingStyle.copyWith(
            fontSize: 32,
            color: DreadmoorColors.textPrimary,
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Local news for the town of Dreadmoor',
          textAlign: TextAlign.center,
          style: DreadmoorTheme.bodyStyle.copyWith(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: DreadmoorColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildArticleCard(BuildContext context, Article article) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed('/article', arguments: article);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail image spans full width like a web card
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: DreadmoorColors.surfaceGlass,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: DreadmoorColors.borderSubtle),
              ),
              child: const Icon(Icons.image, color: DreadmoorColors.textDisabled, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              article.headline,
              style: DreadmoorTheme.headingStyle.copyWith(
                fontSize: 20,
                color: DreadmoorColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article.subheadline,
              style: DreadmoorTheme.bodyStyle.copyWith(
                fontSize: 14,
                color: DreadmoorColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              'March 8', // Syncs with Game Time start day
              style: DreadmoorTheme.bodyStyle.copyWith(
                fontSize: 11,
                color: DreadmoorColors.textMeta,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
