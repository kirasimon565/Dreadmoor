import 'package:flutter/material.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/features/browser/article_model.dart';

class BrowserHomeScreen extends StatelessWidget {
  const BrowserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockArticles = [
      Article(
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
      ),
      Article(
        id: '2',
        headline: 'Mayor Announces New Curfew',
        subheadline: 'In response to recent events, a strict curfew is now in effect.',
        photo: 'assets/branding/dreadmoor_daily_logo.png',
        caption: 'Mayor speaking at the town hall.',
        body: [
          'Effective immediately, all residents must remain indoors between the hours of 10:00 PM and 6:00 AM.',
          'This measure has been put in place to ensure the safety of our community while authorities work to resolve the current situation.'
        ],
      )
    ];

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                const Divider(color: DreadmoorColors.divider, height: 1),
                const SizedBox(height: 24),
                ...mockArticles.map((article) => _buildArticleCard(context, article)),
              ],
            ),
          ),
        ],
      ),
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
              'June 12, 2007',
              style: DreadmoorTheme.bodyStyle.copyWith(
                fontSize: 11,
                color: DreadmoorColors.textMeta,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
