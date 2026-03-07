import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/browser/article_model.dart';
import '../../theme/colors.dart';
import 'article_viewer_screen.dart';

class DreadmoorBrowserScreen extends StatelessWidget {
  final Article article;

  const DreadmoorBrowserScreen({
    super.key,
    required this.article,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(46),
        child: AppBar(
          backgroundColor: const Color(0xffe9e9e9),
          elevation: 0,
          title: Row(
            children: [
              const Icon(
                Icons.lock,
                size: 14,
                color: Colors.black54,
              ),
              const SizedBox(width: 6),
              const Text(
                "dreadmoor-daily.com",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ArticleViewerScreen(article: article),
    );
  }
}
