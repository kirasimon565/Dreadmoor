import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/features/browser/article_model.dart';

class ArticleViewerScreen extends StatelessWidget {
  final Article article;

  const ArticleViewerScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset("assets/branding/dreadmoor_daily_logo.png", height: 60),

          const SizedBox(height: 20),

          Text(
            article.headline,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            article.subheadline,
            style: GoogleFonts.sourceSerif4(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 20),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(article.photo),
          ),

          const SizedBox(height: 8),

          Text(
            article.caption,
            style: GoogleFonts.sourceSerif4(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 24),

          ...article.body.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                p,
                style: GoogleFonts.sourceSerif4(fontSize: 17, height: 1.6),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
