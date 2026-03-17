import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/features/browser/article_model.dart';
import 'package:dreadmoor/core/state/game_state.dart';

class BrowserHomeScreen extends ConsumerWidget {
  const BrowserHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(gameFlagsProvider).value ?? {};
    final hasArticle = flags['article_read'] == true;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // REDESIGNED BROWSER ADDRESS BAR (PILL DESIGN)
          _buildAddressBar(context, brightness),
          
          Expanded(
            child: hasArticle 
              ? _buildArticleFeed(context, ref)
              : _buildEmptyState(brightness),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressBar(BuildContext context, Brightness b) {
    final isDark = b == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: DreadmoorColors.divider(b))),
      ),
      child: Row(
        children: [
          Consumer(
            builder: (context, ref, _) {
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.arrow_back_ios_new, color: DreadmoorColors.text(b), size: 20),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    ref.read(activeAppProvider.notifier).setApp(PhoneApp.messenger);
                  }
                },
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 14, color: isDark ? DreadmoorColors.investigatorCyan : DreadmoorColors.evidenceRed),
                  const SizedBox(width: 8),
                  Text(
                    "dreadmoor-daily.local",
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: DreadmoorColors.text(b).withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleFeed(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final stream = (db.select(db.notifications)
      ..where((n) => n.type.equals('article'))
      ..limit(1)).watchSingleOrNull();

    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final payload = jsonDecode(snapshot.data!.payload ?? '{}');
        final article = Article.fromJson(payload['article'] ?? {});

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildArticleCard(context, article),
          ],
        );
      },
    );
  }

  Widget _buildArticleCard(BuildContext context, Article article) {
    final b = Theme.of(context).brightness;
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/article', arguments: article),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: DreadmoorColors.divider(b)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.photo.isNotEmpty)
              Image.asset(article.photo, height: 180, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.headline.toUpperCase(), style: GoogleFonts.spectral(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(article.subheadline, maxLines: 2, style: GoogleFonts.spectral(fontSize: 14, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Brightness b) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 48, color: DreadmoorColors.text(b).withOpacity(0.2)),
          const SizedBox(height: 16),
          Text("CONNECTION TIMEOUT", style: GoogleFonts.spaceGrotesk(letterSpacing: 4, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
