import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // For BackdropFilter

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
        vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(
            begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _anim, curve: Curves.easeOutQuart));
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
            left: 0, right: 0, bottom: 0,
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                  opacity: _fade,
                  child: _ChoiceSheet(player: player)),
            ),
          ),
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
    final bp = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bp + 16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0), // Soft light gray background
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.30),
                blurRadius: 10, offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 22),
            Expanded(
              child: Text(
                'Write message...', // Placeholder text
                style: GoogleFonts.spectral(
                  color: Colors.black.withOpacity(0.58), // Black placeholder text
                  fontSize: 17,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Consumer(
                builder: (context, ref, _) => GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(globalSchedulerProvider).resume();
                  },
                  child: const SizedBox(
                    width: 40, height: 40,
                    child: Icon(Icons.send, color: Colors.black, size: 24), // Black send arrow icon
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

// ── CHOICE SHEET ──────────────────────────────────────────────────────────────

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
    final bp = MediaQuery.of(context).padding.bottom;
    final scheduler = ref.read(globalSchedulerProvider);
    final activeId = ref.watch(activeNodeIdProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Choice Cards
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bp + 16), // Adjust padding to make it semi-floating
          child: FutureBuilder(
            future: ref
                .read(databaseProvider)
                .getNextNode(activeId ?? ''),
            builder: (context, snap) {
              if (!snap.hasData || snap.data == null) {
                return const SizedBox(height: 48);
              }
              final choices =
                  DreadmoorNode.fromDb(snap.data!).choices;
              if (choices.isEmpty) {
                return const SizedBox(height: 48);
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: choices.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10), // Generous vertical spacing
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
                )).toList(),
              );
            },
          ),
        ),

        // Player Avatar
        Positioned(
          top: -40, // Adjust position to overlap
          right: 14,
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFFF0EEEA), width: 3),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                widget.player?.profilePath
                    ?? 'assets/characters/player_default.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFD4B896),
                  child: const Icon(Icons.person,
                      color: Colors.white54, size: 38),
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

class _ChoiceRow extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool disabled;

  const _ChoiceRow({
    required this.text,
    required this.onTap,
    this.disabled = false,
  });

  @override
  State<_ChoiceRow> createState() => _ChoiceRowState();
}

class _ChoiceRowState extends State<_ChoiceRow> {
  bool _isHovering = false; // For hover effect (desktop/web) or tap highlight

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.disabled ? 0.35 : 1.0,
      child: GestureDetector(
        onTap: widget.disabled ? null : widget.onTap,
        onTapDown: (_) => setState(() => _isHovering = true),
        onTapUp: (_) => setState(() => _isHovering = false),
        onTapCancel: () => setState(() => _isHovering = false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // Rounded rectangular cards
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Soft blur optional
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 20), // Generous padding
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4), // Dark translucent background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHovering ? const Color(0xFFCC2A2A) : Colors.transparent, // Subtle red noir highlight on tap
                  width: 2,
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                widget.text,
                style: GoogleFonts.spectral(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white, // White text
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
