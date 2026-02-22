import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/investigation_state.dart';
import '../../theme/colors.dart';

class EvidenceDetailScreen extends ConsumerWidget {
  final String evidenceId;

  const EvidenceDetailScreen({super.key, required this.evidenceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evidence = allEvidence.firstWhere((e) => e.id == evidenceId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.asset(evidence.imagePath, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                bottom: 12,
                left: 16,
                right: 16,
              ),
              color: Colors.black.withOpacity(0.75),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      evidence.title,
                      style: GoogleFonts.michroma(
                        fontSize: 14,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
