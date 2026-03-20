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

import 'package:dreadmoor/ui/widgets/notification_overlay.dart';

class DreadmoorOS extends ConsumerWidget {
  const DreadmoorOS({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneState = ref.watch(phoneProvider);
    final brightness = Theme.of(context).brightness;
    final activeApp  = ref.watch(activeAppProvider);

    // FIX: previously used `activeThreadId != null` to decide whether to
    // hide the nav bar. This caused a permanent disappearance because when
    // the scheduler navigates away from a chat (e.g. switches to browser),
    // the chat screen stays alive in MessengerNavigator's stack — dispose()
    // is never called, activeThreadId is never cleared, isInChat stays true.
    //
    // The correct rule: show the nav bar for all four tab apps.
    // Hide it only for browser and phone which are immersive full-screen.
    // The chat screen is itself full-screen inside MessengerNavigator so
    // the nav bar underneath it doesn't matter — it's covered by the chat UI.
    final showNavBar = activeApp != PhoneApp.browser &&
                       activeApp != PhoneApp.phone;

    return Scaffold(
      backgroundColor: DreadmoorColors.background(brightness),
      body: Stack(
        children: [

          // ── MAIN OS LAYER ─────────────────────────────────────────────
          SafeArea(
            top: false,
            child: NotificationOverlay(
              child: Column(
                children: [
                  const DreadmoorStatusBar(),

                  const Expanded(
                    child: DreadmoorAppContainer(),
                  ),

                  if (showNavBar)
                    const DreadmoorNavigationBar(),
                ],
              ),
            ),
          ),

          // ── INCOMING CALL ─────────────────────────────────────────────
          if (phoneState.callState == CallState.incoming)
            Positioned.fill(
              child: IncomingCallScreen(
                callerName:   phoneState.callerName,
                callerNumber: phoneState.callerNumber,
                canDecline:   phoneState.canDecline,
                onAccept: () {
                  ref.read(phoneProvider.notifier)
                      .acceptIncomingCall(ref.read(gameClockProvider));
                  if (phoneState.onAccept != null) {
                    phoneState.onAccept!();
                  }
                },
                onDecline: () {
                  ref.read(phoneProvider.notifier)
                      .declineIncomingCall(ref.read(gameClockProvider));
                  if (phoneState.onDecline != null) {
                    phoneState.onDecline!();
                  }
                },
              ),
            ),

          // ── ACTIVE CALL ───────────────────────────────────────────────
          if (phoneState.callState == CallState.active)
            Positioned.fill(
              child: ActiveCallScreen(
                callerName:   phoneState.callerName,
                callerNumber: phoneState.callerNumber,
                onEnd: (durationSeconds) {
                  ref.read(phoneProvider.notifier)
                      .endActiveCall(durationSeconds);
                  ref.read(globalSchedulerProvider).resume();
                },
              ),
            ),
        ],
      ),
    );
  }
}
