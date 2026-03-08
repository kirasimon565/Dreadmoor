import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dreadmoor/core/time/game_clock.dart';

enum CallState { idle, incoming, active }

class CallEntry {
  final String name;
  final String number;
  final int time;
  final bool isIncoming;
  final bool isMissed;

  CallEntry({
    required this.name,
    required this.number,
    required this.time,
    required this.isIncoming,
    required this.isMissed,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'number': number,
        'time': time,
        'isIncoming': isIncoming,
        'isMissed': isMissed,
      };

  factory CallEntry.fromJson(Map<String, dynamic> json) {
    return CallEntry(
      name: json['name'],
      number: json['number'],
      time: json['time'],
      isIncoming: json['isIncoming'],
      isMissed: json['isMissed'],
    );
  }
}

class PhoneState {
  final CallState callState;
  final String callerName;
  final String callerNumber;
  final List<CallEntry> history;

  PhoneState({
    required this.callState,
    required this.callerName,
    required this.callerNumber,
    required this.history,
  });

  PhoneState copyWith({
    CallState? callState,
    String? callerName,
    String? callerNumber,
    List<CallEntry>? history,
  }) {
    return PhoneState(
      callState: callState ?? this.callState,
      callerName: callerName ?? this.callerName,
      callerNumber: callerNumber ?? this.callerNumber,
      history: history ?? this.history,
    );
  }
}

class PhoneNotifier extends StateNotifier<PhoneState> {
  static const _historyKey = 'phone_call_history';

  PhoneNotifier()
      : super(PhoneState(
          callState: CallState.idle,
          callerName: '',
          callerNumber: '',
          history: [],
        )) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        final history = decoded.map((e) => CallEntry.fromJson(e)).toList();
        state = state.copyWith(history: history);
      } catch (e) {
        // Handle decoding error
      }
    }
  }

  Future<void> _saveHistory(List<CallEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_historyKey, jsonString);
  }

  void startCall(String name, String number, int time) {
    final entry = CallEntry(
      name: name,
      number: number,
      time: time,
      isIncoming: false,
      isMissed: false,
    );

    final newHistory = [entry, ...state.history];
    state = state.copyWith(
      callState: CallState.active,
      callerName: name,
      callerNumber: number,
      history: newHistory,
    );
    _saveHistory(newHistory);
  }

  void receiveIncomingCall(String name, String number) {
    state = state.copyWith(
      callState: CallState.incoming,
      callerName: name,
      callerNumber: number,
    );
  }

  void acceptIncomingCall(int time) {
    if (state.callState != CallState.incoming) return;

    final entry = CallEntry(
      name: state.callerName,
      number: state.callerNumber,
      time: time,
      isIncoming: true,
      isMissed: false,
    );

    final newHistory = [entry, ...state.history];
    state = state.copyWith(
      callState: CallState.active,
      history: newHistory,
    );
    _saveHistory(newHistory);
  }

  void declineIncomingCall(int time) {
    if (state.callState != CallState.incoming) return;

    final entry = CallEntry(
      name: state.callerName,
      number: state.callerNumber,
      time: time,
      isIncoming: true,
      isMissed: true,
    );

    final newHistory = [entry, ...state.history];
    state = state.copyWith(
      callState: CallState.idle,
      history: newHistory,
    );
    _saveHistory(newHistory);
  }

  void endActiveCall() {
    if (state.callState != CallState.active) return;

    state = state.copyWith(
      callState: CallState.idle,
      callerName: '',
      callerNumber: '',
    );
  }

  String resolveName(String number) {
    switch (number) {
      case "911":
        return "Emergency";
      case "558169":
        return "Ash";
      case "7319":
        return "Rebecca Voicemail";
      default:
        return number;
    }
  }
}

final phoneProvider = StateNotifierProvider<PhoneNotifier, PhoneState>((ref) {
  return PhoneNotifier();
});
