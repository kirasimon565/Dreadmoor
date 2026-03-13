import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/ui/theme/colors.dart';

class EpisodeTeaserCard extends StatefulWidget {
  final String episodeId;
  final String title;
  final String description;
  final bool isLocked;
  final int progress; // 0 = not started, 1–99 = in progress, 100 = complete
  final VoidCallback? onTap;
  final int index; // for staggered animation

  const EpisodeTeaserCard({
    super.key,
    required this.episodeId,
    required this.title,
    required this.description,
    required this.isLocked,
    required this.progress,
    this.onTap,
    this.index = 0,
  });

  @override
  State<EpisodeTeaserCard> createState() => _EpisodeTeaserCardState();
}

class _EpisodeTeaserCardState extends State<EpisodeTeaserCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 120 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _episodeNumber {
    final num = widget.episodeId.replaceAll(RegExp(r'[^0-9]'), '');
    return num.isNotEmpty ? num.padLeft(2, '0') : '??';
  }

  String get _statusLabel {
    if (widget.isLocked) return 'CLASSIFIED';
    if (widget.progress == 100) return 'COMPLETE';
    if (widget.progress > 0) return 'IN PROGRESS';
    return 'AVAILABLE';
  }

  Color get _statusColor {
    if (widget.isLocked) return DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.4);
    if (widget.progress == 100) return DreadmoorColors.investigatorCyan;
    if (widget.progress > 0) return DreadmoorColors.evidenceRed;
    return DreadmoorColors.investigatorCyan;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: GestureDetector(
            onTap: widget.isLocked ? null : widget.onTap,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: DreadmoorColors.surface(Theme.of(context).brightness),
                  border: Border(
                    left: BorderSide(
                      color: widget.isLocked
                          ? DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.12)
                          : _statusColor,
                      width: _isHovered && !widget.isLocked ? 3 : 2,
                    ),
                    top: BorderSide(
                      color: widget.isLocked
                          ? Colors.transparent
                          : _isHovered
                          ? _statusColor.withOpacity(0.4)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  boxShadow: _isHovered && !widget.isLocked
                      ? [
                          BoxShadow(
                            color: _statusColor.withOpacity(0.12),
                            blurRadius: 24,
                            spreadRadius: 0,
                          ),
                        ]
                      : [],
                ),
                child: Stack(
                  children: [
                    // Scanline texture overlay
                    Positioned.fill(
                      child: CustomPaint(painter: _ScanlinePainter()),
                    ),

                    // Locked overlay
                    if (widget.isLocked)
                      Positioned.fill(
                        child: Container(
                          color: DreadmoorColors.background.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),

                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: episode number + status badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Large episode number
                              Text(
                                _episodeNumber,
                                style: GoogleFonts.michroma(
                                  fontSize: 48,
                                  height: 1.0,
                                  color: widget.isLocked
                                      ? DreadmoorColors.text(Theme.of(context).brightness).withValues(
                                          alpha: 0.25,
                                        )
                                      : _statusColor.withOpacity(0.18),
                                  letterSpacing: -2,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Status badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _statusColor.withValues(
                                            alpha: widget.isLocked ? 0.4 : 0.7,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _statusLabel,
                                        style: GoogleFonts.michroma(
                                          fontSize: 9,
                                          letterSpacing: 2.5,
                                          color: _statusColor.withValues(
                                            alpha: widget.isLocked ? 0.5 : 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Episode title
                                    Text(
                                      widget.isLocked
                                          ? '??? ?????'
                                          : widget.title,
                                      style: GoogleFonts.michroma(
                                        fontSize: 15,
                                        letterSpacing: 1.5,
                                        color: widget.isLocked
                                            ? DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.16)
                                            : DreadmoorColors.text(Theme.of(context).brightness),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Locked icon / play icon
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Icon(
                                  widget.isLocked
                                      ? Icons.lock_outline
                                      : widget.progress == 100
                                      ? Icons.replay_rounded
                                      : Icons.play_arrow_rounded,
                                  color: widget.isLocked
                                      ? DreadmoorColors.text(Theme.of(context).brightness).withValues(
                                          alpha: 0.3,
                                        )
                                      : _statusColor.withOpacity(0.8),
                                  size: 22,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Divider line
                          Container(
                            height: 1,
                            color: widget.isLocked
                                ? DreadmoorColors.text(Theme.of(context).brightness).withValues(
                                    alpha: 0.12,
                                  )
                                : DreadmoorColors.text(Theme.of(context).brightness).withValues(
                                    alpha: 0.2,
                                  ),
                          ),

                          const SizedBox(height: 12),

                          // Description
                          Text(
                            widget.isLocked
                                ? 'INTEL LOCKED. CLEARANCE REQUIRED TO ACCESS THIS EPISODE.'
                                : widget.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.6,
                              color: widget.isLocked
                                  ? DreadmoorColors.text(Theme.of(context).brightness).withValues(
                                      alpha: 0.35,
                                    )
                                  : DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.7),
                              letterSpacing: widget.isLocked ? 1.2 : 0.2,
                            ),
                          ),

                          // Progress bar (only if started and not locked)
                          if (!widget.isLocked && widget.progress > 0) ...[
                            const SizedBox(height: 16),
                            _ProgressBar(
                              progress: widget.progress,
                              color: _statusColor,
                            ),
                          ],

                          // Coming soon teaser (locked)
                          if (widget.isLocked) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  color: DreadmoorColors.evidenceRed.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'COMING SOON',
                                  style: GoogleFonts.michroma(
                                    fontSize: 9,
                                    letterSpacing: 3,
                                    color: DreadmoorColors.evidenceRed.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int progress; // 0–100
  final Color color;

  const _ProgressBar({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESS',
              style: GoogleFonts.michroma(
                fontSize: 8,
                letterSpacing: 2,
                color: DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.4),
              ),
            ),
            Text(
              progress == 100 ? 'COMPLETE' : '$progress%',
              style: GoogleFonts.michroma(
                fontSize: 8,
                letterSpacing: 1.5,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRect(
          child: Stack(
            children: [
              // Track
              Container(
                height: 2,
                color: DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.06),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: progress / 100.0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
