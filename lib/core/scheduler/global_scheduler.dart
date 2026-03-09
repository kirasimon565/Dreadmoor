import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/time/game_clock.dart';
import 'package:dreadmoor/features/phone/phone_state.dart';
import 'package:dreadmoor/features/notifications/app_notification.dart';
import 'package:dreadmoor/features/notifications/notification_state.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/script_models.dart';
import '../state/game_state.dart';

class GlobalScheduler {
  final Ref ref;

  Timer? _timer;

  // Keep track of active audio players so we can clean them up,
  // but allow multiple sounds to overlap.
  final List<AudioPlayer> _audioPlayers = [];

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
  Future<void> startThread(String episodeId, String threadId) async {
    // Stub functionality to avoid undefined method errors.
    // Replace with correct implementation if necessary.
    ref.read(activeThreadIdProvider.notifier).state = threadId;
    await startEpisode(episodeId);
  }

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
    if (ref.read(waitingForPuzzleProvider)) return;

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

      if (event.threadId != null) {
        db.update(db.threads)
          ..where((t) => t.id.equals(event.threadId!))
          ..write(const ThreadsCompanion(isTyping: Value(true)));
      }
      _playSound('sfx/typing.mp3');
    }

    _timer = Timer(Duration(milliseconds: delay), () async {
      await _executeEvent(event);
    });
  }

  Future<void> _playSound(String path) async {
    try {
      final player = AudioPlayer();
      _audioPlayers.add(player);

      player.onPlayerComplete.listen((_) {
        _audioPlayers.remove(player);
        player.dispose();
      });

      await player.play(AssetSource('media/$path'));
    } catch (e) {
      // Ignore if audio fails to play
    }
  }

  Future<void> _executeEvent(EventScript event) async {
    final db = ref.read(databaseProvider);
    final totalMinutes = ref.read(gameClockProvider);
    final gameTime = DateTime(2007, 3, 8 + (totalMinutes ~/ (24 * 60)), (totalMinutes % (24 * 60)) ~/ 60, totalMinutes % 60);

    /// ----------------------
    /// TYPING EVENT
    /// ----------------------

    if (event.type == 'typing') {
      if (event.threadId != null) {
        await (db.update(db.threads)..where((t) => t.id.equals(event.threadId!)))
            .write(const ThreadsCompanion(isTyping: Value(false)));
      }

      _eventIndex++;
      _scheduleNextTick();
      return;
    }

    /// ----------------------
    /// MESSAGE EVENT
    /// ----------------------

    if (event.type == 'message') {
      final threadId = event.threadId ?? 'system';
      final sender = event.sender ?? 'unknown';
      await _ensureThreadExists(threadId, sender);

      final id = await db
          .into(db.messages)
          .insert(
            MessagesCompanion.insert(
              threadId: threadId,
              senderId: sender,
              content: Value(event.text ?? ''),
              sequence: _eventIndex,
              timestamp: Value(gameTime),
            ),
          );

      await (db.update(db.threads)..where((t) => t.id.equals(threadId)))
          .write(ThreadsCompanion(lastMessageId: Value(id)));

      await _incrementUnread(db, threadId);

      /// Notification trigger hook
      final activeThread = ref.read(activeThreadIdProvider);

      if (activeThread != threadId) {
        ref.read(notificationProvider.notifier).push(
          AppNotification(
            id: 'msg_${event.id}',
            type: NotificationType.message,
            title: sender,
            message: event.text ?? 'Sent a message',
            createdAtMinutes: totalMinutes,
            payload: {'route': '/chat', 'threadId': threadId},
          ),
        );
      }

      _playSound('sfx/message_receive.mp3');

      // Advance game clock
      ref.read(gameClockProvider.notifier).advanceTime(1);

      _eventIndex++;
      _scheduleNextTick();
      return;
    }

    /// ----------------------
    /// SYSTEM MESSAGE
    /// ----------------------

    if (event.type == 'system') {
      if (event.action == 'open_puzzle') {
        pause();
        ref.read(waitingForPuzzleProvider.notifier).state = true;
        // Don't advance eventIndex until puzzle is complete
        return;
      }

      final threadId = event.threadId ?? 'system';

      if (event.text != null && event.text!.isNotEmpty) {
        await _ensureThreadExists(threadId, 'system');

        await db
            .into(db.messages)
            .insert(
              MessagesCompanion.insert(
                threadId: threadId,
                senderId: 'system',
                content: Value(event.text!),
                type: const Value('system'),
                sequence: _eventIndex,
                timestamp: Value(gameTime),
              ),
            );
      }

      _eventIndex++;
      _scheduleNextTick();
      return;
    }

    /// ----------------------
    /// NEWS EVENT
    /// ----------------------

    if (event.type == 'news') {
      ref.read(notificationProvider.notifier).push(
        AppNotification(
          id: 'news_${event.id}',
          type: NotificationType.article,
          title: event.headline ?? 'New Article',
          message: event.subheadline ?? 'Tap to read',
          createdAtMinutes: totalMinutes,
          payload: {'route': '/browser', 'url': 'news'},
        ),
      );

      _playSound('sfx/notification.mp3');

      _eventIndex++;
      _scheduleNextTick();
      return;
    }

    /// ----------------------
    /// MEDIA EVENTS
    /// ----------------------

    if (event.type == 'video' || event.type == 'audio') {
      final threadId = event.threadId ?? 'system';
      final sender = event.sender ?? 'unknown';
      final isCall = event.type == 'audio' && event.file != null && event.file!.contains('call');

      await _ensureThreadExists(threadId, sender);

      String mediaPath = '';
      if (event.file != null) {
        if (event.type == 'video') mediaPath = 'assets/media/videos/${event.file}';
        else if (event.type == 'audio') mediaPath = 'assets/media/audio/${event.file}';
      }

      final id = await db
          .into(db.messages)
          .insert(
            MessagesCompanion.insert(
              threadId: threadId,
              senderId: sender,
              content: Value(mediaPath),
              type: Value(event.type),
              sequence: _eventIndex,
              timestamp: Value(gameTime),
            ),
          );

      await (db.update(db.threads)..where((t) => t.id.equals(threadId)))
          .write(ThreadsCompanion(lastMessageId: Value(id)));

      await _incrementUnread(db, threadId);

      _playSound('sfx/message_receive.mp3');

      _eventIndex++;
      _scheduleNextTick();
      return;
    }

    /// ----------------------
    /// INTERCEPT EVENT
    /// ----------------------

    if (event.type == 'intercept') {
      // Intercept logic: trigger the intercept UI flow
      pause();

      // In a full implementation, we would route to an intercept screen.
      // For now, we simulate the intercept and emit a system notification/state.
      final threadId = event.threadId ?? 'system';
      await _ensureThreadExists(threadId, 'system');

      await db
          .into(db.messages)
          .insert(
            MessagesCompanion.insert(
              threadId: threadId,
              senderId: 'system',
              content: Value(event.text ?? 'INTERCEPT CONNECTION ESTABLISHED...'),
              type: const Value('system'),
              sequence: _eventIndex,
              timestamp: Value(gameTime),
            ),
          );

      // We wait for the intercept UI to finish, then we resume.
      // We'll auto-resume after a delay for now to prevent hard-locking the scheduler in this stub.
      Timer(const Duration(seconds: 3), () {
        _eventIndex++;
        resume();
      });
      return;
    }

    /// ----------------------
    /// CALL EVENT
    /// ----------------------

    if (event.type == 'call' || event.type == 'phone_call') {
       // example syntax: text="Anonymous", sender="12345"
       ref.read(phoneProvider.notifier).receiveIncomingCall(
         event.text ?? "Unknown",
         event.sender ?? "000000"
       );

       // Pause scheduler while call is active
       ref.read(isSchedulerPausedProvider.notifier).state = true;

       // Wait for call to finish before advancing
       // In a full implementation, the Phone app ending the call would unpause this.

       _eventIndex++;
       // Note: the next tick will be blocked until `resume()` is called.
       _scheduleNextTick();
       return;
    }

    /// ----------------------
    /// PUZZLE EVENT
    /// ----------------------

    if (event.type == 'puzzle') {
      ref.read(waitingForPuzzleProvider.notifier).state = true;
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
    /// DELAY EVENT
    /// ----------------------

    if (event.type == 'delay') {
      _eventIndex++;
      _scheduleNextTick();
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

    final existing = await (db.select(
      db.threads,
    )..where((t) => t.id.equals(threadId))).getSingleOrNull();

    if (existing != null) return;

    await db
        .into(db.threads)
        .insert(
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

    final thread = await (db.select(
      db.threads,
    )..where((t) => t.id.equals(threadId))).getSingleOrNull();

    if (thread == null) return;

    await (db.update(db.threads)..where((t) => t.id.equals(threadId))).write(
      ThreadsCompanion(unreadCount: Value(thread.unreadCount + 1)),
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

  void completePuzzle() {
    ref.read(waitingForPuzzleProvider.notifier).state = false;
    _eventIndex++;
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
    for (final player in _audioPlayers) {
      player.dispose();
    }
    _audioPlayers.clear();
  }
}
