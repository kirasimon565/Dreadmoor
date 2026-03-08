import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/features/browser/article_model.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';

class ArticleViewerScreen extends StatelessWidget {
  final Article article;

  const ArticleViewerScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DreadmoorColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'DREADMOOR DAILY',
                textAlign: TextAlign.center,
                style: DreadmoorTheme.headingStyle.copyWith(
                  fontSize: 28,
                  color: DreadmoorColors.textPrimary,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              article.headline,
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: DreadmoorColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              article.subheadline,
              style: GoogleFonts.sourceSerif4(
                fontSize: 18,
                color: DreadmoorColors.textSecondary,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: DreadmoorColors.surfaceAlt,
                border: Border.all(color: DreadmoorColors.borderSubtle),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 64, color: DreadmoorColors.textDisabled),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              article.caption,
              style: GoogleFonts.sourceSerif4(
                fontSize: 12,
                color: DreadmoorColors.textMeta,
              ),
            ),
            const SizedBox(height: 32),
            ...article.body.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  p,
                  style: GoogleFonts.sourceSerif4(
                    fontSize: 18,
                    height: 1.6,
                    color: DreadmoorColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
