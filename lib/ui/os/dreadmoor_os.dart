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
    final topPad     = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: DreadmoorColors.background(brightness),
      body: Stack(
        children: [
          // ── MAIN OS LAYER ────────────────────────────────────────────────
          // Content fills the full body (including status bar area).
          // The bottom nav sits at the bottom; status bar overlays the top.
          SafeArea(
            // Don't add top padding here — status bar overlays content.
            top: false,
            child: NotificationOverlay(
              child: Column(
                children: [
                  // Reserve space for the transparent status bar so
                  // content starts below it, not behind it.
                  SizedBox(height: topPad + 32),

                  const Expanded(child: DreadmoorAppContainer()),

                  if (ref.watch(showNavigationBarProvider))
                    const DreadmoorNavigationBar(),
                ],
              ),
            ),
          ),

          // ── STATUS BAR — floats over everything, transparent ─────────────
          // Positioned at the very top, renders over whatever screen is active.
          // On chat/secret screens the header image shows through it.
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            child: const DreadmoorStatusBar(),
          ),

          // ── INCOMING CALL OVERLAY ────────────────────────────────────────
          if (phoneState.callState == CallState.incoming)
            Positioned.fill(
              child: IncomingCallScreen(
                callerName:   phoneState.callerName,
                callerNumber: phoneState.callerNumber,
                canDecline:   phoneState.canDecline,
                onAccept: () {
                  ref.read(phoneProvider.notifier)
                      .acceptIncomingCall(ref.read(gameClockProvider));
                  if (phoneState.onAccept != null) phoneState.onAccept!();
                },
                onDecline: () {
                  ref.read(phoneProvider.notifier)
                      .declineIncomingCall(ref.read(gameClockProvider));
                  if (phoneState.onDecline != null) phoneState.onDecline!();
                },
              ),
            ),

          // ── ACTIVE CALL OVERLAY ──────────────────────────────────────────
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
