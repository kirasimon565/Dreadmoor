import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:dreadmoor/core/time/game_clock.dart';
import 'package:dreadmoor/core/state/game_state.dart';
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
    final direction =
        isIncoming ? (isMissed ? 'missed' : 'incoming') : 'outgoing';
    return {
      'name':            name,
      'number':          number,
      'direction':       direction,
      'durationSeconds': durationSeconds,
      'timestamp':       time,
    };
  }

  factory CallEntry.fromJson(Map<String, dynamic> json) {
    final direction = json['direction'] as String?;
    bool isIncoming = false;
    bool isMissed   = false;

    if (direction == 'incoming') {
      isIncoming = true;
    } else if (direction == 'missed') {
      isIncoming = true;
      isMissed   = true;
    }

    return CallEntry(
      name:            json['name']            ?? 'Unknown',
      number:          json['number']          ?? '',
      time:            json['timestamp']        ?? 0,
      isIncoming:      isIncoming,
      isMissed:        isMissed,
      durationSeconds: json['durationSeconds'] ?? 0,
    );
  }
}

class PhoneState {
  final CallState callState;
  final String callerName;
  final String callerNumber;
  final List<CallEntry> history;
  final bool canDecline;
  final VoidCallback? onDecline;
  final VoidCallback? onAccept;
  final String? callAudioPath;

  PhoneState({
    required this.callState,
    required this.callerName,
    required this.callerNumber,
    required this.history,
    this.canDecline     = true,
    this.onDecline,
    this.onAccept,
    this.callAudioPath,
  });

  PhoneState copyWith({
    CallState?    callState,
    String?       callerName,
    String?       callerNumber,
    List<CallEntry>? history,
    bool?         canDecline,
    VoidCallback? onDecline,
    VoidCallback? onAccept,
    String?       callAudioPath,
  }) {
    return PhoneState(
      callState:     callState     ?? this.callState,
      callerName:    callerName    ?? this.callerName,
      callerNumber:  callerNumber  ?? this.callerNumber,
      history:       history       ?? this.history,
      canDecline:    canDecline    ?? this.canDecline,
      onDecline:     onDecline     ?? this.onDecline,
      onAccept:      onAccept      ?? this.onAccept,
      callAudioPath: callAudioPath ?? this.callAudioPath,
    );
  }
}

class PhoneNotifier extends Notifier<PhoneState> {
  static const _historyKey = 'phone_call_history';

  @override
  PhoneState build() {
    _loadHistory();
    return PhoneState(
      callState:     CallState.idle,
      callerName:    '',
      callerNumber:  '',
      history:       [],
      callAudioPath: null,
    );
  }

  Future<void> _loadHistory() async {
    final db  = ref.read(databaseProvider);
    final row = await (db.select(db.storyState)
          ..where((t) => t.key.equals(_historyKey)))
        .getSingleOrNull();

    if (row != null && row.stringValue != null) {
      try {
        final List<dynamic> decoded = jsonDecode(row.stringValue!);
        final history = decoded.map((e) => CallEntry.fromJson(e)).toList();
        state = state.copyWith(history: history);
      } catch (_) {}
    } else {
      await _saveHistory([]);
    }
  }

  Future<void> _saveHistory(List<CallEntry> history) async {
    final db         = ref.read(databaseProvider);
    final jsonString = jsonEncode(history.map((e) => e.toJson()).toList());

    await db.into(db.storyState).insertOnConflictUpdate(
      StoryStateCompanion(
        key:         const Value(_historyKey),
        value:       const Value(true),
        stringValue: Value(jsonString),
        updatedAt:   Value(DateTime.now()),
      ),
    );
  }

  Future<String> getCallerName(String number) async {
    final db        = ref.read(databaseProvider);
    final character = await (db.select(db.characters)
          ..where((c) => c.phoneNumber.equals(number)))
        .getSingleOrNull();

    if (character != null) return character.name;

    switch (number) {
      case '911':    return 'Emergency';
      case '558169': return 'Ash';
      case '7319':   return 'Rebecca Voicemail';
      default:       return number;
    }
  }

  void startCall(String name, String number, int time) {
    final entry = CallEntry(
      name:            name,
      number:          number,
      time:            time,
      isIncoming:      false,
      isMissed:        false,
      durationSeconds: 0,
    );

    final newHistory = [entry, ...state.history];
    state = state.copyWith(
      callState:    CallState.active,
      callerName:   name,
      callerNumber: number,
      history:      newHistory,
    );
    _saveHistory(newHistory);
  }

  void receiveIncomingCall(
    String name,
    String number, {
    bool          canDecline    = true,
    VoidCallback? onDecline,
    VoidCallback? onAccept,
    String?       callAudioPath,
  }) {
    state = state.copyWith(
      callState:     CallState.incoming,
      callerName:    name,
      callerNumber:  number,
      canDecline:    canDecline,
      onDecline:     onDecline,
      onAccept:      onAccept,
      callAudioPath: callAudioPath,
    );
  }

  /// FIX: public method so the scheduler can set callAudioPath after
  /// startCall() without directly mutating .state (which is protected
  /// in Riverpod 3 and silently fails when called externally).
  void setCallAudioPath(String? path) {
    state = state.copyWith(callAudioPath: path);
  }

  void acceptIncomingCall(int time) {
    if (state.callState != CallState.incoming) return;

    final entry = CallEntry(
      name:            state.callerName,
      number:          state.callerNumber,
      time:            time,
      isIncoming:      true,
      isMissed:        false,
      durationSeconds: 0,
    );

    final newHistory = [entry, ...state.history];
    state = state.copyWith(
      callState:     CallState.active,
      history:       newHistory,
      callAudioPath: state.callAudioPath, // preserve path for ActiveCallScreen
    );
    _saveHistory(newHistory);
  }

  void declineIncomingCall(int time) {
    if (state.callState != CallState.incoming) return;

    final entry = CallEntry(
      name:            state.callerName,
      number:          state.callerNumber,
      time:            time,
      isIncoming:      true,
      isMissed:        true,
      durationSeconds: 0,
    );

    final newHistory = [entry, ...state.history];
    state = state.copyWith(
      callState:     CallState.idle,
      history:       newHistory,
      callAudioPath: null,
    );
    _saveHistory(newHistory);
  }

  void endActiveCall(int durationSeconds) {
    if (state.callState != CallState.active) return;

    if (state.history.isNotEmpty) {
      final activeEntry   = state.history.first;
      final updatedEntry  = CallEntry(
        name:            activeEntry.name,
        number:          activeEntry.number,
        time:            activeEntry.time,
        isIncoming:      activeEntry.isIncoming,
        isMissed:        activeEntry.isMissed,
        durationSeconds: durationSeconds,
      );

      final newHistory = [updatedEntry, ...state.history.skip(1)];
      state = state.copyWith(
        callState:     CallState.idle,
        callerName:    '',
        callerNumber:  '',
        history:       newHistory,
        callAudioPath: null,
      );
      _saveHistory(newHistory);
    } else {
      state = state.copyWith(
        callState:     CallState.idle,
        callerName:    '',
        callerNumber:  '',
        callAudioPath: null,
      );
    }
  }

  String resolveName(String number) {
    switch (number) {
      case '911':    return 'Emergency';
      case '558169': return '???';
      case '7319':   return 'Rebecca Voicemail';
      default:       return number;
    }
  }
}

final phoneProvider =
    NotifierProvider<PhoneNotifier, PhoneState>(PhoneNotifier.new);
