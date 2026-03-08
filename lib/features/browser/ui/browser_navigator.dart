import 'package:flutter/material.dart';

import 'package:dreadmoor/features/browser/ui/screens/browser/browser_home_screen.dart';
import 'package:dreadmoor/features/browser/ui/screens/browser/article_viewer_screen.dart';
import 'package:dreadmoor/features/browser/article_model.dart';

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
        if (settings.name == BrowserRoutes.home) {
          return MaterialPageRoute(
            builder: (context) => const BrowserHomeScreen(),
          );
        } else if (settings.name == BrowserRoutes.article) {
          final article = settings.arguments as Article;
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                   Container(
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF111111),
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0x14FFFFFF),
                          width: 1.0,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.arrow_back_ios, color: Color(0x73FFFFFF), size: 18),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0x0AFFFFFF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0x14FFFFFF)),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock, size: 12, color: Color(0x73FFFFFF)),
                                const SizedBox(width: 6),
                                Text(
                                  'dreadmoor-daily.local',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0x73FFFFFF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.refresh, color: Color(0x73FFFFFF), size: 20),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ArticleViewerScreen(article: article),
                  )
                ]
              )
            ),
          );
        }
        return null;
      },
    );
  }
}
