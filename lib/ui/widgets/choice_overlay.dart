import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/ui/theme/colors.dart';

class ChoiceOverlay extends ConsumerStatefulWidget {
  const ChoiceOverlay({super.key});

  @override
  ConsumerState<ChoiceOverlay> createState() => _ChoiceOverlayState();
}

class _ChoiceOverlayState extends ConsumerState<ChoiceOverlay> {
  int? _selectedIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset selection if the choice changes or disappears
    _selectedIndex = null;
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: BoxDecoration(
                  color: DreadmoorColors.surfaceAlt.withOpacity(0.9),
                  border: Border(
                    top: BorderSide(
                      color: DreadmoorColors.borderSubtle.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Player Avatar
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DreadmoorColors.surfaceGlass,
                        border: Border.all(color: DreadmoorColors.borderGlass),
                      ),
                      child: const Icon(Icons.person,
                          color: DreadmoorColors.textSecondary, size: 16),
                    ),
                    const SizedBox(width: 12),

                    // Choices List
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(choices.length, (index) {
                          final choice = choices[index];
                          final isSelected = _selectedIndex == index;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? DreadmoorColors.accentCyan
                                        .withOpacity(0.15)
                                    : DreadmoorColors.surface,
                                border: Border.all(
                                  color: isSelected
                                      ? DreadmoorColors.accentCyan
                                          .withOpacity(0.6)
                                      : DreadmoorColors.borderSubtle,
                                  width: isSelected ? 1.0 : 0.5,
                                ),
                                borderRadius: BorderRadius.circular(
                                    16), // Chat bubble style
                              ),
                              child: Text(
                                choice.text,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: isSelected
                                      ? DreadmoorColors.accentCyan
                                      : Colors.white.withOpacity(0.8),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Send Button
                    GestureDetector(
                      onTap: () {
                        if (_selectedIndex != null) {
                          HapticFeedback.heavyImpact();
                          final selectedChoice = choices[_selectedIndex!];
                          setState(() {
                            _selectedIndex = null; // Reset for next time
                          });
                          scheduler.submitChoice(
                              selectedChoice.jumpto, selectedChoice.text);
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedIndex != null
                              ? DreadmoorColors.accentCyan
                              : DreadmoorColors.surfaceGlass,
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: _selectedIndex != null
                              ? DreadmoorColors.background
                              : DreadmoorColors.textDisabled,
                          size: 18,
                        ),
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
