import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';

class BoardFilters extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelect;

  const BoardFilters({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(filter);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DreadmoorColors.accentCyan.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? DreadmoorColors.accentCyan.withOpacity(0.6)
                        : Colors.white.withOpacity(0.15),
                    width: 0.7,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: DreadmoorColors.glowCyan.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.michroma(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: isSelected
                        ? DreadmoorColors.accentCyan
                        : DreadmoorColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
