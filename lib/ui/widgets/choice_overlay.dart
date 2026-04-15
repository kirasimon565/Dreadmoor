import 'dart:async';
import 'dart:io';

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
  bool _isExpanded = false;
  late final AnimationController _anim;
  late final Animation<double> _expandAnim;

  Timer? _blinkTimer;
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _expandAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOutQuart);
    _startBlinkTimer();
  }

  void _startBlinkTimer() {
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      setState(() {
        _showCursor = !_showCursor;
      });
    });
  }

  void _stopBlinkTimer() {
    _blinkTimer?.cancel();
    _showCursor = false;
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!_isExpanded) {
      HapticFeedback.selectionClick();
      _stopBlinkTimer();
      setState(() {
        _isExpanded = true;
      });
      ref.read(isChoiceOverlayExpandedProvider.notifier).setExpanded(true);
      _anim.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final waiting = ref.watch(waitingForChoiceProvider);
    final player = ref.watch(playerStateProvider);
    final bp = MediaQuery.of(context).padding.bottom;

    if (!waiting && _isExpanded) {
      // Begin retraction if state changed from waiting to not-waiting externally (e.g. choice selected)
      ref.read(isChoiceOverlayExpandedProvider.notifier).setExpanded(false);
      _anim.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isExpanded = false;
          });
          _startBlinkTimer();
        }
      });
    }

    return GestureDetector(
        onTap: () {
          if (!waiting) {
            // Normal tap when not waiting for choices: resume scheduler
            HapticFeedback.lightImpact();
            ref.read(globalSchedulerProvider).resume();
          } else {
            // Tap when choices available: expand to show choices
            _handleTap();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _expandAnim,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // ── EXPANDED NOTCH PANEL ──────────────────────────────────────────
                // This panel takes natural layout space that animates from 0 to its full size.
                // We use SizeTransition to safely animate its natural height pushing the list up
                // without clipping the top portion (the protruding avatar).
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizeTransition(
                    sizeFactor: _expandAnim,
                    axisAlignment: 1.0,
                    child: _ChoiceSheetNotch(player: player),
                  ),
                ),

                // ── IDLE CAPSULE ────────────────────────────────────────────────
                // We fade it out and translate it down slightly.
                if (_expandAnim.value < 1.0)
                  FractionalTranslation(
                    translation: Offset(0, _expandAnim.value),
                    child: Opacity(
                      opacity: 1.0 - _expandAnim.value,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, bp + 16),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E4E9)
                                .withOpacity(0.95), // Soft light gray
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5))
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 24),
                              Expanded(
                                child: Text(
                                    waiting ? 'Write message... ${_showCursor ? '|' : ' '}' : 'Write message...',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.black54,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    )),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
                                  ),
                                  child: const Icon(Icons.send,
                                      color: Colors.black87, size: 24),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
    );
  }
}

// ── CONCAVE NOTCH CLIPPER ────────────────────────────────────────────────────────

class _NotchPanelClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double rightInset;

  _NotchPanelClipper({required this.notchRadius, required this.rightInset});

  @override
  Path getClip(Size size) {
    final path = Path();
    final cornerRadius = 24.0;

    // Start at top-left corner
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // Line to the start of the notch
    final notchCenterX = size.width - rightInset - notchRadius;
    final notchRect = Rect.fromCircle(
      center: Offset(notchCenterX, 0),
      radius: notchRadius,
    );

    path.lineTo(notchCenterX - notchRadius, 0);

    path.arcTo(
      notchRect,
      3.1415926535,
      -3.1415926535,
      false,
    );

    // Ensure we only draw the top-right corner if there is space between the notch and the corner
    if (rightInset > cornerRadius) {
      // Line to the top-right corner
      path.lineTo(size.width - cornerRadius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    } else {
       // Notch merges with corner edge, draw a direct point to corner
       path.lineTo(size.width, cornerRadius);
    }


    // Line to bottom-right
    path.lineTo(size.width, size.height);
    // Line to bottom-left
    path.lineTo(0, size.height);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

// ── EXPANDED CHOICE SHEET (WITH NOTCH) ─────────────────────────────────────────

class _ChoiceSheetNotch extends ConsumerStatefulWidget {
  final dynamic player;
  const _ChoiceSheetNotch({required this.player});

  @override
  ConsumerState<_ChoiceSheetNotch> createState() => _ChoiceSheetNotchState();
}

class _ChoiceSheetNotchState extends ConsumerState<_ChoiceSheetNotch> {
  bool _tapped = false;

  @override
  void didUpdateWidget(covariant _ChoiceSheetNotch oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tapped = false;
  }

  @override
  Widget build(BuildContext context) {
    final scheduler = ref.read(globalSchedulerProvider);
    final activeId = ref.watch(activeNodeIdProvider);
    final bp = MediaQuery.of(context).padding.bottom;

    const double avatarDiameter = 62;
    const double notchRadius = 40;
    const double rightInset = 20;

    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The Clipped Panel
          ClipPath(
          clipper: _NotchPanelClipper(
              notchRadius: notchRadius, rightInset: rightInset),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 56, 16,
                bp + 20), // Padding to account for the notch space at top
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEEA), // Elegant white/light gray
            ),
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
                  children: [
                    ...choices.asMap().entries.map((entry) {
                      final index = entry.key;
                      final c = entry.value;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ChoiceRowContent(
                            text: c.text,
                            disabled: _tapped,
                            onTap: () {
                              if (_tapped) return;
                              setState(() => _tapped = true);
                              HapticFeedback.lightImpact();
                              scheduler.submitChoice(c.target, c.text);
                            },
                          ),
                          if (index < choices.length - 1)
                            Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.black.withOpacity(0.08)),
                        ],
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ),

        // The Player Avatar inside the Notch
        Positioned(
          top: -(avatarDiameter / 2),
          left: MediaQuery.of(context).size.width - rightInset - notchRadius - (avatarDiameter / 2),
          child: Container(
            width: avatarDiameter,
            height: avatarDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ClipOval(
              child: Builder(
                builder: (context) {
                  final path = widget.player?.profilePath;
                  if (path != null && path.isNotEmpty) {
                    if (path.startsWith('assets/')) {
                      return Image.asset(
                        path,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFD4B896),
                          child: const Icon(Icons.person, color: Colors.white54, size: 38),
                        ),
                      );
                    } else {
                      return Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFD4B896),
                          child: const Icon(Icons.person, color: Colors.white54, size: 38),
                        ),
                      );
                    }
                  } else {
                    return Image.asset(
                      'assets/characters/player_default.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFD4B896),
                        child: const Icon(Icons.person, color: Colors.white54, size: 38),
                      ),
                    );
                  }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CHOICE TEXT ROW ─────────────────────────────────────────────────────────────

class _ChoiceRowContent extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool disabled;

  const _ChoiceRowContent({
    required this.text,
    required this.onTap,
    this.disabled = false,
  });

  @override
  State<_ChoiceRowContent> createState() => _ChoiceRowContentState();
}

class _ChoiceRowContentState extends State<_ChoiceRowContent> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel:
          widget.disabled ? null : () => setState(() => _pressed = false),
      onTap: widget.disabled ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        color: _pressed ? Colors.black.withOpacity(0.05) : Colors.transparent,
        child: Text(
          widget.text,
          style: GoogleFonts.spectral(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: widget.disabled
                ? Colors.black38
                : Colors.black87, // Dark readable text
            height: 1.4,
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}
