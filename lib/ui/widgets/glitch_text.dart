import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class GlitchText extends StatefulWidget {
  const GlitchText({
    super.key,
    required this.text,
    required this.style,
    this.glitchIntensity = 0.4,
    this.enableColorFlicker = true,
  });

  final String text;
  final TextStyle style;
  final double glitchIntensity;
  final bool enableColorFlicker;

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText> {
  final _random = Random();
  Timer? _timer;
  late String _rendered;
  Color? _flickerColor;

  @override
  void initState() {
    super.initState();
    _rendered = widget.text;
    _schedule();
  }

  @override
  void didUpdateWidget(covariant GlitchText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _rendered = widget.text;
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 5 + _random.nextInt(12)), _glitchOnce);
  }

  void _glitchOnce() {
    if (!mounted || widget.text.isEmpty) return;

    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) return;

    final chars = widget.text.split('');
    final base = 1 + _random.nextInt(3);
    final count = (base * widget.glitchIntensity.clamp(0, 1))
        .round()
        .clamp(1, chars.length);

    for (var i = 0; i < count; i++) {
      final idx = _random.nextInt(chars.length);
      chars[idx] = _random.nextBool() ? '▓' : '▒';
    }

    setState(() {
      _rendered = chars.join();
      if (widget.enableColorFlicker) {
        _flickerColor = Colors.white.withOpacity(0.7);
      }
    });

    Timer(const Duration(milliseconds: 90), () {
      if (!mounted) return;
      setState(() {
        _rendered = widget.text;
        _flickerColor = null;
      });
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _rendered,
      style: widget.style.copyWith(color: _flickerColor ?? widget.style.color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
