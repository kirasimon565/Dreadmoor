import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/ghost_trace_constants.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const TutorialOverlay({super.key, required this.onDismiss});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _step = 0; // 0: scan, 1: trace, 2: reconstruct, 3: win

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addListener(() {
        final val = _controller.value;
        int newStep = 0;
        if (val < 0.25) {
          newStep = 0;
        } else if (val < 0.5) {
          newStep = 1;
        } else if (val < 0.75) {
          newStep = 2;
        } else {
          newStep = 3;
        }
        if (newStep != _step) {
          setState(() => _step = newStep);
        }
      });

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _currentCaption {
    switch (_step) {
      case 0:
        return 'Identify the malicious node';
      case 1:
        return 'Trace the signal path in order';
      case 2:
        return 'Rebuild the signal data';
      case 3:
        return 'Complete the trace';
      default:
        return '';
    }
  }

  Widget _buildDemoContent() {
    return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final val = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Fake Nodes
              if (_step < 2) ...[
                Positioned(
                  top: 50,
                  left: 50,
                  child: _FakeNode(
                      color: GhostTraceColors.nodeNormal, isActive: false),
                ),
                Positioned(
                  top: 50,
                  right: 50,
                  child: _FakeNode(
                      color: (_step == 0 && (val * 10).toInt() % 2 == 0) ||
                              _step > 0
                          ? GhostTraceColors.nodeAttacker
                          : GhostTraceColors.nodeNormal,
                      isActive: true),
                ),
                Positioned(
                  bottom: 50,
                  child: _FakeNode(
                      color: _step == 1 && val > 0.35
                          ? GhostTraceColors.nodeTraced
                          : GhostTraceColors.nodeNormal,
                      isActive: false),
                ),
              ],

              // Fake Edge Tracing
              if (_step == 1)
                Positioned(
                  top: 70,
                  right: 70,
                  child: Container(
                    width: 4,
                    height: (val - 0.25) * 400, // simple line animation
                    color: GhostTraceColors.edgeActive,
                    constraints: const BoxConstraints(maxHeight: 120),
                  ),
                ),

              // Fake Reconstruction
              if (_step == 2)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FakeTile(label: '192', isPlaced: val > 0.55),
                      const SizedBox(width: 8),
                      _FakeTile(label: '168', isPlaced: val > 0.65),
                      const SizedBox(width: 8),
                      _FakeTile(label: '0', isPlaced: val > 0.70),
                    ],
                  ),
                ),

              // Win State
              if (_step == 3)
                Center(
                  child: Icon(
                    Icons.check_circle_outline,
                    color: GhostTraceColors.nodeNormal,
                    size: 80,
                  ),
                ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDismiss, // Any tap dismisses the tutorial
        child: Container(
          color: Colors.black87,
          child: Center(
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: GhostTraceColors.hudDim),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'HOW TO PLAY',
                      style: GoogleFonts.sourceCodePro(
                        color: GhostTraceColors.hudText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),

                  // Demo View
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: GhostTraceColors.background,
                        border: Border.all(color: GhostTraceColors.gridLines),
                      ),
                      child: ClipRect(child: _buildDemoContent()),
                    ),
                  ),

                  // Caption
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _currentCaption,
                      style: GoogleFonts.sourceCodePro(
                        color: GhostTraceColors.hudText,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Dismiss hint
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Tap anywhere to start',
                      style: GoogleFonts.sourceCodePro(
                        color: GhostTraceColors.hudDim,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FakeNode extends StatelessWidget {
  final Color color;
  final bool isActive;

  const _FakeNode({required this.color, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
        border: Border.all(color: color, width: 2),
      ),
      child: isActive
          ? Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            )
          : null,
    );
  }
}

class _FakeTile extends StatelessWidget {
  final String label;
  final bool isPlaced;

  const _FakeTile({required this.label, required this.isPlaced});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isPlaced ? GhostTraceColors.nodeNormal.withOpacity(0.2) : Colors.transparent,
        border: Border.all(color: isPlaced ? GhostTraceColors.nodeNormal : GhostTraceColors.hudDim),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          isPlaced ? label : '?',
          style: GoogleFonts.sourceCodePro(
            color: isPlaced ? GhostTraceColors.hudText : GhostTraceColors.hudDim,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}