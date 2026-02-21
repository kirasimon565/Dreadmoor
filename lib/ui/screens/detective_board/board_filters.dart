import 'package:flutter/material.dart';
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
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                filter.toUpperCase(),
                style: GoogleFonts.michroma(
                  fontSize: 10,
                  color: isSelected ? Colors.black : DreadmoorColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onSelect(filter),
              backgroundColor: Colors.transparent,
              selectedColor: DreadmoorColors.accentCyan,
              checkmarkColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? DreadmoorColors.accentCyan : Colors.white.withOpacity(0.2),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
