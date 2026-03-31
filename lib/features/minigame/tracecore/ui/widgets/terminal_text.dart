// lib/features/minigame/tracecore/ui/widgets/terminal_text.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TerminalText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color  color;

  const TerminalText(
    this.text, {
    super.key,
    this.fontSize = 13,
    this.color    = const Color(0xFF00FF41),
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.sourceCodePro(
        fontSize:      fontSize,
        color:         color,
        height:        1.55,
        letterSpacing: 0.4,
      ),
    );
  }
}
