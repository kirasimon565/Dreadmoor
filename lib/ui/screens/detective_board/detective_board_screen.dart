import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const List<String> _filters = ['ALL', 'PEOPLE', 'FILES', 'LOCATIONS'];

  @override
  Widget build(BuildContext context) {
    final unlockedEvidenceAsync = ref.watch(unlockedEvidenceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Stack(
        children: [
          // ── Corkboard texture ─────────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/detective_board_bg.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.72),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF111111)),
            ),
          ),

          // ── Grain overlay ─────────────────────────────────────────────
          IgnorePointer(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/ui/glitch_overlay.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          Column(
            children: [
              CustomScreenHeader(
                title: "DETECTIVE BOARD",
                onBackPressed: () {
                  HapticFeedback.selectionClick();
                  context.go('/messenger');
                },
              ),

              BoardFilters(
                filters: _filters,
                selectedFilter: _selectedFilter,
                onSelect: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedFilter = val);
                },
              ),

              Expanded(
                child: unlockedEvidenceAsync.when(
                  data: (items) {
                    final filtered = _selectedFilter == 'ALL'
                        ? items
                        : items.where((e) {
                            switch (_selectedFilter) {
                              case 'PEOPLE':
                                return e.type == 'profile';
                              case 'FILES':
                                return e.type == 'diary' ||
                                    e.type == 'document';
                              case 'LOCATIONS':
                                // ✅ Fixed: 'location' not 'photo'
                                return e.type == 'location' ||
                                    e.type == 'photo';
                              default:
                                return true;
                            }
                          }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              color: DreadmoorColors.textMeta.withOpacity(0.4),
                              size: 36,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "NO EVIDENCE FOUND",
                              style: GoogleFonts.michroma(
                                fontSize: 11,
                                color: DreadmoorColors.textMeta,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _BoardItem(
                          item: item,
                          onTap: () {
                            if (item.isLocked) return;
                            HapticFeedback.selectionClick();
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
                    child: CircularProgressIndicator(
                        color: DreadmoorColors.accentCyan),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      "ERROR LOADING BOARD",
                      style: GoogleFonts.michroma(
                        color: DreadmoorColors.accentRed,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Board item card ────────────────────────────────────────────────────────

class _BoardItem extends StatefulWidget {
  final EvidenceItem item;
  final VoidCallback onTap;

  const _BoardItem({required this.item, required this.onTap});

  @override
  State<_BoardItem> createState() => _BoardItemState();
}

class _BoardItemState extends State<_BoardItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isLocked = item.isLocked;

    return GestureDetector(
      onTapDown: isLocked ? null : (_) => setState(() => _pressed = true),
      onTapUp: isLocked
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          // ✅ clipBehavior.none so the pin renders above card bounds
          clipBehavior: Clip.none,
          children: [
            // ── Card body ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.65),
                    blurRadius: 12,
                    offset: const Offset(3, 6),
                  ),
                ],
                border: Border.all(
                  color: isLocked
                      ? Colors.white.withOpacity(0.04)
                      : Colors.white.withOpacity(0.09),
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    // Card content
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TypeBadge(item.type),
                          const Spacer(),

                          // Recovery bar for diary items
                          if (item.type == 'diary' &&
                              item.recoveryPercent != null) ...[
                            _RecoveryBar(percent: item.recoveryPercent!),
                            const SizedBox(height: 8),
                          ],

                          Text(
                            item.title,
                            style: GoogleFonts.michroma(
                              fontSize: 11,
                              color: isLocked
                                  ? Colors.white.withOpacity(0.25)
                                  : DreadmoorColors.textPrimary,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // ✅ Blur overlay for locked items
                    if (isLocked)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                            child: Container(
                              color: Colors.black.withOpacity(0.55),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock_outline_rounded,
                                      color: DreadmoorColors.accentRed
                                          .withOpacity(0.6),
                                      size: 22,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "LOCKED",
                                      style: GoogleFonts.michroma(
                                        fontSize: 8,
                                        color: DreadmoorColors.accentRed
                                            .withOpacity(0.5),
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Pin ───────────────────────────────────────────────
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLocked
                        ? Colors.grey.shade700
                        : DreadmoorColors.accentRed,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
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
      ),
    );
  }
}

// ── Recovery bar ───────────────────────────────────────────────────────────

class _RecoveryBar extends StatelessWidget {
  final double percent; // 0.0 to 1.0

  const _RecoveryBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "RECOVERY",
              style: GoogleFonts.inter(
                fontSize: 7,
                color: DreadmoorColors.accentRed.withOpacity(0.7),
                letterSpacing: 1.2,
              ),
            ),
            Text(
              "${(percent * 100).toInt()}%",
              style: GoogleFonts.inter(
                fontSize: 7,
                color: DreadmoorColors.accentRed.withOpacity(0.9),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: Colors.white.withOpacity(0.08),
          color: DreadmoorColors.accentRed,
          minHeight: 2,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}

// ── Type badge ─────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge(this.type);

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'diary' => DreadmoorColors.accentCyan,
      'photo' || 'location' => Colors.amber,
      'document' => Colors.blueGrey,
      'profile' => Colors.purpleAccent,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withOpacity(0.25), width: 0.5),
      ),
      child: Text(
        type.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
