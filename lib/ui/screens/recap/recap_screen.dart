import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/state/recap_state.dart';
import '../../theme/colors.dart';

class RecapScreen extends ConsumerStatefulWidget {
  final String episodeId;

  const RecapScreen({super.key, required this.episodeId});

  @override
  ConsumerState<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends ConsumerState<RecapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    context.go('/messenger');
  }

  @override
  Widget build(BuildContext context) {
    final recapAsync = ref.watch(recapProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Noir Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                radius: 1.4,
                colors: [Colors.transparent, Colors.black],
              ),
            ),
          ),

          recapAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: DreadmoorColors.accentRed)),
            error: (e, _) => Center(child: Text("RECAP ERROR", style: GoogleFonts.michroma(color: Colors.red))),
            data: (lines) {
              return Center(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
                  itemCount: lines.length,
                  itemBuilder: (context, index) {
                    final start = index / lines.length;
                    final end = (index + 1) / lines.length;

                    final opacity = CurvedAnimation(
                      parent: _controller,
                      curve: Interval(start * 0.7, end * 0.9, curve: Curves.easeIn),
                    );

                    return FadeTransition(
                      opacity: opacity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          lines[index].toUpperCase(),
                          textAlign: TextAlign.center,
                          style: index == 0
                              ? GoogleFonts.michroma(fontSize: 14, letterSpacing: 3, color: DreadmoorColors.accentRed)
                              : GoogleFonts.inter(fontSize: 16, color: Colors.white.withOpacity(0.9), height: 1.6),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          Positioned(
            bottom: 32,
            right: 24,
            child: TextButton(
              onPressed: _continue,
              child: Text(
                "SKIP ▶",
                style: GoogleFonts.michroma(fontSize: 11, letterSpacing: 2, color: Colors.white.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
