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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NEWSPAPER MASTHEAD
            Center(
              child: Text(
                'DREADMOOR DAILY',
                style: GoogleFonts.spectral(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isDark ? DreadmoorColors.investigatorCyan : DreadmoorColors.evidenceRed,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const Divider(thickness: 1.5, height: 40),

            // HEADLINE
            Text(
              article.headline.toUpperCase(),
              style: GoogleFonts.spectral(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                height: 1.1,
                color: DreadmoorColors.text(brightness),
              ),
            ),
            const SizedBox(height: 12),
            
            // SUBHEADLINE
            Text(
              article.subheadline,
              style: GoogleFonts.spectral(
                fontSize: 19,
                fontStyle: FontStyle.italic,
                height: 1.3,
                color: DreadmoorColors.text(brightness).withOpacity(0.7),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // PHOTO WITH CAPTION
            if (article.photo.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: DreadmoorColors.divider(brightness)),
                    ),
                    child: Image.asset(article.photo, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.caption.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: DreadmoorColors.text(brightness).withOpacity(0.5),
                    ),
                  ),
                ],
              ),

            const Divider(height: 48),

            // ARTICLE BODY
            ...article.body.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                p,
                style: GoogleFonts.spectral(
                  fontSize: 17,
                  height: 1.6,
                  color: DreadmoorColors.text(brightness).withOpacity(0.9),
                ),
              ),
            )),
            
            const SizedBox(height: 60),
            Center(child: Icon(Icons.emergency, color: isDark ? Colors.white10 : Colors.black12, size: 40)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
