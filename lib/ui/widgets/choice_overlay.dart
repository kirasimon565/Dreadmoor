import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/models/script_models.dart';

class ChoiceOverlay extends ConsumerStatefulWidget {
  const ChoiceOverlay({super.key});

  @override
  ConsumerState<ChoiceOverlay> createState() => _ChoiceOverlayState();
}

class _ChoiceOverlayState extends ConsumerState<ChoiceOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide =
        Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ) // Subtle slide
            .animate(
              CurvedAnimation(parent: _anim, curve: Curves.easeOutQuart),
            );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waiting = ref.watch(waitingForChoiceProvider);
    final player = ref.watch(playerStateProvider);

    waiting ? _anim.forward() : _anim.reverse();

    return Stack(
      children: [
        if (waiting)
          Positioned(
            left: 0,
            right: 0,
            bottom: 80, // Float above input capsule
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: _ChoiceSheet(player: player),
              ),
            ),
          ),
        Positioned(left: 0, right: 0, bottom: 0, child: _InputBar()),
      ],
    );
  }
}

// ── INPUT BAR (FLOATING CAPSULE) ──────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bp = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bp + 16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E4E9).withOpacity(0.95), // Soft light gray
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                'Write message...', // Match spec
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Consumer(
                builder: (context, ref, _) => GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(globalSchedulerProvider).resume();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent, // Arrow directly on capsule
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.black87,
                      size: 24,
                    ), // Black send arrow
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CHOICE CARDS (FLOATING STACK) ─────────────────────────────────────────────────

class _ChoiceSheet extends ConsumerStatefulWidget {
  final dynamic player;
  const _ChoiceSheet({required this.player});

  @override
  ConsumerState<_ChoiceSheet> createState() => _ChoiceSheetState();
}

class _ChoiceSheetState extends ConsumerState<_ChoiceSheet> {
  bool _tapped = false;

  @override
  Widget build(BuildContext context) {
    final scheduler = ref.read(globalSchedulerProvider);
    final activeId = ref.watch(activeNodeIdProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder(
        future: ref.read(databaseProvider).getNextNode(activeId ?? ''),
        builder: (context, snap) {
          if (!snap.hasData || snap.data == null) {
            return const SizedBox(height: 48);
          }
          final choices = DreadmoorNode.fromDb(snap.data!).choices;
          if (choices.isEmpty) {
            return const SizedBox(height: 48);
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: choices
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ChoiceRow(
                      text: c.text,
                      disabled: _tapped,
                      onTap: () {
                        if (_tapped) return;
                        setState(() => _tapped = true);
                        HapticFeedback.lightImpact();
                        scheduler.submitChoice(c.target, c.text);
                      },
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

// ── CHOICE ROW (NOIR CARD) ──────────────────────────────────────────────────────

class _ChoiceRow extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool disabled;

  const _ChoiceRow({
    required this.text,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(
              0xFF161616,
            ).withOpacity(0.85), // Dark translucent
            borderRadius: BorderRadius.circular(
              16,
            ), // Rounded rectangular cards
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: GoogleFonts.spectral(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.95), // White text centered-left
              height: 1.4,
            ),
            textAlign: TextAlign.left, // Centered-left
          ),
        ),
      ),
    );
  }
}
