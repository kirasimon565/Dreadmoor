import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class GlitchText extends StatefulWidget {
  const GlitchText({
    super.key,
    required this.text,
    required this.style,
    this.glitchIntensity = 0.4,
  });

  final String text;
  final TextStyle style;
  final double glitchIntensity;

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText> {
  final _random = Random();
  Timer? _timer;
  String _rendered = '';

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
    _timer = Timer(Duration(seconds: 6 + _random.nextInt(15)), _glitchOnce);
  }

  void _glitchOnce() {
    if (!mounted || widget.text.isEmpty) return;

    final chars = widget.text.split('');
    final base = 2 + _random.nextInt(3);
    final count = (base * widget.glitchIntensity.clamp(0, 1)).round().clamp(1, chars.length);
    for (var i = 0; i < count; i++) {
      final idx = _random.nextInt(chars.length);
      chars[idx] = _random.nextBool() ? '▓' : '█';
    }

    setState(() => _rendered = chars.join());

    Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      setState(() => _rendered = widget.text);
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
    return Text(_rendered, style: widget.style);
  }
}
