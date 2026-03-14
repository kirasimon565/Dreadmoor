import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/features/browser/ui/screens/browser/browser_home_screen.dart';
import 'package:dreadmoor/features/browser/ui/screens/browser/article_viewer_screen.dart'; // Updated name
import 'package:dreadmoor/features/browser/article_model.dart';
import 'package:dreadmoor/ui/theme/colors.dart';

class BrowserRoutes {
  static const home = '/';
  static const article = '/article';
}

class BrowserNavigator extends StatelessWidget {
  const BrowserNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: BrowserRoutes.home,
      onGenerateRoute: (settings) {
        final brightness = Theme.of(context).brightness;
        final isDark = brightness == Brightness.dark;

        if (settings.name == BrowserRoutes.home) {
          return _noTransitionRoute(const BrowserHomeScreen());
        } 
        
        if (settings.name == BrowserRoutes.article) {
          Article article;
          if (settings.arguments is Map) {
            article = Article.fromJson(settings.arguments as Map<String, dynamic>);
          } else {
            article = settings.arguments as Article;
          }

          return _noTransitionRoute(
            Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Column(
                children: [
                  // ── THE REDESIGNED BROWSER ADDRESS BAR ──────────────────────
                  Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      bottom: 12,
                      left: 12,
                      right: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border(
                        bottom: BorderSide(color: DreadmoorColors.divider(brightness)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            return IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                Navigator.of(context).pop();
                                // Resume the story once the article is closed
                                ref.read(globalSchedulerProvider).resume();
                              },
                            );
                          }
                        ),
                        
                        Expanded(
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              // Matches the "Pill" design from your chat screenshots
                              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 14,
                                  color: isDark ? DreadmoorColors.investigatorCyan : DreadmoorColors.evidenceRed,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'dreadmoor-daily.local',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: DreadmoorColors.text(brightness).withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 10),
                        const Icon(Icons.share_outlined, size: 20),
                      ],
                    ),
                  ),

                  // THE ARTICLE CONTENT
                  Expanded(
                    child: ArticleViewerScreen(article: article),
                  )
                ],
              ),
            ),
          );
        }
        return null;
      },
    );
  }

  /// Instant OS-style transitions for browser pages
  Route _noTransitionRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }
}
