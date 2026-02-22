import 'dart:async';
import 'dart:math';
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
  final _rng = Random();

  GlobalScheduler(this.ref);

  static Future<void> prepare() async {
    // Reserved for future: background isolates, content prefetch, etc.
  }

  Future<void> resetAll() async {
    _timer?.cancel();
    _timer = null;
    _currentLineId = null;
    _currentScript = null;

    ref.read(currentEpisodeIdProvider.notifier).state = null;
    ref.read(activeThreadIdProvider.notifier).state = null;
    ref.read(isSchedulerPausedProvider.notifier).state = false;
    ref.read(waitingForChoiceProvider.notifier).state = false;
  }

  Future<void> startThread(String episodeId, String threadId) async {
    _timer?.cancel();

    try {
      final script =
          await ref.read(scriptLoaderProvider).loadThreadScript(episodeId, threadId);

      _currentScript = script;
      _currentLineId = script.script.isNotEmpty ? script.script.first.id : null;

      ref.read(currentEpisodeIdProvider.notifier).state = episodeId;
      ref.read(activeThreadIdProvider.notifier).state = threadId;
      ref.read(isSchedulerPausedProvider.notifier).state = false;
      ref.read(waitingForChoiceProvider.notifier).state = false;

      final db = ref.read(databaseProvider);

      await db.into(db.threads).insertOnConflictUpdate(
        ThreadsCompanion.insert(
          id: threadId,
          title: script.title,
          participants: script.participants.join(','),
          unreadCount: const Value(0),
          isTyping: const Value(false),
          isLocked: const Value(false),
          isSecret: const Value(false), // hook for secret chats
        ),
      );

      _scheduleNextTick();
    } catch (e) {
      // ignore: avoid_print
      print('❌ Scheduler startThread error: $e');
    }
  }

  Future<void> _scheduleNextTick() async {
    _timer?.cancel();

    if (_currentScript == null ||
        _currentLineId == null ||
        ref.read(isSchedulerPausedProvider) ||
        ref.read(waitingForChoiceProvider)) {
      return;
    }

    final line = _currentScript!.script.firstWhere(
      (l) => l.id == _currentLineId,
      orElse: () => throw Exception('Line $_currentLineId not found'),
    );

    int delay = line.delay ?? 600;

    if (line.content != null) {
      delay += (line.content!.length * 28);
    }

    delay += _rng.nextInt(400); // human jitter

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

    if (line.type == 'text' && line.senderId != 'player') {
      await (db.update(db.threads)..where((t) => t.id.equals(_currentScript!.id)))
          .write(const ThreadsCompanion(isTyping: Value(false)));
    }

    if (line.type == 'text') {
      final id = await db.into(db.messages).insert(
        MessagesCompanion.insert(
          threadId: _currentScript!.id,
          senderId: line.senderId!,
          content: line.content!,
          timestamp: Value(DateTime.now()),
        ),
      );

      await _incrementUnread(db);

      await (db.update(db.threads)..where((t) => t.id.equals(_currentScript!.id)))
          .write(ThreadsCompanion(lastMessageId: Value(id)));

      _currentLineId = line.next;
      _scheduleNextTick();
      return;
    }

    if (line.type == 'player_text') {
      final id = await db.into(db.messages).insert(
        MessagesCompanion.insert(
          threadId: _currentScript!.id,
          senderId: 'player',
          content: line.content!,
          isPlayerMessage: const Value(true),
          timestamp: Value(DateTime.now()),
        ),
      );

      await (db.update(db.threads)..where((t) => t.id.equals(_currentScript!.id)))
          .write(ThreadsCompanion(lastMessageId: Value(id)));

      _currentLineId = line.next;
      _scheduleNextTick();
      return;
    }

    if (line.type == 'choice') {
      ref.read(waitingForChoiceProvider.notifier).state = true;
      return;
    }

    // Script end
    _currentLineId = null;
  }

  Future<void> _incrementUnread(AppDatabase db) async {
    final active = ref.read(activeThreadIdProvider);
    if (active == _currentScript!.id) return;

    await db.customStatement(
      '''
      UPDATE threads
      SET unread_count = COALESCE(unread_count, 0) + 1
      WHERE id = ?
      ''',
      [_currentScript!.id],
    );
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
    } catch (_) {}

    return null;
  }

  void pause() {
    _timer?.cancel();
    ref.read(isSchedulerPausedProvider.notifier).state = true;
  }

  void resume() {
    ref.read(isSchedulerPausedProvider.notifier).state = false;
    _scheduleNextTick();
  }

  void dispose() {
    _timer?.cancel();
  }
}
