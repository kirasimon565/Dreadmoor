import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/state/game_state.dart';
import '../theme/colors.dart';

class ChoiceOverlay extends ConsumerWidget {
  const ChoiceOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = ref.watch(waitingForChoiceProvider);
    if (!waiting) return const SizedBox.shrink();

    final scheduler = ref.read(globalSchedulerProvider);
    final choices = scheduler.getCurrentChoices();
    if (choices == null || choices.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              border: Border(top: BorderSide(color: DreadmoorColors.accentCyan.withOpacity(0.15), width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHOOSE YOUR RESPONSE', style: GoogleFonts.michroma(fontSize: 10, letterSpacing: 2, color: DreadmoorColors.accentCyan)),
                const SizedBox(height: 12),
                ...choices.map(
                  (choice) => _ChoiceButton(
                    text: choice.text,
                    onTap: () => scheduler.submitChoice(choice.jumpto),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatefulWidget {
  const _ChoiceButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  State<_ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<_ChoiceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(_pressed ? 0.2 : 0.08), width: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(widget.text, style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.75), letterSpacing: 0.3, height: 1.4)),
      ),
    );
  }
}
