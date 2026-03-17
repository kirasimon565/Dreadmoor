import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dreadmoor/ui/os/os_state.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/core/state/game_state.dart';
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
    HapticFeedback.selectionClick();
    setState(() {
      _number += value;
    });
  }

  void _delete() {
    if (_number.isEmpty) return;
    HapticFeedback.selectionClick();
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

    setState(() {
      _number = "";
      _isDialPadOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final phoneState = ref.watch(phoneProvider);
    final history = phoneState.history;
    final b = Theme.of(context).brightness;
    final isDark = b == Brightness.dark;

    return PopScope(
      canPop: !_isDialPadOpen,
      onPopInvoked: (didPop) {
        if (!didPop) setState(() => _isDialPadOpen = false);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        floatingActionButton: _isDialPadOpen ? null : FloatingActionButton(
          backgroundColor: isDark ? DreadmoorColors.investigatorCyan : DreadmoorColors.evidenceRed,
          onPressed: () => setState(() => _isDialPadOpen = true),
          child: const Icon(Icons.dialpad, color: Colors.white),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  OSHeader(
                    title: "SIGNAL LOG",
                    subtitle: "CALL HISTORY",
                    onBackPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        ref.read(activeAppProvider.notifier).setApp(PhoneApp.messenger);
                      }
                    },
                    trailing: Icon(Icons.history_toggle_off, color: DreadmoorColors.text(b).withOpacity(0.5)),
                  ),
                  Expanded(
                    child: history.isEmpty
                      ? Center(child: Text("NO RECENT LOGS", style: GoogleFonts.spaceGrotesk(letterSpacing: 2, color: DreadmoorColors.text(b).withOpacity(0.3))))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                          itemCount: history.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final call = history[index];
                            return _buildHistoryTile(context, call, b);
                          },
                        ),
                  ),
                ],
              ),

              // THE SLIDING DIAL PAD
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutQuart,
                bottom: _isDialPadOpen ? 0 : -MediaQuery.of(context).size.height,
                left: 0,
                right: 0,
                child: _buildDialPad(context, b),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(BuildContext context, CallEntry call, Brightness b) {
    final isDark = b == Brightness.dark;
    final timeStr = formatGameTime(call.time);
    final accent = isDark ? DreadmoorColors.investigatorCyan : DreadmoorColors.evidenceRed;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: DreadmoorColors.divider(b), width: 0.5),
        borderRadius: BorderRadius.circular(4), // Sharp corners
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: call.isMissed ? DreadmoorColors.evidenceRed : Colors.black12),
            ),
            child: Icon(
              call.isMissed ? Icons.call_missed : (call.isIncoming ? Icons.call_received : Icons.call_made),
              color: call.isMissed ? DreadmoorColors.evidenceRed : DreadmoorColors.text(b).withOpacity(0.4),
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call.name.toUpperCase(),
                  style: GoogleFonts.spectral(
                    color: call.isMissed ? DreadmoorColors.evidenceRed : DreadmoorColors.text(b),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  timeStr,
                  style: GoogleFonts.spaceGrotesk(fontSize: 10, color: DreadmoorColors.text(b).withOpacity(0.5)),
                ),
              ],
            ),
          ),
          if (call.durationSeconds > 0)
            Text(
              "${call.durationSeconds ~/ 60}:${(call.durationSeconds % 60).toString().padLeft(2, '0')}",
              style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildDialPad(BuildContext context, Brightness b) {
    final isDark = b == Brightness.dark;
    final accent = isDark ? DreadmoorColors.investigatorCyan : DreadmoorColors.evidenceRed;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: DreadmoorColors.divider(b), width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => setState(() => _isDialPadOpen = false),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              _number.isEmpty ? "SELECT FREQUENCY" : _number,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: _number.isEmpty ? DreadmoorColors.text(b).withOpacity(0.2) : accent,
              ),
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            crossAxisCount: 3,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              for (var i in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"])
                _dialKey(i, b),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40, top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 60),
                GestureDetector(
                  onTap: _call,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                    child: const Icon(Icons.call, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: Icon(Icons.backspace_outlined, color: DreadmoorColors.text(b).withOpacity(0.5)),
                  onPressed: _delete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialKey(String val, Brightness b) {
    return GestureDetector(
      onTap: () => _press(val),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: DreadmoorColors.divider(b)),
        ),
        child: Center(
          child: Text(
            val,
            style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
