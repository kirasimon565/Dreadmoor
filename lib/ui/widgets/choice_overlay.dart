import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/theme/colors.dart';

class ChoiceOverlay extends ConsumerWidget {
  const ChoiceOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = ref.watch(waitingForChoiceProvider);
    if (!waiting) return const SizedBox.shrink();

    final scheduler = ref.read(globalSchedulerProvider);
    final choices = scheduler.getCurrentChoices();
    if (choices == null || choices.isEmpty) return const SizedBox.shrink();

    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final dy = reduceMotion ? 0.0 : (1 - value) * 24;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
            );
          },
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  border: Border(
                    top: BorderSide(
                      color: DreadmoorColors.accentCyan.withOpacity(0.18),
                      width: 0.6,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHOOSE YOUR RESPONSE',
                      style: GoogleFonts.michroma(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: DreadmoorColors.accentCyan,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...choices.map(
                      (choice) => _ChoiceButton(
                        text: choice.text,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          scheduler.submitChoice(choice.jumpto);
                        },
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

class _ChoiceButton extends StatefulWidget {
  const _ChoiceButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  State<_ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<_ChoiceButton> {
  bool _pressed = false;
  bool _locked = false;

  void _handleTap() {
    if (_locked) return;
    setState(() => _locked = true);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _pressed
              ? Colors.white.withOpacity(0.06)
              : Colors.white.withOpacity(0.02),
          border: Border.all(
            color: _pressed
                ? DreadmoorColors.accentCyan.withOpacity(0.35)
                : Colors.white.withOpacity(0.1),
            width: 0.6,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          widget.text,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 0.3,
            height: 1.4,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
