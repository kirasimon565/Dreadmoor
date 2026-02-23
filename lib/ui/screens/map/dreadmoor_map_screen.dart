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

          _Header(onBack: () {
            HapticFeedback.selectionClick();
            context.pop();
          }),
        ],
      ),
    );
  }
}

// ── Map view ──────────────────────────────────────────────────────────────

class _MapView extends StatelessWidget {
  final Set<String> unlockedFlags;
  const _MapView({required this.unlockedFlags});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      boundaryMargin: const EdgeInsets.all(60),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // ✅ No fixed canvas — the map image fills available space
          // naturally. LayoutBuilder gives us the rendered size so pins
          // can be placed as fractions of actual pixels.
          return Stack(
            children: [
              // Map image — sizes itself to its intrinsic dimensions
              Image.asset(
                'assets/map/dreadmore_map.png',
                fit: BoxFit.contain,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
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

              // Grain overlay
              IgnorePointer(
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset(
                    'assets/ui/glitch_overlay.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),

              // ✅ Pins use a separate widget that reads the image's
              // actual rendered size via a post-frame callback
              _PinLayer(
                locations: allMapLocations,
                unlockedFlags: unlockedFlags,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Pin layer — measures the image then lays out pins ─────────────────────

class _PinLayer extends StatefulWidget {
  final List<MapLocation> locations;
  final Set<String> unlockedFlags;

  const _PinLayer({
    required this.locations,
    required this.unlockedFlags,
  });

  @override
  State<_PinLayer> createState() => _PinLayerState();
}

class _PinLayerState extends State<_PinLayer> {
  // Actual rendered size of the map image — null until measured
  Size? _imageSize;
  final _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Measure after first frame when the image has been laid out
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final box =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    if (size != _imageSize) {
      setState(() => _imageSize = size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Invisible key holder so we can measure the image size
        Image.asset(
          'assets/map/dreadmore_map.png',
          key: _imageKey,
          fit: BoxFit.contain,
          width: double.infinity,
          // Fully transparent — the real image is drawn in the parent
          color: Colors.transparent,
          colorBlendMode: BlendMode.multiply,
          errorBuilder: (_, __, ___) => const SizedBox(),
        ),

        // Only render pins once we know the rendered image size
        if (_imageSize != null)
          for (final loc in widget.locations)
            _MapPin(
              location: loc,
              unlocked: loc.requiredFlag == null ||
                  widget.unlockedFlags.contains(loc.requiredFlag),
              imageSize: _imageSize!,
            ),
      ],
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
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                  onPressed: onBack,
                  tooltip: 'Back',
                ),
                const SizedBox(width: 4),
                Text(
                  "DREADMOOR",
                  style: GoogleFonts.michroma(
                      fontSize: 15,
                      color: Colors.white,
                      letterSpacing: 3.0),
                ),
                const Spacer(),
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
  final Size imageSize; // actual rendered px size of the map image

  const _MapPin({
    required this.location,
    required this.unlocked,
    required this.imageSize,
  });

  @override
  State<_MapPin> createState() => _MapPinState();
}

class _MapPinState extends State<_MapPin> with SingleTickerProviderStateMixin {
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
    _pulseScale = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
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
    final w = widget.imageSize.width;
    final h = widget.imageSize.height;

    // ✅ Pins placed as fractions of the ACTUAL rendered image size —
    // no hardcoded canvas needed. Correct at every screen size and zoom.
    return Positioned(
      left: w * loc.x - 18,
      top: h * loc.y - 44,
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
          scale: _pressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pin + pulse ring
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (unlocked)
                      AnimatedBuilder(
                        animation: _pulseScale,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseScale.value,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: DreadmoorColors.accentRed.withOpacity(
                                  (1.0 - _pulseController.value) * 0.4),
                            ),
                          ),
                        ),
                      ),
                    Icon(
                      unlocked
                          ? Icons.location_on_rounded
                          : Icons.location_off_rounded,
                      color: unlocked
                          ? DreadmoorColors.accentRed
                          : Colors.grey.shade700,
                      size: 30,
                      shadows: unlocked
                          ? [
                              Shadow(
                                color: DreadmoorColors.accentRed
                                    .withOpacity(0.6),
                                blurRadius: 10,
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
                  color: Colors.black.withOpacity(0.80),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: unlocked
                        ? DreadmoorColors.accentRed.withOpacity(0.35)
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
                        ? Colors.white.withOpacity(0.9)
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
