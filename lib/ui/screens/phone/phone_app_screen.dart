import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/colors.dart';

class PhoneAppScreen extends ConsumerStatefulWidget {
  const PhoneAppScreen({super.key});

  @override
  ConsumerState<PhoneAppScreen> createState() => _PhoneAppScreenState();
}

class _PhoneAppScreenState extends ConsumerState<PhoneAppScreen> {

  String _number = "";

  bool _incomingCall = false;
  bool _activeCall = false;

  String _callerName = "";
  String _callerNumber = "";

  List<CallEntry> history = [];

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

    setState(() {

      _activeCall = true;

      _callerNumber = _number;
      _callerName = _resolveName(_number);

      history.insert(
        0,
        CallEntry(
          name: _callerName,
          number: _number,
          time: DateTime.now(),
        ),
      );
    });
  }

  String _resolveName(String number) {

    switch (number) {

      case "911":
        return "Emergency";

      case "558169":
        return "Ash";

      default:
        return number;
    }
  }

  void _endCall() {
    setState(() {
      _activeCall = false;
      _number = "";
    });
  }

  void simulateIncomingCall(String name, String number) {

    setState(() {
      _incomingCall = true;
      _callerName = name;
      _callerNumber = number;
    });
  }

  void _acceptCall() {
    setState(() {
      _incomingCall = false;
      _activeCall = true;
    });
  }

  void _declineCall() {
    setState(() {
      _incomingCall = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (_incomingCall) {
      return _IncomingCallScreen(
        name: _callerName,
        number: _callerNumber,
        onAccept: _acceptCall,
        onDecline: _declineCall,
      );
    }

    if (_activeCall) {
      return _ActiveCallScreen(
        name: _callerName,
        number: _callerNumber,
        onEnd: _endCall,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [

            const SizedBox(height: 20),

            Text(
              _number.isEmpty ? "Enter Number" : _number,
              style: GoogleFonts.inter(
                fontSize: 30,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                children: [
                  _dial("1"),
                  _dial("2"),
                  _dial("3"),
                  _dial("4"),
                  _dial("5"),
                  _dial("6"),
                  _dial("7"),
                  _dial("8"),
                  _dial("9"),
                  _dial("*"),
                  _dial("0"),
                  _dial("#"),
                ],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                IconButton(
                  icon: const Icon(Icons.backspace, color: Colors.white),
                  onPressed: _delete,
                ),

                const SizedBox(width: 30),

                FloatingActionButton(
                  backgroundColor: Colors.green,
                  onPressed: _call,
                  child: const Icon(Icons.call),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {

                  final call = history[index];

                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      call.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      call.number,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Text(
                      "${call.time.hour}:${call.time.minute.toString().padLeft(2,'0')}",
                      style: const TextStyle(color: Colors.white54),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _dial(String value) {

    return GestureDetector(
      onTap: () => _press(value),
      child: Center(
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomingCallScreen extends StatelessWidget {

  final String name;
  final String number;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingCallScreen({
    required this.name,
    required this.number,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const CircleAvatar(
              radius: 60,
              child: Icon(Icons.person, size: 60),
            ),

            const SizedBox(height: 20),

            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
              ),
            ),

            Text(
              number,
              style: const TextStyle(color: Colors.white54),
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: onDecline,
                  child: const Icon(Icons.call_end),
                ),

                const SizedBox(width: 60),

                FloatingActionButton(
                  backgroundColor: Colors.green,
                  onPressed: onAccept,
                  child: const Icon(Icons.call),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _ActiveCallScreen extends StatelessWidget {

  final String name;
  final String number;
  final VoidCallback onEnd;

  const _ActiveCallScreen({
    required this.name,
    required this.number,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const CircleAvatar(
              radius: 60,
              child: Icon(Icons.person, size: 60),
            ),

            const SizedBox(height: 20),

            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
              ),
            ),

            Text(
              "Calling...",
              style: const TextStyle(color: Colors.white54),
            ),

            const SizedBox(height: 40),

            FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: onEnd,
              child: const Icon(Icons.call_end),
            ),
          ],
        ),
      ),
    );
  }
}

class CallEntry {

  final String name;
  final String number;
  final DateTime time;

  CallEntry({
    required this.name,
    required this.number,
    required this.time,
  });
}
