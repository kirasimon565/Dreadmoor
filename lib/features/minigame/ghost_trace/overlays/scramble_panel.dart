// lib/features/minigame/ghost_trace/overlays/scramble_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/ghost_trace_notifier.dart';
import '../data/ghost_trace_constants.dart';

class ScramblePanel extends ConsumerStatefulWidget {
  const ScramblePanel({super.key});

  @override
  ConsumerState<ScramblePanel> createState() => _ScramblePanelState();
}

class _ScramblePanelState extends ConsumerState<ScramblePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end:   Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideCtrl,
      curve:  Curves.easeOutQuart,
    ));
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(ghostTraceProvider);
    final notifier = ref.read(ghostTraceProvider.notifier);
    final target   = state.target;
    if (target == null) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnim,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0A),
            border: Border(
              top: BorderSide(color: GhostTraceColors.nodeNormal, width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                '> IDENTITY RECONSTRUCTION',
                style: GoogleFonts.sourceCodePro(
                  color:     GhostTraceColors.nodeNormal,
                  fontSize:  11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Arrange the tiles to reconstruct the attacker IP and ID tag.',
                style: GoogleFonts.sourceCodePro(
                  color:     GhostTraceColors.hudDim,
                  fontSize:  10,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 16),

              // IP reconstruction
              Text('IP ADDRESS',
                  style: _labelStyle()),
              const SizedBox(height: 6),
              _TileRow(
                tiles:     state.scrambledIpTiles,
                slots:     state.ipSlots,
                onPlace:   (slot, tile) =>
                    notifier.placeIpTile(slot, tile),
              ),

              const SizedBox(height: 14),

              // Tag reconstruction
              Text('ID TAG',
                  style: _labelStyle()),
              const SizedBox(height: 6),
              _TileRow(
                tiles:   state.scrambledTagTiles,
                slots:   state.tagSlots,
                onPlace: (slot, tile) =>
                    notifier.placeTagTile(slot, tile),
              ),

              const SizedBox(height: 20),

              // Submit
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GhostTraceColors.nodeNormal,
                    side: const BorderSide(
                        color: GhostTraceColors.nodeNormal, width: 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: notifier.submitReconstruction,
                  child: Text(
                    'SUBMIT TRACE',
                    style: GoogleFonts.sourceCodePro(
                      fontSize:  13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.sourceCodePro(
    color:     GhostTraceColors.hudDim,
    fontSize:  9,
    letterSpacing: 1.4,
    fontWeight: FontWeight.w600,
  );
}

// ── DRAGGABLE TILE ROW ────────────────────────────────────────────────────────

class _TileRow extends StatelessWidget {
  final List<String>  tiles;
  final List<String?> slots;
  final void Function(int slot, String tile) onPlace;

  const _TileRow({
    required this.tiles,
    required this.slots,
    required this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Draggable source tiles
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tiles.map((t) => Draggable<String>(
            data: t,
            feedback: _tile(t, dragging: true),
            childWhenDragging: _tile(t, dim: true),
            child: _tile(t),
          )).toList(),
        ),

        const SizedBox(height: 10),

        // Drop targets
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(slots.length, (i) {
            final filled = slots[i];
            return DragTarget<String>(
              builder: (_, accepted, __) {
                return _slot(filled, accepted.isNotEmpty);
              },
              onAccept: (tile) => onPlace(i, tile),
            );
          }),
        ),
      ],
    );
  }

  Widget _tile(String text, {bool dragging = false, bool dim = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:  dim
            ? const Color(0xFF050505)
            : const Color(0xFF0D200D),
        border: Border.all(
          color: dim
              ? GhostTraceColors.hudDim
              : GhostTraceColors.nodeNormal,
          width: dragging ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(3),
        boxShadow: dragging
            ? [const BoxShadow(
                color:     GhostTraceColors.glow,
                blurRadius: 8,
              )]
            : null,
      ),
      child: Text(
        text,
        style: GoogleFonts.sourceCodePro(
          color:    dim
              ? GhostTraceColors.hudDim
              : GhostTraceColors.nodeNormal,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _slot(String? content, bool hovered) {
    return Container(
      width:  44,
      height: 34,
      decoration: BoxDecoration(
        color:  hovered
            ? const Color(0xFF0D200D)
            : const Color(0xFF050505),
        border: Border.all(
          color: hovered
              ? GhostTraceColors.nodeNormal
              : GhostTraceColors.hudDim,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      child: content != null
          ? Text(
              content,
              style: GoogleFonts.sourceCodePro(
                color:    GhostTraceColors.nodeNormal,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            )
          : Text(
              '_',
              style: GoogleFonts.sourceCodePro(
                color:    GhostTraceColors.hudDim,
                fontSize: 13,
              ),
            ),
    );
  }
}
