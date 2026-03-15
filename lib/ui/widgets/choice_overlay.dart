import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/state/player_state.dart';
import 'package:dreadmoor/core/models/script_models.dart';

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
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sheetAnim, curve: Curves.easeOutQuart));
    _fadeAnim =
        CurvedAnimation(parent: _sheetAnim, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _sheetAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waiting = ref.watch(waitingForChoiceProvider);
    final player  = ref.watch(playerStateProvider);

    if (waiting) {
      _sheetAnim.forward();
    } else {
      _sheetAnim.reverse();
    }

    return Stack(
      children: [
        // ── CHOICE SHEET ────────────────────────────────────────────────
        if (waiting)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _ChoiceSheet(player: player),
              ),
            ),
          ),

        // ── INPUT BAR ───────────────────────────────────────────────────
        if (!waiting)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _InputBar(),
          ),
      ],
    );
  }
}

// ── INPUT BAR ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 16),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFF4E6470),
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
                  color: Colors.white.withOpacity(0.60),
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Consumer(
                builder: (context, ref, _) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(globalSchedulerProvider).resume();
                    },
                    child: SizedBox(
                      width: 42, height: 42,
                      child: Image.asset(
                        'assets/ui/quill_red.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.edit, color: Color(0xFFCC2A2A), size: 26),
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

class _ChoiceSheet extends ConsumerStatefulWidget {
  final dynamic player;
  const _ChoiceSheet({required this.player});

  @override
  ConsumerState<_ChoiceSheet> createState() => _ChoiceSheetState();
}

class _ChoiceSheetState extends ConsumerState<_ChoiceSheet> {
  /// FIX: local tapped guard per sheet render.
  /// Once tapped, the buttons dim and ignore further input until
  /// the scheduler advances to the next node (which rebuilds the sheet).
  /// This prevents duplicates even when the story stalls.
  bool _tapped = false;

  @override
  Widget build(BuildContext context) {
    final bottomPad    = MediaQuery.of(context).padding.bottom;
    final scheduler    = ref.read(globalSchedulerProvider);
    final activeNodeId = ref.watch(activeNodeIdProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── SHEET ──────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, 28, 20, bottomPad + 20),
          decoration: const BoxDecoration(
            color: Color(0xFFF0EEEA),
            borderRadius: BorderRadius.only(
              topLeft:  Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: FutureBuilder(
            future: ref.read(databaseProvider).getNextNode(activeNodeId ?? ''),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox(height: 60);
              }

              final choices = DreadmoorNode.fromDb(snapshot.data!).choices;

              if (choices.isEmpty) {
                return const SizedBox(height: 60);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: choices.map((choice) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ChoiceRow(
                      text:     choice.text,
                      disabled: _tapped,
                      onTap: () {
                        if (_tapped) return;
                        setState(() => _tapped = true);
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

        // ── FLOATING PLAYER AVATAR ─────────────────────────────────────
        Positioned(
          top: -56, right: 16,
          child: Container(
            width: 112, height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFFF0EEEA), width: 4),
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
                widget.player?.profilePath
                    ?? 'assets/characters/player_default.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFD4B896),
                  child: const Icon(
                      Icons.person, color: Colors.white54, size: 52),
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
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 13, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border:
                      Border.all(color: Colors.black, width: 1.5),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  text.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 44, height: 44,
              child: Image.asset(
                'assets/ui/quill_black.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.edit, color: Colors.black87, size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
