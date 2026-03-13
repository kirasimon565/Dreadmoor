import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/widgets/custom_screen_header.dart';
import 'package:dreadmoor/ui/widgets/shared_screen_painters.dart'; // FIX: was private classes

class LegalDisclaimerScreen extends StatelessWidget {
  const LegalDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background(Theme.of(context).brightness),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: const ScanlinePainter())),

          Column(
            children: [
              CustomScreenHeader(
                title: 'LEGAL',
                onBackPressed: () => context.pop(),
              ),

              _DocumentStamp(),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _LegalSection(
                        title: 'FICTIONAL DISCLAIMER',
                        index: '01',
                        body:
                            'Dreadmoor: Rebecca Stone Mystery is a work of fiction. '
                            'All names, characters, organizations, locations, and events '
                            'portrayed in this game are either products of the author\'s imagination '
                            'or are used in a fictional manner. Any resemblance to actual persons, '
                            'living or dead, or to real-world events or locations is purely coincidental.',
                      ),
                      const _LegalSection(
                        title: 'INTELLECTUAL PROPERTY',
                        index: '02',
                        body:
                            'All content within this game — including but not limited to storylines, '
                            'dialogue, characters, artwork, audio, music, and visual designs — '
                            'is the intellectual property of BlackMoon Studio unless otherwise stated. '
                            'Unauthorized reproduction, redistribution, or modification of any part '
                            'of this game is prohibited.',
                      ),
                      const _LegalSection(
                        title: 'LIABILITY DISCLAIMER',
                        index: '03',
                        body:
                            'The developers and publishers of this game assume no responsibility '
                            'for any direct or indirect damages arising from the use of this software. '
                            'This game is provided "as is" without warranties of any kind, '
                            'express or implied.',
                      ),
                      const _LegalSection(
                        title: 'DATA & PRIVACY',
                        index: '04',
                        body:
                            'This game stores gameplay progress locally on your device only. '
                            'No personal data is transmitted to external servers. '
                            'Deleting the app or clearing local storage will permanently erase your progress.',
                      ),

                      const SizedBox(height: 40),

                      Center(
                        child: Column(
                          children: [
                            const RedactedBar(width: 200),
                            const SizedBox(height: 16),
                            Text(
                              '© ${DateTime.now().year} BLACKMOON STUDIO',
                              style: GoogleFonts.michroma(
                                fontSize: 9,
                                letterSpacing: 2,
                                color: DreadmoorColors.text(Theme.of(context).brightness).withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ALL RIGHTS RESERVED',
                              style: GoogleFonts.michroma(
                                fontSize: 8,
                                letterSpacing: 2.5,
                                color: DreadmoorColors.text(Theme.of(context).brightness).withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentStamp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        color: Colors.white.withOpacity(0.02),
      ),
      child: Row(
        children: [
          Icon(
            Icons.gavel_rounded,
            size: 13,
            color: DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.4).withOpacity(0.4),
          ),
          const SizedBox(width: 10),
          Text(
            'DOCUMENT REF: BMS-LEGAL-${DateTime.now().year}',
            style: GoogleFonts.sourceCodePro(
              fontSize: 10,
              letterSpacing: 1.5,
              color: DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.4).withOpacity(0.4),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(
                color: DreadmoorColors.investigatorCyan.withOpacity(0.3),
              ),
            ),
            child: Text(
              'OFFICIAL',
              style: GoogleFonts.michroma(
                fontSize: 7,
                letterSpacing: 2,
                color: DreadmoorColors.investigatorCyan.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String title;
  final String index;
  final String body;

  const _LegalSection({
    required this.title,
    required this.index,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                index,
                style: GoogleFonts.michroma(
                  fontSize: 22,
                  color: DreadmoorColors.investigatorCyan.withOpacity(0.1),
                  letterSpacing: -1,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.michroma(
                        fontSize: 10,
                        letterSpacing: 2.5,
                        color: DreadmoorColors.investigatorCyan,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 1,
                      color: DreadmoorColors.investigatorCyan.withOpacity(0.15),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: GoogleFonts.sourceCodePro(
              fontSize: 12,
              height: 1.75,
              color: Colors.white.withOpacity(0.65),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
