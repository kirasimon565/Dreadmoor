import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Duskwood-style typing indicator.
///
/// Shows a chat bubble aligned left with:
///   • Sender name label above in small caps (matches ChatBubble sender label)
///   • A feather icon + three staggered bouncing dots inside the bubble
///
/// Usage:
///   FeatherTypingIndicator(senderName: 'Amelia Stone')
///   FeatherTypingIndicator(senderName: 'Michael Jones', isSecret: true)
///
/// The old GunTypingIndicator class is kept as an alias so existing
/// call sites compile without changes while you migrate.
class FeatherTypingIndicator extends StatefulWidget {
  final String? senderName;

  /// true → uses the dark-red secret chat bubble colour palette
  final bool isSecret;

  const FeatherTypingIndicator({
    super.key,
    this.senderName,
    this.isSecret = false,
  });

  @override
  State<FeatherTypingIndicator> createState() =>
      _FeatherTypingIndicatorState();
}

class _FeatherTypingIndicatorState extends State<FeatherTypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>>   _anims;

  static const _dotCount     = 3;
  static const _staggerMs    = 160;
  static const _dotSize      = 7.0;
  static const _bounceHeight = 5.0;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(_dotCount, (i) {
      return AnimationController(
        vsync:    this,
        duration: const Duration(milliseconds: 480),
      );
    });

    _anims = _controllers
        .map((c) => Tween<double>(begin: 0, end: -_bounceHeight)
            .animate(CurvedAnimation(
                parent: c, curve: Curves.easeInOut)))
        .toList();

    // Start each dot with a stagger so they ripple left → right
    for (int i = 0; i < _dotCount; i++) {
      Future.delayed(Duration(milliseconds: i * _staggerMs), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    final bubbleBg = widget.isSecret
        ? const Color(0xFF6B0000)
        : dark
            ? const Color(0xFF1C2B35)
            : const Color(0xFFEFEFEF);

    final contentColor = widget.isSecret || dark
        ? Colors.white.withOpacity(0.72)
        : Colors.black54;

    final nameColor = widget.isSecret || dark
        ? Colors.white.withOpacity(0.42)
        : Colors.black38;

    final name = widget.senderName?.toUpperCase();

    return Padding(
      // Match ChatBubble horizontal margins exactly
      padding: const EdgeInsets.only(
          left: 12, right: 60, top: 2, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [

          // Sender name — mirrors the label in ChatBubble
          if (name != null && name.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 3),
              child: Text(
                name,
                style: GoogleFonts.spaceGrotesk(
                  fontSize:      10,
                  fontWeight:    FontWeight.w700,
                  color:         nameColor,
                  letterSpacing: 0.9,
                ),
              ),
            ),

          // Bubble
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleBg,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(4),
                topRight:    Radius.circular(16),
                bottomLeft:  Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // Feather / quill icon
                Icon(Icons.edit, size: 13, color: contentColor),

                const SizedBox(width: 7),

                // Three staggered bouncing dots
                for (int i = 0; i < _dotCount; i++)
                  AnimatedBuilder(
                    animation: _anims[i],
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _anims[i].value),
                      child: Container(
                        width:  _dotSize,
                        height: _dotSize,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          color: contentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Backwards-compatible alias — existing call sites keep compiling.
/// Gradually replace GunTypingIndicator() with FeatherTypingIndicator()
/// as you update each chat screen.
typedef GunTypingIndicator = FeatherTypingIndicator;
