import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../core/persistence/drift_database.dart';
import '../models/script_models.dart';
import '../state/game_state.dart';

class GlobalScheduler {
  final Ref ref;
  Timer? _timer;
  String? _currentLineId;
  ThreadScript? _currentScript;

  GlobalScheduler(this.ref);

  static Future<void> prepare() async {
    // Placeholder for any global scheduler initialization
  }

  Future<void> startThread(String episodeId, String threadId) async {
    try {
      final script = await ref.read(scriptLoaderProvider).loadThreadScript(episodeId, threadId);
      _currentScript = script;
      _currentLineId = script.script.first.id;

      ref.read(currentEpisodeIdProvider.notifier).state = episodeId;
      ref.read(activeThreadIdProvider.notifier).state = threadId;
      ref.read(isSchedulerPausedProvider.notifier).state = false;
      ref.read(waitingForChoiceProvider.notifier).state = false;

      // Initialize Thread in DB
      final db = ref.read(databaseProvider);
      await db.into(db.threads).insertOnConflictUpdate(ThreadsCompanion.insert(
        id: threadId,
        title: script.title,
        participants: script.participants.join(','),
        unreadCount: const Value(0), // Reset unread count? Or keep? Usually 0 on start.
        isTyping: const Value(false),
      ));

      _scheduleNextTick();
    } catch (e) {
      // ignore: avoid_print
      print('Error starting thread: $e');
    }
  }

  Future<void> _scheduleNextTick() async {
    if (ref.read(isSchedulerPausedProvider) || ref.read(waitingForChoiceProvider) || _currentLineId == null) return;

    final line = _currentScript!.script.firstWhere(
      (l) => l.id == _currentLineId,
      orElse: () => throw Exception('Line $_currentLineId not found'),
    );

    int delay = line.delay ?? 500;
    if (line.content != null) {
      delay += (line.content!.length * 30); // 30ms per char for typing speed
    }

    // Indicate typing if it's not player
    if (line.senderId != 'player' && line.type == 'text') {
       final db = ref.read(databaseProvider);
       await (db.update(db.threads)..where((t) => t.id.equals(_currentScript!.id)))
           .write(const ThreadsCompanion(isTyping: Value(true)));
    }

    _timer = Timer(Duration(milliseconds: delay), () async {
      await _executeLine(line);
    });
  }

  Future<void> _executeLine(ScriptLine line) async {
    final db = ref.read(databaseProvider);

    // Clear typing status if it was set
    if (line.type == 'text' && line.senderId != 'player') {
       await (db.update(db.threads)..where((t) => t.id.equals(_currentScript!.id)))
           .write(const ThreadsCompanion(isTyping: Value(false)));
    }

    if (line.type == 'text') {
      final id = await db.into(db.messages).insert(MessagesCompanion.insert(
        threadId: _currentScript!.id,
        senderId: line.senderId!,
        content: line.content!,
        timestamp: Value(DateTime.now()),
      ));

      // Update last message ID
      await (db.update(db.threads)..where((t) => t.id.equals(_currentScript!.id)))
           .write(ThreadsCompanion(lastMessageId: Value(id), unreadCount: const Value(1))); // Increment unread count logic needed properly

      _currentLineId = line.next;
      _scheduleNextTick();

    } else if (line.type == 'choice') {
      ref.read(waitingForChoiceProvider.notifier).state = true;
    } else if (line.type == 'player_text') {
       final id = await db.into(db.messages).insert(MessagesCompanion.insert(
        threadId: _currentScript!.id,
        senderId: 'player',
        content: line.content!,
        isPlayerMessage: Value(true),
        timestamp: Value(DateTime.now()),
      ));

       await (db.update(db.threads)..where((t) => t.id.equals(_currentScript!.id)))
           .write(ThreadsCompanion(lastMessageId: Value(id)));

       _currentLineId = line.next;
       _scheduleNextTick();
    }
  }

  void submitChoice(String jumptoId) {
    _currentLineId = jumptoId;
    ref.read(waitingForChoiceProvider.notifier).state = false;
    _scheduleNextTick();
  }

  List<ChoiceOption>? getCurrentChoices() {
    if (_currentScript == null || _currentLineId == null) return null;
    try {
        final line = _currentScript!.script.firstWhere((l) => l.id == _currentLineId);
        if (line.type == 'choice') return line.options;
    } catch (e) {
        return null;
    }
    return null;
  }
}
