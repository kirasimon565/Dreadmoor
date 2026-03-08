import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  PhoneNotifier()
      : super(PhoneState(
          callState: CallState.idle,
          callerName: '',
          callerNumber: '',
          history: [],
        ));

  void startCall(String name, String number, int time) {
    final entry = CallEntry(
      name: name,
      number: number,
      time: time,
      isIncoming: false,
      isMissed: false,
    );

    state = state.copyWith(
      callState: CallState.active,
      callerName: name,
      callerNumber: number,
      history: [entry, ...state.history],
    );
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

    state = state.copyWith(
      callState: CallState.active,
      history: [entry, ...state.history],
    );
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

    state = state.copyWith(
      callState: CallState.idle,
      history: [entry, ...state.history],
    );
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
