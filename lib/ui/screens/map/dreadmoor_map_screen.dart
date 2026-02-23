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
      // ✅ Full bleed — map goes edge to edge, UI floats on top
      extendBodyBehindAppBar: true,
      body: unlockedAsync.when(
        data: (unlockedFlags) => _MapScaffold(unlockedFlags: unlockedFlags),
        loading: () => const _LoadingView(),
        error: (e, _) => _ErrorView(),
      ),
    );
  }
}

// ── Full screen map scaffold ───────────────────────────────────────────────

class _MapScaffold extends StatefulWidget {
  final Set<String> unlockedFlags;
  const _MapScaffold({required this.unlockedFlags});

  @override
  State<_MapScaffold> createState() => _MapScaffoldState();
}

class _MapScaffoldState extends State<_MapScaffold> {
  MapLocation? _selectedLocation;
  final _transformController = TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _onPinTapped(MapLocation loc) {
    HapticFeedback.selectionClick();
    setState(() => _selectedLocation = loc);
  }

  void _onDismiss() {
    setState(() => _selectedLocation = null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Full screen interactive map ─────────────────────────────
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.6,
            maxScale: 5.0,
            // No boundary — Google Maps style free pan
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: _MapContent(
              unlockedFlags: widget.unlockedFlags,
              onPinTapped: _onPinTapped,
              selectedId: _selectedLocation?.id,
            ),
          ),
        ),

        // ── Edge vignette (darkens corners like a real map app) ─────
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.45),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),

        // ── Floating top bar ────────────────────────────────────────
        _FloatingTopBar(
          locationCount: allMapLocations
              .where((l) =>
                  l.requiredFlag == null ||
                  widget.unlockedFlags.contains(l.requiredFlag))
              .length,
        ),

        // ── Bottom detail card ──────────────────────────────────────
        if (_selectedLocation != null)
          _FloatingLocationCard(
            location: _selectedLocation!,
            onDismiss: _onDismiss,
          ),

        // ── Zoom controls (bottom-right, like Google Maps) ──────────
        _ZoomControls(controller: _transformController),
      ],
    );
  }
}

// ── Map content (image + pins) ─────────────────────────────────────────────

class _MapContent extends StatefulWidget {
  final Set<String> unlockedFlags;
  final void Function(MapLocation) onPinTapped;
  final String? selectedId;

  const _MapContent({
    required this.unlockedFlags,
    required this.onPinTapped,
    required this.selectedId,
  });

  @override
  State<_MapContent> createState() => _MapContentState();
}

class _MapContentState extends State<_MapContent> {
  Size? _imageSize;
  final _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    if (box.size != _imageSize) setState(() => _imageSize = box.size);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map image fills naturally
        Image.asset(
          'assets/map/dreadmore_map.png',
          key: _imageKey,
          fit: BoxFit.contain,
          width: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: const Color(0xFF0D0D0F),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined,
                      color: Colors.white.withOpacity(0.1), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    "MAP ASSET MISSING",
                    style: GoogleFonts.michroma(
                      color: Colors.white.withOpacity(0.15),
                      fontSize: 10,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Pins — only once image is measured
        if (_imageSize != null)
          for (final loc in allMapLocations)
            _MapPin(
              location: loc,
              unlocked: loc.requiredFlag == null ||
                  widget.unlockedFlags.contains(loc.requiredFlag),
              isSelected: widget.selectedId == loc.id,
              imageSize: _imageSize!,
              onTap: () => widget.onPinTapped(loc),
            ),
      ],
    );
  }
}

// ── Floating top bar ───────────────────────────────────────────────────────

class _FloatingTopBar extends StatelessWidget {
  final int locationCount;
  const _FloatingTopBar({required this.locationCount});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Positioned(
      top: top + 12,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A).withOpacity(0.82),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 0.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Back button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "DREADMOOR",
                        style: GoogleFonts.michroma(
                          fontSize: 13,
                          color: Colors.white,
                          letterSpacing: 3.0,
                        ),
                      ),
                      Text(
                        "$locationCount LOCATIONS ACTIVE",
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: DreadmoorColors.accentCyan.withOpacity(0.7),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Compass indicator
                _CompassDot(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            "N",
            style: GoogleFonts.michroma(
              fontSize: 11,
              color: DreadmoorColors.accentRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Floating location card (replaces bottom sheet) ─────────────────────────

class _FloatingLocationCard extends StatefulWidget {
  final MapLocation location;
  final VoidCallback onDismiss;

  const _FloatingLocationCard({
    required this.location,
    required this.onDismiss,
  });

  @override
  State<_FloatingLocationCard> createState() => _FloatingLocationCardState();
}

class _FloatingLocationCardState extends State<_FloatingLocationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Color get _typeColor {
    return switch (widget.location.type) {
      'crime_scene' => DreadmoorColors.accentRed,
      'witness' => Colors.amber,
      'landmark' => Colors.blueGrey,
      _ => DreadmoorColors.textMeta,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final loc = widget.location;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom + 16,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _typeColor.withOpacity(0.25),
                    width: 0.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: _typeColor.withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Location image strip ─────────────────────────
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 7,
                            child: Image.asset(
                              loc.imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF161616),
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.white.withOpacity(0.1),
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Gradient over image
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFF0A0A0A).withOpacity(0.8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Dismiss button
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: widget.onDismiss,
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    color:
                                        Colors.black.withOpacity(0.5),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color:
                                          Colors.white.withOpacity(0.7),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Type badge
                          if (loc.type != null)
                            Positioned(
                              bottom: 10,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      _typeColor.withOpacity(0.18),
                                  borderRadius:
                                      BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _typeColor.withOpacity(0.4),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  loc.type!
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: _typeColor,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Info + buttons ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.title,
                            style: GoogleFonts.michroma(
                              fontSize: 14,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            loc.description,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                              height: 1.55,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 14),

                          // Action buttons row
                          Row(
                            children: [
                              // View full details
                              Expanded(
                                child: _CardButton(
                                  label: "DETAILS",
                                  icon: Icons.info_outline_rounded,
                                  color: DreadmoorColors.accentCyan,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      isScrollControlled: true,
                                      builder: (_) =>
                                          LocationDetailSheet(location: loc),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              // View evidence
                              Expanded(
                                child: _CardButton(
                                  label: "EVIDENCE",
                                  icon: Icons.folder_open_outlined,
                                  color: _typeColor,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    widget.onDismiss();
                                    context.push(
                                        '/board?filter=LOCATIONS&locationId=${loc.id}');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CardButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CardButton> createState() => _CardButtonState();
}

class _CardButtonState extends State<_CardButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withOpacity(0.18)
              : widget.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.color.withOpacity(_pressed ? 0.55 : 0.25),
            width: 0.7,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: widget.color, size: 14),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: GoogleFonts.michroma(
                fontSize: 9,
                color: widget.color,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Zoom controls ──────────────────────────────────────────────────────────

class _ZoomControls extends StatelessWidget {
  final TransformationController controller;
  const _ZoomControls({required this.controller});

  void _zoom(double factor) {
    final current = controller.value.clone();
    final center = Matrix4.identity()
      ..translate(150.0, 300.0)
      ..scale(factor)
      ..translate(-150.0, -300.0);
    controller.value = center * current;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 16,
      bottom: bottom + 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A).withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ZoomButton(
                  icon: Icons.add_rounded,
                  onTap: () => _zoom(1.25),
                  top: true,
                ),
                Container(height: 0.5, color: Colors.white.withOpacity(0.08)),
                _ZoomButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _zoom(0.8),
                  top: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool top;
  const _ZoomButton(
      {required this.icon, required this.onTap, required this.top});

  @override
  State<_ZoomButton> createState() => _ZoomButtonState();
}

class _ZoomButtonState extends State<_ZoomButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 40,
        height: 40,
        color: _pressed
            ? Colors.white.withOpacity(0.08)
            : Colors.transparent,
        child: Icon(
          widget.icon,
          color: Colors.white.withOpacity(0.6),
          size: 20,
        ),
      ),
    );
  }
}

// ── Map pin — Google Maps style teardrop ───────────────────────────────────

class _MapPin extends StatefulWidget {
  final MapLocation location;
  final bool unlocked;
  final bool isSelected;
  final Size imageSize;
  final VoidCallback onTap;

  const _MapPin({
    required this.location,
    required this.unlocked,
    required this.isSelected,
    required this.imageSize,
    required this.onTap,
  });

  @override
  State<_MapPin> createState() => _MapPinState();
}

class _MapPinState extends State<_MapPin> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.unlocked) _pulse.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _pinColor {
    if (!widget.unlocked) return Colors.grey.shade600;
    return switch (widget.location.type) {
      'crime_scene' => DreadmoorColors.accentRed,
      'witness'     => Colors.amber.shade600,
      'landmark'    => DreadmoorColors.accentCyan,
      _             => Colors.white,
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    final w = widget.imageSize.width;
    final h = widget.imageSize.height;
    final color = _pinColor;
    final selected = widget.isSelected;

    return Positioned(
      // Anchor the bottom-point of the teardrop pin to the location
      left: w * loc.x - (selected ? 22 : 18),
      top: h * loc.y - (selected ? 58 : 48),
      child: GestureDetector(
        onTap: widget.unlocked ? widget.onTap : null,
        child: AnimatedScale(
          scale: selected ? 1.25 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: selected ? 44 : 36,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Teardrop pin ──────────────────────────────────
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulse ring
                    if (widget.unlocked)
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, __) => Transform.scale(
                          scale: 1.0 + _pulse.value * 0.8,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(
                                  (1.0 - _pulse.value) * 0.25),
                            ),
                          ),
                        ),
                      ),

                    // Pin body — teardrop via CustomPaint
                    CustomPaint(
                      painter: _TeardropPainter(
                        color: color,
                        selected: selected,
                        locked: !widget.unlocked,
                      ),
                      size: Size(selected ? 44 : 36, selected ? 52 : 44),
                    ),

                    // Icon inside the pin
                    Positioned(
                      top: selected ? 10 : 8,
                      child: Icon(
                        widget.unlocked
                            ? _typeIcon(loc.type)
                            : Icons.lock_outline_rounded,
                        color: widget.unlocked
                            ? Colors.white
                            : Colors.white.withOpacity(0.35),
                        size: selected ? 16 : 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                // ── Label ──────────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withOpacity(0.2)
                        : Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: selected
                          ? color.withOpacity(0.5)
                          : Colors.white.withOpacity(0.08),
                      width: 0.6,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    loc.title,
                    style: GoogleFonts.michroma(
                      fontSize: 6,
                      letterSpacing: 0.8,
                      color: widget.unlocked
                          ? (selected ? color : Colors.white.withOpacity(0.85))
                          : Colors.white.withOpacity(0.2),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String? type) {
    return switch (type) {
      'crime_scene' => Icons.warning_amber_rounded,
      'witness'     => Icons.person_outline_rounded,
      'landmark'    => Icons.home_outlined,
      _             => Icons.place_outlined,
    };
  }
}

// ── Teardrop pin painter ───────────────────────────────────────────────────

class _TeardropPainter extends CustomPainter {
  final Color color;
  final bool selected;
  final bool locked;

  const _TeardropPainter({
    required this.color,
    required this.selected,
    required this.locked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;

    final fillPaint = Paint()
      ..color = locked ? Colors.grey.shade800 : color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(selected ? 0.35 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Teardrop: circle on top, pointed at bottom
    final path = Path();
    // Top circle arc
    path.addArc(
      Rect.fromCircle(center: Offset(r, r), radius: r),
      0,
      3.14159 * 2,
    );

    // Rebuild as teardrop
    final td = Path();
    td.moveTo(r, h); // tip at bottom center
    td.quadraticBezierTo(0, h * 0.65, 0, r);     // left curve to circle
    td.arcTo(
      Rect.fromCircle(center: Offset(r, r), radius: r),
      3.14159,
      -3.14159,
      false,
    );
    td.quadraticBezierTo(w, h * 0.65, r, h);      // right curve to tip
    td.close();

    // Shadow
    canvas.drawShadow(td, Colors.black, selected ? 6 : 3, false);

    canvas.drawPath(td, fillPaint);
    canvas.drawPath(td, strokePaint);

    // Shine highlight at top of circle
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(r * 0.7, r * 0.65), r * 0.22, shinePaint);
  }

  @override
  bool shouldRepaint(_TeardropPainter old) =>
      old.color != color || old.selected != selected || old.locked != locked;
}

// ── Loading and error views ────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: DreadmoorColors.accentCyan),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(
          "MAP UNAVAILABLE",
          style: GoogleFonts.michroma(
            color: DreadmoorColors.accentRed,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}
