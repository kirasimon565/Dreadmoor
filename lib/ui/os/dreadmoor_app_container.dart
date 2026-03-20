import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/core/state/game_state.dart';

import 'package:dreadmoor/features/messenger/ui/messenger_navigator.dart';
import 'package:dreadmoor/features/browser/ui/browser_navigator.dart';
import 'package:dreadmoor/features/phone/ui/phone_navigator.dart';
import 'package:dreadmoor/features/profile/ui/profile_navigator.dart';
import 'package:dreadmoor/features/apps/ui/screens/apps/apps_screen.dart';
import 'package:dreadmoor/features/minigame/minigame_gate.dart';

class DreadmoorAppContainer extends ConsumerStatefulWidget {
  const DreadmoorAppContainer({super.key});

  @override
  ConsumerState<DreadmoorAppContainer> createState() =>
      _DreadmoorAppContainerState();
}

class _DreadmoorAppContainerState
    extends ConsumerState<DreadmoorAppContainer> {
  final List<PhoneApp> _appOrder = [
    PhoneApp.messenger,
    PhoneApp.browser,
    PhoneApp.phone,
    PhoneApp.apps,
    PhoneApp.puzzle,
    PhoneApp.profile,
  ];

  @override
  Widget build(BuildContext context) {
    final activeApp    = ref.watch(activeAppProvider);
    final activeIndex  = _appOrder.indexOf(activeApp);

    // Read minigame routing state so the puzzle slot renders
    // whichever minigame the scheduler launched.
    final minigameId   = ref.watch(activeMinigameIdProvider);
    final difficulty   = ref.watch(activeMinigameDifficultyProvider);

    return IndexedStack(
      index: activeIndex,
      children: [
        const MessengerNavigator(),
        const BrowserNavigator(),
        const PhoneNavigator(),
        const AppsScreen(),

        // ── PUZZLE / MINIGAME SLOT ────────────────────────────────────
        // Renders the correct minigame driven by activeMinigameIdProvider.
        // Falls back to a blank terminal screen if no minigame is active.
        minigameId != null
            ? MinigameGate(
                key:        ValueKey(minigameId),
                minigameId: minigameId,
                difficulty: difficulty,
              )
            : const _EmptyMinigameSlot(),

        const ProfileNavigator(),
      ],
    );
  }
}

/// Shown if the player somehow navigates to the puzzle tab
/// before a minigame has been launched by the scheduler.
class _EmptyMinigameSlot extends StatelessWidget {
  const _EmptyMinigameSlot();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'NO ACTIVE TRACE',
          style: TextStyle(
            color:       Color(0xFF005A14),
            fontFamily:  'monospace',
            fontSize:    13,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
