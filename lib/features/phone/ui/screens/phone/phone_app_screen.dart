import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/core/time/game_clock.dart';
import 'package:dreadmoor/features/phone/phone_state.dart';

import 'package:dreadmoor/ui/os/components/os_header.dart';

class PhoneAppScreen extends ConsumerStatefulWidget {
  const PhoneAppScreen({super.key});

  @override
  ConsumerState<PhoneAppScreen> createState() => _PhoneAppScreenState();
}

class _PhoneAppScreenState extends ConsumerState<PhoneAppScreen> {
  String _number = "";

  void _press(String value) {
    setState(() {
      _number += value;
    });
  }

  void _delete() {
    if (_number.isEmpty) return;
    setState(() {
      _number = _number.substring(0, _number.length - 1);
    });
  }

  void _call() {
    if (_number.isEmpty) return;

    final phoneNotifier = ref.read(phoneProvider.notifier);
    final resolved = phoneNotifier.resolveName(_number);
    final currentTime = ref.read(gameClockProvider);

    phoneNotifier.startCall(resolved, _number, currentTime);

    // Clear typed number after dialing
    setState(() {
      _number = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final phoneState = ref.watch(phoneProvider);
    final history = phoneState.history;

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const OSHeader(
              title: "PHONE",
              subtitle: "Dialer & History",
            ),

            // Top section: Dialer (Naturally sized and centered)
            Container(
              color: DreadmoorColors.surfaceAlt,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Number Display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _number.isEmpty ? "Enter Number" : _number,
                      style: DreadmoorTheme.headingStyle.copyWith(
                        fontSize: 28,
                        color: _number.isEmpty ? DreadmoorColors.textMeta : Colors.white,
                        letterSpacing: 2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Keypad (Centered & more compact)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _dial("1", ""),
                            _dial("2", "ABC"),
                            _dial("3", "DEF"),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _dial("4", "GHI"),
                            _dial("5", "JKL"),
                            _dial("6", "MNO"),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _dial("7", "PQRS"),
                            _dial("8", "TUV"),
                            _dial("9", "WXYZ"),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _dial("*", ""),
                            _dial("0", "+"),
                            _dial("#", ""),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 56), // spacer
                      GestureDetector(
                        onTap: _call,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: DreadmoorColors.accentCyan,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call, color: Colors.black, size: 28),
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: IconButton(
                          icon: const Icon(Icons.backspace, color: DreadmoorColors.textSecondary),
                          onPressed: _delete,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              height: 1,
              color: DreadmoorColors.divider,
            ),

            // Bottom section: Call History (Takes remaining space)
            Expanded(
              child: Container(
                color: DreadmoorColors.background,
                child: history.isEmpty
                  ? Center(
                      child: Text(
                        "No calls yet",
                        style: DreadmoorTheme.bodyStyle.copyWith(
                          color: DreadmoorColors.textMeta,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.white.withOpacity(0.05),
                        height: 24,
                      ),
                      itemBuilder: (context, index) {
                        final call = history[index];
                        final timeStr = formatGameTime(call.time);

                        IconData iconData;
                        Color iconColor;
                        if (call.isMissed) {
                          iconData = Icons.call_missed;
                          iconColor = DreadmoorColors.accentRed;
                        } else if (call.isIncoming) {
                          iconData = Icons.call_received;
                          iconColor = DreadmoorColors.textSecondary;
                        } else {
                          iconData = Icons.call_made;
                          iconColor = DreadmoorColors.textSecondary;
                        }

                        return Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: DreadmoorColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.person, color: Colors.white54, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    call.name,
                                    style: DreadmoorTheme.bodyStyle.copyWith(
                                      color: call.isMissed ? DreadmoorColors.accentRed : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(iconData, size: 12, color: iconColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        call.number,
                                        style: DreadmoorTheme.bodyStyle.copyWith(
                                          color: DreadmoorColors.textMeta,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              timeStr,
                              style: DreadmoorTheme.bodyStyle.copyWith(
                                color: DreadmoorColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dial(String number, String letters) {
    return GestureDetector(
      onTap: () => _press(number),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: DreadmoorColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: DreadmoorTheme.bodyStyle.copyWith(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w300,
                height: 1.0,
              ),
            ),
            if (letters.isNotEmpty)
              Text(
                letters,
                style: DreadmoorTheme.bodyStyle.copyWith(
                  fontSize: 9,
                  color: DreadmoorColors.textMeta,
                  letterSpacing: 1.0,
                  height: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
