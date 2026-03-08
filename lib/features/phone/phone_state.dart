import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:dreadmoor/core/time/game_clock.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';

enum CallState { idle, incoming, active }

class CallEntry {
  final String name;
  final String number;
  final int time;
  final bool isIncoming;
  final bool isMissed;
  final int durationSeconds;

  CallEntry({
    required this.name,
    required this.number,
    required this.time,
    required this.isIncoming,
    required this.isMissed,
    this.durationSeconds = 0,
  });

  Map<String, dynamic> toJson() {
    String direction = isIncoming ? (isMissed ? "missed" : "incoming") : "outgoing";
    return {
      'name': name,
      'number': number,
      'direction': direction,
      'durationSeconds': durationSeconds,
      'timestamp': time,
    };
  }

  factory CallEntry.fromJson(Map<String, dynamic> json) {
    final direction = json['direction'] as String?;
    bool isIncoming = false;
    bool isMissed = false;

    if (direction == "incoming") {
      isIncoming = true;
    } else if (direction == "missed") {
      isIncoming = true;
      isMissed = true;
    }

    return CallEntry(
      name: json['name'] ?? 'Unknown',
      number: json['number'] ?? '',
      time: json['timestamp'] ?? 0,
      isIncoming: isIncoming,
      isMissed: isMissed,
      durationSeconds: json['durationSeconds'] ?? 0,
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
  final Ref _ref;

  PhoneNotifier(this._ref)
      : super(PhoneState(
          callState: CallState.idle,
          callerName: '',
          callerNumber: '',
          history: [],
        )) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final db = _ref.read(databaseProvider);
    final row = await (db.select(db.storyState)..where((t) => t.key.equals(_historyKey))).getSingleOrNull();

    if (row != null && row.stringValue != null) {
      try {
        final List<dynamic> decoded = jsonDecode(row.stringValue!);
        final history = decoded.map((e) => CallEntry.fromJson(e)).toList();
        state = state.copyWith(history: history);
      } catch (e) {
        // Handle decoding error
      }
    } else {
      // First boot: insert default empty list to prevent missing rows
      await _saveHistory([]);
    }
  }

  Future<void> _saveHistory(List<CallEntry> history) async {
    final db = _ref.read(databaseProvider);
    final jsonString = jsonEncode(history.map((e) => e.toJson()).toList());

    await db.into(db.storyState).insertOnConflictUpdate(
      StoryStateCompanion(
        key: const Value(_historyKey),
        value: const Value(true),
        stringValue: Value(jsonString),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  void startCall(String name, String number, int time) {
    final entry = CallEntry(
      name: name,
      number: number,
      time: time,
      isIncoming: false,
      isMissed: false,
      durationSeconds: 0,
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
      durationSeconds: 0,
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
      durationSeconds: 0,
    );

    final newHistory = [entry, ...state.history];
    state = state.copyWith(
      callState: CallState.idle,
      history: newHistory,
    );
    _saveHistory(newHistory);
  }

  void endActiveCall(int durationSeconds) {
    if (state.callState != CallState.active) return;

    // Update the duration of the last call entry (the active one)
    if (state.history.isNotEmpty) {
      final activeEntry = state.history.first;
      final updatedEntry = CallEntry(
        name: activeEntry.name,
        number: activeEntry.number,
        time: activeEntry.time,
        isIncoming: activeEntry.isIncoming,
        isMissed: activeEntry.isMissed,
        durationSeconds: durationSeconds,
      );

      final newHistory = [updatedEntry, ...state.history.skip(1)];
      state = state.copyWith(
        callState: CallState.idle,
        callerName: '',
        callerNumber: '',
        history: newHistory,
      );
      _saveHistory(newHistory);
    } else {
      state = state.copyWith(
        callState: CallState.idle,
        callerName: '',
        callerNumber: '',
      );
    }
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
  return PhoneNotifier(ref);
});
