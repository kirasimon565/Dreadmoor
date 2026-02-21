import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

class RecapScreen extends ConsumerStatefulWidget {
  const RecapScreen({super.key});

  @override
  ConsumerState<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends ConsumerState<RecapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ScrollController _listController = ScrollController();

  final List<String> recapLines = [
    "PREVIOUSLY ON DREADMOOR...",
    "",
    "Rebecca vanished without a trace.",
    "Her phone was recovered near the factory.",
    "You confronted Amelia about her lies.",
    "The mystery man remains unidentified.",
    "",
    "Now, the investigation continues...",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    _controller.forward().then((_) {
      if (mounted) {
         Future.delayed(const Duration(seconds: 2), () {
           if (mounted) context.go('/messenger'); // Auto proceed
         });
      }
    });

    // Auto scroll logic could be here but simple fade/reveal is better for cinematic feel
  }

  @override
  void dispose() {
    _controller.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Ambience (static or video)
          Container(color: Colors.black),

          // Text Scroll
          Center(
            child: ListView.builder(
              controller: _listController,
              shrinkWrap: true,
              itemCount: recapLines.length,
              itemBuilder: (context, index) {
                final line = recapLines[index];
                // Staggered Fade In
                final start = index / recapLines.length;
                final end = (index + 1) / recapLines.length;
                final opacity = CurvedAnimation(
                  parent: _controller,
                  curve: Interval(start * 0.5, end * 0.8, curve: Curves.easeIn),
                );

                return FadeTransition(
                  opacity: opacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
                    child: Text(
                      line.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: index == 0
                          ? GoogleFonts.michroma(fontSize: 14, color: DreadmoorColors.accentRed, letterSpacing: 2.0)
                          : GoogleFonts.inter(fontSize: 16, color: Colors.white.withOpacity(0.9), height: 1.6),
                    ),
                  ),
                );
              },
            ),
          ),

          // Skip Button
          Positioned(
            bottom: 40,
            right: 40,
            child: TextButton(
              onPressed: () => context.go('/messenger'),
              child: Text(
                "SKIP >>",
                style: GoogleFonts.michroma(fontSize: 10, color: Colors.white.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
