import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/map_state.dart';
import '../../theme/colors.dart';
import 'location_detail_sheet.dart';

class DreadmoorMapScreen extends ConsumerWidget {
  const DreadmoorMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedAsync = ref.watch(unlockedLocationsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Map content ─────────────────────────────────────────────
          unlockedAsync.when(
            data: (unlockedFlags) => _MapView(unlockedFlags: unlockedFlags),
            loading: () => const Center(
              child: CircularProgressIndicator(
                  color: DreadmoorColors.accentCyan),
            ),
            error: (e, _) => Center(
              child: Text(
                "MAP UNAVAILABLE",
                style: GoogleFonts.michroma(
                  color: DreadmoorColors.accentRed,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),

          // ── Fixed header (outside InteractiveViewer so it stays put) ──
          _Header(onBack: () {
            HapticFeedback.selectionClick();
            context.pop();
          }),
        ],
      ),
    );
  }
}

// ── Map view with InteractiveViewer ───────────────────────────────────────

class _MapView extends StatelessWidget {
  final Set<String> unlockedFlags;
  const _MapView({required this.unlockedFlags});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.6,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(80),
      child: SizedBox(
        // ✅ Fixed intrinsic size for the map — pins are positioned
        // relative to this fixed canvas, not the viewport.
        // This means pin positions stay correct at any zoom level.
        width: 1200,
        height: 900,
        child: Stack(
          children: [
            // Map image fills the fixed canvas
            Positioned.fill(
              child: Image.asset(
                'assets/map/dreadmore_map.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF0D0D0D),
                  child: Center(
                    child: Text(
                      "MAP LOADING...",
                      style: GoogleFonts.michroma(
                        color: Colors.white.withOpacity(0.15),
                        letterSpacing: 3.0,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Grain overlay on map
            IgnorePointer(
              child: Opacity(
                opacity: 0.06,
                child: Image.asset(
                  'assets/ui/glitch_overlay.png',
                  fit: BoxFit.cover,
                  width: 1200,
                  height: 900,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),

            // Map pins — positioned on the fixed 1200×900 canvas
            for (final loc in allMapLocations)
              _MapPin(
                location: loc,
                // ✅ null requiredFlag = always unlocked
                unlocked: loc.requiredFlag == null ||
                    unlockedFlags.contains(loc.requiredFlag),
                canvasWidth: 1200,
                canvasHeight: 900,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.only(
              top: topPadding + 8,
              bottom: 10,
              left: 8,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.07),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: onBack,
                  tooltip: 'Back',
                ),
                const SizedBox(width: 4),
                Text(
                  "DREADMOOR",
                  style: GoogleFonts.michroma(
                    fontSize: 15,
                    color: Colors.white,
                    letterSpacing: 3.0,
                  ),
                ),
                const Spacer(),
                // Zoom hint
                Text(
                  "PINCH TO ZOOM",
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.25),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Map pin ───────────────────────────────────────────────────────────────

class _MapPin extends StatefulWidget {
  final MapLocation location;
  final bool unlocked;
  final double canvasWidth;
  final double canvasHeight;

  const _MapPin({
    required this.location,
    required this.unlocked,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  State<_MapPin> createState() => _MapPinState();
}

class _MapPinState extends State<_MapPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    // Only pulse unlocked locations
    if (widget.unlocked) _pulseController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    final unlocked = widget.unlocked;

    // ✅ Pin position: x/y are 0.0–1.0 fractions of the fixed canvas
    return Positioned(
      left: widget.canvasWidth * loc.x - 16,
      top: widget.canvasHeight * loc.y - 40,
      child: GestureDetector(
        onTapDown: unlocked ? (_) => setState(() => _pressed = true) : null,
        onTapUp: unlocked
            ? (_) {
                setState(() => _pressed = false);
                HapticFeedback.selectionClick();
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => LocationDetailSheet(location: loc),
                );
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pin with pulse ring
              SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulse ring (unlocked only)
                    if (unlocked)
                      AnimatedBuilder(
                        animation: _pulseScale,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseScale.value,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: DreadmoorColors.accentRed.withOpacity(
                                  (1.0 - _pulseController.value) * 0.35),
                            ),
                          ),
                        ),
                      ),

                    // Pin icon
                    Icon(
                      unlocked
                          ? Icons.location_on_rounded
                          : Icons.location_off_rounded,
                      color: unlocked
                          ? DreadmoorColors.accentRed
                          : Colors.grey.shade700,
                      size: 28,
                      shadows: unlocked
                          ? [
                              Shadow(
                                color: DreadmoorColors.accentRed
                                    .withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 2),

              // Label
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: unlocked
                        ? DreadmoorColors.accentRed.withOpacity(0.3)
                        : Colors.white.withOpacity(0.06),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  loc.title.toUpperCase(),
                  style: GoogleFonts.michroma(
                    fontSize: 7,
                    letterSpacing: 1.2,
                    color: unlocked
                        ? Colors.white.withOpacity(0.85)
                        : Colors.white.withOpacity(0.25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
