import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/state/player_state.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';

class ChoiceOverlay extends ConsumerStatefulWidget {
  const ChoiceOverlay({super.key});

  @override
  ConsumerState<ChoiceOverlay> createState() => _ChoiceOverlayState();
}

class _ChoiceOverlayState extends ConsumerState<ChoiceOverlay> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final waiting = ref.watch(waitingForChoiceProvider);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    
    // Get choices from the scheduler
    final scheduler = ref.read(globalSchedulerProvider);
    final activeNodeId = ref.watch(activeNodeIdProvider);
    
    // We also need the player's avatar for that floating effect
    final player = ref.watch(playerStateProvider);

    // ---------------------------------------------------------
    // RENDER LOGIC 1: Standard "Send Message" Bar (Your 2nd Image)
    // ---------------------------------------------------------
    if (!waiting) {
      return _buildInputBar(context, player, isDark);
    }

    // ---------------------------------------------------------
    // RENDER LOGIC 2: Choice Selection (Your 1st Image)
    // ---------------------------------------------------------
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // FLOATING PLAYER AVATAR (Right side, overlapping)
            Positioned(
              top: -85,
              right: 0,
              child: _buildFloatingAvatar(player),
            ),

            // CHOICE LIST
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder(
                  future: ref.read(databaseProvider).getNextNode(activeNodeId ?? ''),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final node = snapshot.data!;
                    final choices = (DreadmoorNode.fromDb(node)).choices;

                    return Column(
                      children: choices.map((choice) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              // The Sharp Choice Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    scheduler.submitChoice(choice.target, choice.text);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black, width: 1.5),
                                      color: Colors.white,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      choice.text.toUpperCase(),
                                      style: GoogleFonts.spectral(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              // The Black Quill Icon
                              Image.asset(
                                'assets/ui/quill_black.png', 
                                width: 45, 
                                height: 45
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- SUB-WIDGET: FLOATING AVATAR ---
  Widget _buildFloatingAvatar(dynamic player) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: CircleAvatar(
        radius: 65,
        backgroundImage: player?.profilePath != null 
            ? AssetImage(player!.profilePath!) 
            : const AssetImage('assets/characters/player_default.png'),
      ),
    );
  }

  // --- SUB-WIDGET: DEFAULT INPUT BAR (RED FEATHER) ---
  Widget _buildInputBar(BuildContext context, dynamic player, bool isDark) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: DreadmoorColors.divider(isDark ? Brightness.dark : Brightness.light))),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Text(
              "Send message...",
              style: GoogleFonts.spectral(fontSize: 22, color: Colors.black45),
            ),
            
            // RED QUILL SEND BUTTON
            Positioned(
              right: -5,
              top: -30,
              child: GestureDetector(
                onTap: () => HapticFeedback.mediumImpact(),
                child: Image.asset(
                  'assets/ui/quill_red.png', 
                  width: 85, 
                  height: 85
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
