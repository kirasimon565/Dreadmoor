import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/ui/os/dreadmoor_app_container.dart';
import 'package:dreadmoor/ui/os/dreadmoor_navigation_bar.dart';
import 'package:dreadmoor/ui/os/dreadmoor_status_bar.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/features/phone/phone_state.dart';
import 'package:dreadmoor/features/phone/ui/screens/call/incoming_call_screen.dart';
import 'package:dreadmoor/features/phone/ui/screens/call/active_call_screen.dart';
import 'package:dreadmoor/core/time/game_clock.dart';
import 'package:dreadmoor/core/state/game_state.dart';

class DreadmoorOS extends ConsumerWidget {
  const DreadmoorOS({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneState = ref.watch(phoneProvider);

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const DreadmoorStatusBar(),
                const Expanded(
                  child: DreadmoorAppContainer(),
                ),
                const DreadmoorNavigationBar(),
              ],
            ),
          ),

          // OS-Level Overlays for Phone Calls
          if (phoneState.callState == CallState.incoming)
            Positioned.fill(
              child: IncomingCallScreen(
                callerName: phoneState.callerName,
                callerNumber: phoneState.callerNumber,
                onAccept: () {
                  ref.read(phoneProvider.notifier).acceptIncomingCall(ref.read(gameClockProvider));
                },
                onDecline: () {
                  ref.read(phoneProvider.notifier).declineIncomingCall(ref.read(gameClockProvider));
                  ref.read(globalSchedulerProvider).resume();
                },
              ),
            ),

          if (phoneState.callState == CallState.active)
            Positioned.fill(
              child: ActiveCallScreen(
                callerName: phoneState.callerName,
                callerNumber: phoneState.callerNumber,
                onEnd: () {
                  ref.read(phoneProvider.notifier).endActiveCall();
                  ref.read(globalSchedulerProvider).resume();
                },
              ),
            ),
        ],
      ),
    );
  }
}
