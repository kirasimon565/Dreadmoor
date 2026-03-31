// lib/features/minigame/tracecore/ui/widgets/selectable_tile.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectableTile extends StatelessWidget {
  final String  label;
  final bool    isSelected;
  final VoidCallback onTap;

  const SelectableTile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin:  const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:        isSelected
              ? const Color(0xFF003A00)
              : const Color(0xFF0A0A0A),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00FF41)
                : const Color(0xFF1A3A1A),
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size:  14,
              color: isSelected
                  ? const Color(0xFF00FF41)
                  : const Color(0xFF1A4A1A),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.sourceCodePro(
                  fontSize:  12,
                  color:     isSelected
                      ? const Color(0xFF00FF41)
                      : const Color(0xFF4A7A4A),
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
