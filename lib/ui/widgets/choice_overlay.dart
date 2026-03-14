import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/state/player_state.dart';
import 'package:dreadmoor/core/models/script_models.dart';
import 'package:dreadmoor/ui/theme/colors.dart';

class ChoiceOverlay extends ConsumerStatefulWidget {
  const ChoiceOverlay({super.key});

  @override
  ConsumerState<ChoiceOverlay> createState() => _ChoiceOverlayState();
}

class _ChoiceOverlayState extends ConsumerState<ChoiceOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheetAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _sheetAnim = AnimationController(
      vsync: this,
      duration: Duration.zero, // Zero duration ensures it paints immediately upon layout
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sheetAnim, curve: Curves.linear));
    _fadeAnim = CurvedAnimation(parent: _sheetAnim, curve: Curves.linear);
  }

  @override
  void dispose() {
    _sheetAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waiting = ref.watch(waitingForChoiceProvider);
    final player = ref.watch(playerStateProvider);

    if (waiting) {
      _sheetAnim.forward();
    } else {
      _sheetAnim.reverse();
    }

    return Stack(
      children: [
        // ── CHOICE SHEET (slides up when waiting) ─────────────────────────
        if (waiting)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _ChoiceSheet(player: player),
              ),
            ),
          ),

        // ── INPUT BAR (visible when NOT waiting) ─────────────────────────
        if (!waiting)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _InputBar(),
          ),
      ],
    );
  }
}

// ── INPUT BAR ─────────────────────────────────────────────────────────────────
// Bluish-grey pill, "Say something..." italic, red quill right.

class _InputBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 16),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: DreadmoorColors.surface(brightness),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                'Say something...',
                style: GoogleFonts.spectral(
                  color: DreadmoorColors.text(brightness).withOpacity(0.60),
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Consumer(
                builder: (context, ref, child) {
                  return GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final scheduler = ref.read(globalSchedulerProvider);
                      final activeNodeId = ref.read(activeNodeIdProvider);

                      if (activeNodeId != null) {
                        final db = ref.read(databaseProvider);
                        final nodeData = await db.getNextNode(activeNodeId);
                        if (nodeData != null) {
                          final node = DreadmoorNode.fromDb(nodeData);
                          if (node.choices.isNotEmpty) {
                            // Automatically submit the first choice if tapped while choices exist
                            // (Though usually this bar is hidden if waitingForChoice is true)
                            final choice = node.choices.first;
                            scheduler.submitChoice(choice.target, choice.text);
                            return;
                          }
                        }
                      }

                      // Advance current non-branching node if one is pending
                      scheduler.resume();
                    },
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: Image.asset(
                        'assets/ui/quill_red.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.edit,
                          color: DreadmoorColors.evidenceRed,
                          size: 26,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CHOICE SHEET ──────────────────────────────────────────────────────────────
// Warm off-white bottom sheet + floating player avatar overlapping top-right.

class _ChoiceSheet extends ConsumerWidget {
  final dynamic player;

  const _ChoiceSheet({required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final brightness = Theme.of(context).brightness;
    final scheduler = ref.read(globalSchedulerProvider);
    final activeNodeId = ref.watch(activeNodeIdProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── SHEET ─────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, 28, 20, bottomPad + 20),
          decoration: BoxDecoration(
            color: DreadmoorColors.surface(brightness),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: FutureBuilder(
            future: ref
                .read(databaseProvider)
                .getNextNode(activeNodeId ?? ''),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox(height: 60);
              final choices =
                  DreadmoorNode.fromDb(snapshot.data!).choices;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: choices.map((choice) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ChoiceRow(
                      text: choice.text,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        scheduler.submitChoice(choice.target, choice.text);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),

        // ── FLOATING PLAYER AVATAR ─────────────────────────────────────────
        Positioned(
          top: -56,
          right: 16,
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DreadmoorColors.surface(brightness), width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                player?.profilePath ?? 'assets/characters/player_default.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: DreadmoorColors.background(brightness),
                  child: Icon(
                    Icons.person,
                    color: DreadmoorColors.text(brightness).withOpacity(0.54),
                    size: 52,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── CHOICE ROW ────────────────────────────────────────────────────────────────

class _ChoiceRow extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _ChoiceRow({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
              decoration: BoxDecoration(
                color: DreadmoorColors.background(brightness),
                border: Border.all(color: DreadmoorColors.divider(brightness), width: 1.5),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                text.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DreadmoorColors.text(brightness),
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 44,
            height: 44,
            child: Image.asset(
              brightness == Brightness.light ? 'assets/ui/quill_red.png' : 'assets/ui/quill_black.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.edit,
                color: DreadmoorColors.text(brightness),
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
