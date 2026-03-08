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
  bool _isDialPadOpen = false;

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

    // Clear typed number after dialing and close the pad
    setState(() {
      _number = "";
      _isDialPadOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final phoneState = ref.watch(phoneProvider);
    final history = phoneState.history;

    return PopScope(
      canPop: !_isDialPadOpen,
      onPopInvoked: (didPop) {
        if (!didPop) {
          setState(() {
            _isDialPadOpen = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: DreadmoorColors.background,
        floatingActionButton: _isDialPadOpen ? null : FloatingActionButton(
          backgroundColor: DreadmoorColors.accentCyan,
          onPressed: () {
            setState(() {
              _isDialPadOpen = true;
            });
          },
          child: const Icon(Icons.dialpad, color: Colors.black),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Base Layer: Header and Call History
              Column(
                children: [
                  const OSHeader(
                    title: "PHONE",
                    subtitle: "Dialer & History",
                  ),
                  Expanded(
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
                          padding: const EdgeInsets.all(16).copyWith(bottom: 100),
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
                            String typeText;
                            if (call.isMissed) {
                              iconData = Icons.call_missed;
                              iconColor = DreadmoorColors.accentRed;
                              typeText = "Missed";
                            } else if (call.isIncoming) {
                              iconData = Icons.call_received;
                              iconColor = DreadmoorColors.textSecondary;
                              typeText = "Incoming";
                            } else {
                              iconData = Icons.call_made;
                              iconColor = DreadmoorColors.textSecondary;
                              typeText = "Outgoing";
                            }

                            String metaString = timeStr;
                            if (call.durationSeconds > 0) {
                                final m = call.durationSeconds ~/ 60;
                                final s = (call.durationSeconds % 60).toString().padLeft(2, '0');
                                metaString += " • $m:$s";
                            }

                            return Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: DreadmoorColors.surfaceAlt,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: DreadmoorColors.borderSubtle),
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
                                            typeText,
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
                                  metaString,
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
                ],
              ),

              // Top Layer: Sliding Dial Pad
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                bottom: _isDialPadOpen ? 0 : -MediaQuery.of(context).size.height,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity! > 200) {
                      setState(() {
                        _isDialPadOpen = false;
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: DreadmoorColors.background,
                      border: Border(top: BorderSide(color: DreadmoorColors.borderSubtle)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        )
                      ]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: DreadmoorColors.textMeta.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Number Display
                        Container(
                          height: 60,
                          width: double.infinity,
                          alignment: Alignment.center,
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

                        const Divider(color: DreadmoorColors.divider, height: 1),

                        // Dial Pad
                        Container(
                          padding: const EdgeInsets.only(top: 24, bottom: 40),
                          color: DreadmoorColors.surfaceAlt,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = MediaQuery.of(context).size.height < 700;
                              final vSpacing = isCompact ? 12.0 : 20.0;

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 56),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _dial("1", "", isCompact),
                                            _dial("2", "ABC", isCompact),
                                            _dial("3", "DEF", isCompact),
                                          ],
                                        ),
                                        SizedBox(height: vSpacing),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _dial("4", "GHI", isCompact),
                                            _dial("5", "JKL", isCompact),
                                            _dial("6", "MNO", isCompact),
                                          ],
                                        ),
                                        SizedBox(height: vSpacing),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _dial("7", "PQRS", isCompact),
                                            _dial("8", "TUV", isCompact),
                                            _dial("9", "WXYZ", isCompact),
                                          ],
                                        ),
                                        SizedBox(height: vSpacing),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _dial("*", "", isCompact),
                                            _dial("0", "+", isCompact),
                                            _dial("#", "", isCompact),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: vSpacing * 1.5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(width: 80),
                                      SizedBox(
                                        width: 80,
                                        child: Center(
                                          child: IconButton(
                                            icon: Icon(Icons.backspace, color: DreadmoorColors.textSecondary, size: isCompact ? 20 : 24),
                                            onPressed: _delete,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      GestureDetector(
                                        onTap: _call,
                                        child: Container(
                                          width: isCompact ? 56 : 64,
                                          height: isCompact ? 56 : 64,
                                          decoration: const BoxDecoration(
                                            color: DreadmoorColors.accentCyan,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.call, color: Colors.black, size: isCompact ? 24 : 28),
                                        ),
                                      ),
                                      const SizedBox(width: 80),
                                    ],
                                  ),
                                ],
                              );
                            }
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dial(String number, String letters, bool isCompact) {
    final size = isCompact ? 48.0 : 56.0;
    return GestureDetector(
      onTap: () => _press(number),
      child: Container(
        width: size,
        height: size,
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
                fontSize: isCompact ? 20 : 24,
                color: Colors.white,
                fontWeight: FontWeight.w300,
                height: 1.0,
              ),
            ),
            if (letters.isNotEmpty && !isCompact)
              Text(
                letters,
                style: DreadmoorTheme.bodyStyle.copyWith(
                  fontSize: 8,
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
