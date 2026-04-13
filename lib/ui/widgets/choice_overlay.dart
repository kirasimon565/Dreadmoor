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
  late final Animation<Offset>   _slide;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _slide = Tween<Offset>(
            begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutQuart));
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
    final player  = ref.watch(playerStateProvider);

    waiting ? _anim.forward() : _anim.reverse();

    if (!waiting) return const SizedBox.shrink();

    return Positioned.fill(
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child:   Align(
            alignment: Alignment.bottomCenter,
            child:     _ChoiceSheet(player: player),
          ),
        ),
      ),
    );
  }
}

// ── CHOICE SHEET ──────────────────────────────────────────────────────────────
// Matches image 4: white panel, floating player avatar top-right,
// choices as clean serif text lines — no borders, no buttons.

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
    final bp       = MediaQuery.of(context).padding.bottom;
    final scheduler = ref.read(globalSchedulerProvider);
    final activeId  = ref.watch(activeNodeIdProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [

        // ── WHITE PANEL ────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(28, 20, 100, bp + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(32),
            ),
          ),
          child: FutureBuilder(
            future: ref
                .read(databaseProvider)
                .getNextNode(activeId ?? ''),
            builder: (context, snap) {
              if (!snap.hasData || snap.data == null) {
                return const SizedBox(height: 60);
              }

              final choices =
                  DreadmoorNode.fromDb(snap.data!).choices;

              if (choices.isEmpty) {
                return const SizedBox(height: 60);
              }

              return Column(
                mainAxisSize:      MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: choices.map((c) {
                  return _ChoiceRow(
                    text:     c.text,
                    disabled: _tapped,
                    onTap: () {
                      if (_tapped) return;
                      setState(() => _tapped = true);
                      HapticFeedback.lightImpact();
                      scheduler.submitChoice(c.target, c.text);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),

        // ── FLOATING PLAYER AVATAR ─────────────────────────────────────
        // Positioned top-right, half-overlapping the panel edge.
        // Matches the large circular avatar in image 4.
        Positioned(
          top:   -44,
          right: 16,
          child: Container(
            width:  88,
            height: 88,
            decoration: BoxDecoration(
              shape:  BoxShape.circle,
              color:  Colors.white,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withOpacity(0.18),
                  blurRadius: 14,
                  offset:     const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                widget.player?.profilePath
                    ?? 'assets/characters/player_default.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE8E8E8),
                  child: const Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 44),
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
// Matches image 4: plain serif text, no borders, no background,
// generous vertical spacing. Tap triggers subtle scale + opacity feedback.

class _ChoiceRow extends StatefulWidget {
  final String       text;
  final VoidCallback onTap;
  final bool         disabled;

  const _ChoiceRow({
    required this.text,
    required this.onTap,
    this.disabled = false,
  });

  @override
  State<_ChoiceRow> createState() => _ChoiceRowState();
}

class _ChoiceRowState extends State<_ChoiceRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
        reverseDuration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   widget.disabled ? null : (_) => _press.forward(),
      onTapUp:     widget.disabled ? null : (_) => _press.reverse(),
      onTapCancel: widget.disabled ? null : ()  => _press.reverse(),
      onTap:       widget.disabled ? null : widget.onTap,
      behavior:    HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity:  widget.disabled ? 0.28 : 1.0,
            child: Text(
              widget.text,
              style: GoogleFonts.spectral(
                fontSize:   22,
                height:     1.35,
                color:      const Color(0xFF1B242C),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
