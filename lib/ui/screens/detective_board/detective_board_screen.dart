import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/investigation_state.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';
import 'board_filters.dart';

class DetectiveBoardScreen extends ConsumerStatefulWidget {
  const DetectiveBoardScreen({super.key});

  @override
  ConsumerState<DetectiveBoardScreen> createState() =>
      _DetectiveBoardScreenState();
}

class _DetectiveBoardScreenState extends ConsumerState<DetectiveBoardScreen> {
  String _selectedFilter = 'ALL';
  final List<String> _filters = const ['ALL', 'PEOPLE', 'FILES', 'LOCATIONS'];

  @override
  Widget build(BuildContext context) {
    final unlockedEvidenceAsync = ref.watch(unlockedEvidenceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          CustomScreenHeader(
            title: "DETECTIVE BOARD",
            onBackPressed: () => context.go('/messenger'),
          ),
          BoardFilters(
            filters: _filters,
            selectedFilter: _selectedFilter,
            onSelect: (val) => setState(() => _selectedFilter = val),
          ),
          Expanded(
            child: unlockedEvidenceAsync.when(
              data: (items) {
                final filtered = _selectedFilter == 'ALL'
                    ? items
                    : items.where((e) {
                        if (_selectedFilter == 'PEOPLE') return e.type == 'profile';
                        if (_selectedFilter == 'FILES') return e.type == 'diary' || e.type == 'document';
                        if (_selectedFilter == 'LOCATIONS') return e.type == 'photo';
                        return true;
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      "NO EVIDENCE FOUND",
                      style: GoogleFonts.michroma(
                        fontSize: 12,
                        color: DreadmoorColors.textMeta,
                        letterSpacing: 2,
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _BoardItem(
                      item: item,
                      onTap: () {
                        if (item.type == 'diary') {
                          context.push('/board/diary/${item.id}');
                        } else {
                          context.push('/board/evidence/${item.id}');
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: DreadmoorColors.accentCyan),
              ),
              error: (e, _) => Center(
                child: Text(
                  "ERROR LOADING BOARD",
                  style: GoogleFonts.michroma(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardItem extends StatelessWidget {
  final EvidenceItem item;
  final VoidCallback onTap;

  const _BoardItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 10,
                  offset: const Offset(3, 6),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TypeBadge(item.type),
                const Spacer(),
                Text(
                  item.title,
                  style: GoogleFonts.michroma(
                    fontSize: 11,
                    color: DreadmoorColors.textPrimary,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Pin
          Positioned(
            top: -6,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DreadmoorColors.accentRed,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.7),
                      blurRadius: 4,
                      offset: const Offset(1, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge(this.type);

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'diary' => DreadmoorColors.accentCyan,
      'photo' => Colors.amber,
      'document' => Colors.blueGrey,
      'profile' => Colors.purpleAccent,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        type.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
