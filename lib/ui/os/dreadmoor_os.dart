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

    final activeApp = ref.watch(activeAppProvider);

    // activeThreadIdProvider is set to the thread ID when the player is
    // inside a ChatScreen or SecretChatScreen, and reset to null on dispose.
    // We use this to hide the nav bar while a chat is open.
    final activeThreadId = ref.watch(activeThreadIdProvider);
    final isInChat = activeThreadId != null;

    /// Nav bar visible ONLY on main OS apps AND when NOT inside a chat.
    final showNavBar = !isInChat &&
        (activeApp == PhoneApp.messenger ||
            activeApp == PhoneApp.apps ||
            activeApp == PhoneApp.puzzle);

    return Scaffold(
      backgroundColor: DreadmoorColors.background(brightness),
      body: Stack(
        children: [

          /// ─────────────────────────────────────────────
          /// MAIN OS LAYER
          /// ─────────────────────────────────────────────
          SafeArea(
            top: false,
            child: NotificationOverlay(
              child: Column(
                children: [

                  /// Status Bar renders first in the column so it pushes the
                  /// rest of the app content down, avoiding overlaps with UI headers.
                  /// As requested, it is completely invisible (transparent/colorless)
                  /// so it does not spoil the appearance of other screens.
                  const DreadmoorStatusBar(),

                  const Expanded(
                    child: DreadmoorAppContainer(),
                  ),

                  /// Bottom navigation bar — hidden inside chats and secret chats
                  if (showNavBar)
                    const DreadmoorNavigationBar(),
                ],
              ),
            ),
          ),

          /// ─────────────────────────────────────────────
          /// INCOMING CALL
          /// ─────────────────────────────────────────────
          if (phoneState.callState == CallState.incoming)
            Positioned.fill(
              child: IncomingCallScreen(
                callerName: phoneState.callerName,
                callerNumber: phoneState.callerNumber,
                canDecline: phoneState.canDecline,
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

          /// ─────────────────────────────────────────────
          /// ACTIVE CALL
          /// ─────────────────────────────────────────────
          if (phoneState.callState == CallState.active)
            Positioned.fill(
              child: ActiveCallScreen(
                callerName: phoneState.callerName,
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
