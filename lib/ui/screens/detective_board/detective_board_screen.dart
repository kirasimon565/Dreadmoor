import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../widgets/custom_screen_header.dart';
import 'board_filters.dart';

class DetectiveBoardScreen extends ConsumerStatefulWidget {
  const DetectiveBoardScreen({super.key});

  @override
  ConsumerState<DetectiveBoardScreen> createState() => _DetectiveBoardScreenState();
}

class _DetectiveBoardScreenState extends ConsumerState<DetectiveBoardScreen> {
  String _selectedFilter = 'ALL';
  final List<String> _filters = ['ALL', 'PEOPLE', 'FILES', 'LOCATIONS'];

  // Dummy data for now
  final List<Map<String, dynamic>> _items = [
    {'id': 'rebecca_diary_1', 'type': 'diary', 'title': 'The Night Before', 'locked': false, 'category': 'FILES'},
    {'id': 'factory_photo', 'type': 'evidence', 'title': 'Factory Entrance', 'locked': true, 'category': 'LOCATIONS'},
    {'id': 'amelia_profile', 'type': 'profile', 'title': 'Amelia', 'locked': false, 'category': 'PEOPLE'},
    {'id': 'deleted_footage', 'type': 'evidence', 'title': 'Deleted Footage', 'locked': true, 'category': 'FILES'},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredItems = _selectedFilter == 'ALL'
        ? _items
        : _items.where((i) => i['category'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Corkboard dark style
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
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return _BoardItem(
                  title: item['title'],
                  type: item['type'],
                  isLocked: item['locked'],
                  onTap: () {
                    if (item['locked']) return;
                    if (item['type'] == 'diary') {
                      context.push('/board/diary/${item['id']}');
                    } else if (item['type'] == 'evidence') {
                      context.push('/board/evidence/${item['id']}');
                    } else if (item['type'] == 'profile') {
                      context.push('/profiles/${item['id']}'); // Assuming ID matches character ID
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardItem extends StatelessWidget {
  final String title;
  final String type;
  final bool isLocked;
  final VoidCallback onTap;

  const _BoardItem({
    required this.title,
    required this.type,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Card Base
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      color: _getTypeColor(type),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                // Title
                Text(
                  title,
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
            top: -4,
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
                    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 2, offset: const Offset(1, 1)),
                  ],
                ),
              ),
            ),
          ),

          // Locked Overlay
          if (isLocked)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: Center(
                      child: Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'diary': return DreadmoorColors.accentCyan;
      case 'evidence': return Colors.amber;
      case 'profile': return Colors.purpleAccent;
      default: return Colors.grey;
    }
  }
}
