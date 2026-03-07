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

  EpisodeScript? _episode;

  int _sceneIndex = 0;
  int _eventIndex = 0;

  final _rng = Random();

  GlobalScheduler(this.ref);

  static Future<void> prepare() async {}

  /// Hard reset
  Future<void> resetAll() async {
    _timer?.cancel();
    _timer = null;

    _episode = null;
    _sceneIndex = 0;
    _eventIndex = 0;

    final db = ref.read(databaseProvider);

    await db.delete(db.messages).go();
    await db.delete(db.threads).go();
    await db.delete(db.storyState).go();
    await db.delete(db.episodes).go();

    ref.read(currentEpisodeIdProvider.notifier).state = null;
    ref.read(activeThreadIdProvider.notifier).state = null;
    ref.read(isSchedulerPausedProvider.notifier).state = false;
    ref.read(waitingForChoiceProvider.notifier).state = false;
  }

  /// Start episode playback
  Future<void> startEpisode(String episodeId) async {
    _timer?.cancel();

    final loader = ref.read(scriptLoaderProvider);
    final episode = await loader.loadEpisode(episodeId);

    _episode = episode;

    _sceneIndex = 0;
    _eventIndex = 0;

    ref.read(currentEpisodeIdProvider.notifier).state = episodeId;
    ref.read(isSchedulerPausedProvider.notifier).state = false;
    ref.read(waitingForChoiceProvider.notifier).state = false;

    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    _timer?.cancel();

    if (_episode == null) return;
    if (ref.read(isSchedulerPausedProvider)) return;
    if (ref.read(waitingForChoiceProvider)) return;

    if (_sceneIndex >= _episode!.scenes.length) {
      return;
    }

    final scene = _episode!.scenes[_sceneIndex];

    if (_eventIndex >= scene.events.length) {
      _sceneIndex++;
      _eventIndex = 0;

      if (_sceneIndex >= _episode!.scenes.length) {
        return;
      }
    }

    final event = _episode!.scenes[_sceneIndex].events[_eventIndex];

    int delay = 500;

    if (event.type == 'message' && event.text != null) {
      delay += event.text!.length * 28;
    }

    if (event.type == 'typing') {
      delay = event.duration ?? 1500;
    }

    if (event.meta?.delayAfter != null) {
      delay += event.meta!.delayAfter!;
    }

    delay += _rng.nextInt(300);

    if (event.type == 'typing') {
      final db = ref.read(databaseProvider);

      db.update(db.threads)
        ..where((t) => t.id.equals(event.threadId!))
        ..write(const ThreadsCompanion(isTyping: Value(true)));
    }

    _timer = Timer(Duration(milliseconds: delay), () async {
      await _executeEvent(event);
    });
  }

  Future<void> _executeEvent(EventScript event) async {
    final db = ref.read(databaseProvider);

    /// ----------------------
    /// TYPING EVENT
    /// ----------------------

    if (event.type == 'typing') {
      await (db.update(db.threads)..where((t) => t.id.equals(event.threadId!)))
          .write(const ThreadsCompanion(isTyping: Value(false)));

      _eventIndex++;
      _scheduleNextTick();
      return;
    }

    /// ----------------------
    /// MESSAGE EVENT
    /// ----------------------

    if (event.type == 'message') {
      await _ensureThreadExists(event.threadId!, event.sender!);

      final id = await db.into(db.messages).insert(
  MessagesCompanion.insert(
    threadId: event.threadId!,
    senderId: event.sender!,
    content: event.text!,
    sequence: _eventIndex,
    timestamp: Value(DateTime.now()),
  ),
);

      await (db.update(db.threads)..where((t) => t.id.equals(event.threadId!)))
          .write(ThreadsCompanion(lastMessageId: Value(id)));

      await _incrementUnread(db, event.threadId!);

      /// Notification trigger hook
      final activeThread = ref.read(activeThreadIdProvider);

      if (activeThread != event.threadId) {
        // notification system will connect here
      }

      _eventIndex++;
      _scheduleNextTick();
      return;
    }

    /// ----------------------
    /// SYSTEM MESSAGE
    /// ----------------------

    if (event.type == 'system') {
      await _ensureThreadExists(event.threadId!, 'system');

      await db.into(db.messages).insert(
        MessagesCompanion.insert(
          threadId: event.threadId!,
          senderId: 'system',
          content: event.text ?? '',
          type: const Value('system'),
          timestamp: Value(DateTime.now()),
        ),
      );

      _eventIndex++;
      _scheduleNextTick();
      return;
    }

    /// ----------------------
    /// CHOICE EVENT
    /// ----------------------

    if (event.type == 'choice') {
      ref.read(waitingForChoiceProvider.notifier).state = true;
      return;
    }

    /// ----------------------
    /// UNKNOWN EVENT
    /// ----------------------

    _eventIndex++;
    _scheduleNextTick();
  }

  /// Ensure thread exists before writing messages
  Future<void> _ensureThreadExists(String threadId, String sender) async {
    final db = ref.read(databaseProvider);

    final existing =
        await (db.select(db.threads)..where((t) => t.id.equals(threadId)))
            .getSingleOrNull();

    if (existing != null) return;

    await db.into(db.threads).insert(
          ThreadsCompanion.insert(
            id: threadId,
            title: threadId,
            participants: sender,
            unreadCount: const Value(0),
            isTyping: const Value(false),
            isLocked: const Value(false),
            isSecret: const Value(false),
          ),
        );
  }

  Future<void> _incrementUnread(AppDatabase db, String threadId) async {
    final active = ref.read(activeThreadIdProvider);

    if (active == threadId) return;

    final thread =
        await (db.select(db.threads)..where((t) => t.id.equals(threadId)))
            .getSingleOrNull();

    if (thread == null) return;

    await (db.update(db.threads)..where((t) => t.id.equals(threadId))).write(
      ThreadsCompanion(
        unreadCount: Value(thread.unreadCount + 1),
      ),
    );
  }

  void submitChoice(String jumpto) {
    if (_episode == null) return;

    for (int s = 0; s < _episode!.scenes.length; s++) {
      final scene = _episode!.scenes[s];

      for (int e = 0; e < scene.events.length; e++) {
        if (scene.events[e].id == jumpto) {
          _sceneIndex = s;
          _eventIndex = e;
          break;
        }
      }
    }

    ref.read(waitingForChoiceProvider.notifier).state = false;

    _scheduleNextTick();
  }

  List<ChoiceOption>? getCurrentChoices() {
    if (_episode == null) return null;

    if (_sceneIndex >= _episode!.scenes.length) return null;

    final scene = _episode!.scenes[_sceneIndex];

    if (_eventIndex >= scene.events.length) return null;

    final event = scene.events[_eventIndex];

    if (event.type == 'choice') {
      return event.options;
    }

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
