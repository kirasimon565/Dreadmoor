import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:flutter/material.dart';
import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/time/game_clock.dart';
import 'package:dreadmoor/features/phone/phone_state.dart';
import 'package:dreadmoor/features/notifications/notification_state.dart';
import 'package:dreadmoor/ui/navigation/app_router.dart';
import 'package:dreadmoor/ui/navigation/routes.dart';
import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/ui/widgets/media_viewer.dart';
import 'package:dreadmoor/ui/widgets/glitch_overlay.dart';
import '../state/game_state.dart';
import '../persistence/seed_characters.dart';

class GlobalScheduler {
  final Ref ref;
  Timer? _timer;
  final List<AudioPlayer> _audioPlayers = [];
  final _rng = Random();

  /// Prevents double-fire on fast taps of a choice button.
  bool _isSubmittingChoice = false;

  GlobalScheduler(this.ref);

  // --------------------------------------------------
  // CORE LIFECYCLE
  // --------------------------------------------------

  Future<void> processNode(String nodeId) async {
    _timer?.cancel();
    final db = ref.read(databaseProvider);
    await seedCharacters(db);
    ref.read(isSchedulerPausedProvider.notifier).state = false;
    ref.read(waitingForChoiceProvider.notifier).state = false;
    await _executeNode(nodeId);
  }

  Future<void> _executeNode(String nodeId) async {
    if (nodeId.isEmpty) return;

    final db = ref.read(databaseProvider);
    final node = await db.getNextNode(nodeId);
    if (node == null) {
      print("DreadmoorOS ✗ Node '$nodeId' not found in StoryNodes table.");
      return;
    }

    Map<String, dynamic> metadata = {};
    if (node.metadata != null && node.metadata!.isNotEmpty) {
      try {
        metadata = jsonDecode(node.metadata!) as Map<String, dynamic>;
      } catch (e) {
        print("DreadmoorOS ✗ Bad metadata on '$nodeId': $e");
      }
    }

    final action = (metadata['action'] as String?) ?? '';

    if (action == 'Typing') {
      await _handleTyping(node, metadata);
      return;
    }

    final delay = action == 'Pause'
        ? ((metadata['duration'] as int?) ?? 2000)
        : 500;

    _timer = Timer(Duration(milliseconds: delay), () async {
      // FIX: wrap Timer body in try/catch.
      // Timer callbacks swallow ALL exceptions silently — without this,
      // any error in _processNodeType causes the story to freeze forever
      // with zero output to the console.
      try {
        await _processNodeType(node, metadata);
      } catch (e, stack) {
        print("DreadmoorOS ✗ _processNodeType failed for '${node.id}': $e");
        print(stack);
        // Fallback: skip the broken node and keep the story moving.
        _advance(node.nextNodeId);
      }
    });
  }

  // --------------------------------------------------
  // NODE TYPE DISPATCHER
  // --------------------------------------------------

  Future<void> _processNodeType(
      StoryNode node, Map<String, dynamic> meta) async {
    final db = ref.read(databaseProvider);
    await db.updateStoryFlag(node.id, bVal: true);

    print("DreadmoorOS → processing '${node.id}' (type: ${node.type})");

    switch (node.type) {
      case 'Chat_Event':
      case 'Private_Unknown':
        await _handleChatMessage(node, meta);
        break;

      case 'Player_Choice':
        _handleChoiceRequired(node);
        break;

      case 'News_Module':
        _handleNewsModule(node, meta);
        break;

      case 'Phone_Call_Event':
      case 'IncomingCall':
      case 'S6_Ringing_Final':
        _handlePhoneCall(node, meta);
        break;

      case 'System_Notification':
      case 'System_Event':
        await _handleSystemLabel(node, meta);
        break;

      case 'S2_SYSTEM_ADD':
        await _handleS2SystemAdd(node, meta);
        break;

      case 'S4_VIDEO_NODE':
        _handleS4VideoNode(node, meta);
        break;

      case 'Secret_Hacked':
        await _handleSecretHacked(node, meta);
        break;

      case 'S5_CONNECTION_GLITCH':
        _handleS5ConnectionGlitch(node, meta);
        break;

      case 'S6_Accept_Call':
        _handleS6AcceptCall(node, meta);
        break;

      default:
        assert(false,
            "DreadmoorOS ✗ Unhandled type '${node.type}' on '${node.id}'");
        _advance(node.nextNodeId);
    }
  }

  // --------------------------------------------------
  // HANDLERS
  // --------------------------------------------------

  bool hasProcessed(String nodeId) {
    final flags = ref.read(gameFlagsProvider).value ?? {};
    return flags.containsKey(nodeId) && flags[nodeId] == true;
  }

  void _handleNewsModule(StoryNode node, Map<String, dynamic> meta) {
    final db = ref.read(databaseProvider);

    db.into(db.notifications).insert(
      NotificationsCompanion.insert(
        id:               'news_${node.id}',
        type:             'article',
        title:            'News Alert',
        message:          'A new article is available.',
        createdAtMinutes: 0,
        payload: Value(jsonEncode({
          'article': {
            'headline':    meta['headline']    ?? '',
            'subheadline': meta['subheadline'] ?? '',
            'photo':       meta['image_asset'] ?? '',
            'caption':     meta['caption']     ?? '',
            'body':        meta['body']        ?? [],
          }
        })),
      ),
      mode: InsertMode.insertOrReplace,
    );

    db.updateStoryFlag('article_read', bVal: true);
    ref.read(activeAppProvider.notifier).state = PhoneApp.browser;
    ref.read(appRouterProvider).go(Routes.messenger);

    // Advance immediately — never pause().
    _advance(node.nextNodeId);
  }

  Future<void> _handleS2SystemAdd(
      StoryNode node, Map<String, dynamic> meta) async {
    const groupId = 'group_dreadmoor_news';
    await _ensureThread(groupId);

    final db = ref.read(databaseProvider);
    for (final m in ['amelia', 'chris', 'abigail', 'michael']) {
      final exists = await (db.select(db.threadMembers)
            ..where((t) =>
                t.threadId.equals(groupId) & t.characterId.equals(m)))
          .getSingleOrNull();
      if (exists == null) {
        await db.into(db.threadMembers).insert(
          ThreadMembersCompanion.insert(
              threadId: groupId, characterId: m),
        );
      }
    }

    final unknownId = _resolveThreadId(node);
    await _ensureThread(unknownId);
    await db.into(db.messages).insert(MessagesCompanion.insert(
      threadId: unknownId,
      senderId: 'system',
      content:  Value(node.content),
      type:     const Value('system_label'),
      sequence: 0,
    ));

    _advance(node.nextNodeId);
  }

  void _handleS4VideoNode(StoryNode node, Map<String, dynamic> meta) {
    final assetPath = meta['file_asset'] as String?;
    if (assetPath == null) { _advance(node.nextNodeId); return; }

    final ctx = ref.read(appRouterProvider)
        .routerDelegate.navigatorKey.currentContext;
    if (ctx == null) { _advance(node.nextNodeId); return; }

    ref.read(activeNodeIdProvider.notifier).state = node.nextNodeId;
    // Requires media_viewer.dart: void open → Future<void> open
    MediaViewer.open(ctx,
            items: [MediaItem(path: assetPath, isVideo: true)])
        .then((_) => _advance(node.nextNodeId));
  }

  Future<void> _handleSecretHacked(
      StoryNode node, Map<String, dynamic> meta) async {
    ref.read(activeThreadIdProvider.notifier).state =
        'intercept_amelia_michael';
    ref.read(appRouterProvider).go(Routes.secret('intercept_amelia_michael'));
    _advance(node.nextNodeId);
  }

  void _handleS5ConnectionGlitch(
      StoryNode node, Map<String, dynamic> meta) {
    final ctx = ref.read(appRouterProvider)
        .routerDelegate.navigatorKey.currentContext;
    if (ctx == null) { _advance(node.nextNodeId); return; }

    final overlay = Overlay.of(ctx, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => GlitchOverlay(
        duration: const Duration(milliseconds: 1000),
        onComplete: () {
          entry.remove();
          ref.read(activeAppProvider.notifier).state = PhoneApp.phone;
          ref.read(appRouterProvider).go(Routes.messenger);
          _advance(node.nextNodeId);
        },
      ),
    );
    overlay.insert(entry);
  }

  void _handleS6AcceptCall(StoryNode node, Map<String, dynamic> meta) {
    ref.read(phoneProvider.notifier).startCall(
        'Unknown', 'Unknown Number', ref.read(gameClockProvider));
    ref.read(activeNodeIdProvider.notifier).state = node.nextNodeId;
    pause();
  }

  Future<void> _handleChatMessage(
      StoryNode node, Map<String, dynamic> meta) async {
    final db = ref.read(databaseProvider);
    final threadId = _resolveThreadId(node);

    await _ensureThread(threadId);

    final content = node.content ?? (meta['file_asset'] as String?) ?? '';
    final msgType = node.type == 'Video_Message' ? 'video' : 'text';

    final id = await db.into(db.messages).insert(
      MessagesCompanion.insert(
        nodeId:    Value(node.id),
        threadId:  threadId,
        senderId:  node.senderId ?? 'unknown',
        content:   Value(_sanitize(content)),
        type:      Value(msgType),
        mediaPath: Value(meta['file_asset'] as String?),
        sequence:  0,
        // isPlayerMessage stays false (default) for NPC messages.
      ),
    );

    await (db.update(db.threads)..where((t) => t.id.equals(threadId)))
        .write(ThreadsCompanion(lastMessageId: Value(id)));

    _playSound('sfx/message_receive.mp3');
    _advance(node.nextNodeId);
  }

  Future<void> _handleSystemLabel(
      StoryNode node, Map<String, dynamic> meta) async {
    final db = ref.read(databaseProvider);

    if (meta['action'] == 'Switch_Context') {
      final target = meta['target'] as String?;
      if (target == 'Private_Chat_Unknown') {
        ref.read(activeThreadIdProvider.notifier).state = 'unknown';
      } else if (target == 'Group_Dreadmoor_News') {
        ref.read(activeThreadIdProvider.notifier).state = 'group_dreadmoor_news';
      }
      _advance(node.nextNodeId);
      return;
    }

    if (meta['action'] == 'Push_Notification') {
      await db.updateStoryFlag('SCENE_1_NOTIFICATION_TRIGGER', bVal: true);
      _advance(node.nextNodeId);
      return;
    }

    final threadId = ref.read(activeThreadIdProvider) ?? 'unknown';
    await _ensureThread(threadId);

    await db.into(db.messages).insert(MessagesCompanion.insert(
      threadId: threadId,
      senderId: 'system',
      content:  Value(node.content),
      type:     const Value('system_label'),
      sequence: 0,
    ));
    _advance(node.nextNodeId);
  }

  void _handlePhoneCall(StoryNode node, Map<String, dynamic> meta) {
    final declineMeta = meta['next_on_decline'] as Map<String, dynamic>?;
    final canDecline = node.type != 'S6_Ringing_Final' && declineMeta != null;

    ref.read(phoneProvider.notifier).receiveIncomingCall(
      node.content ?? 'Unknown',
      node.senderId ?? 'Unknown Number',
      canDecline: canDecline,
      onDecline: () {
        if (canDecline && declineMeta != null) {
          final delay = (declineMeta['delay_seconds'] as int?) ?? 0;
          final target = declineMeta['target'] as String?;
          if (target != null) {
            Future.delayed(Duration(seconds: delay), () => _executeNode(target));
          }
        }
      },
      onAccept: () => _advance(node.nextNodeId),
    );
    pause();
  }

  void _handleChoiceRequired(StoryNode node) {
    _isSubmittingChoice = false; // reset for the new prompt
    ref.read(waitingForChoiceProvider.notifier).state = true;
    ref.read(activeNodeIdProvider.notifier).state = node.id;
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------

  /// FIX: ensure thread exists before writing isTyping.
  /// Also wraps timer body in try/catch — raw Timer callbacks swallow
  /// ALL exceptions, making the story freeze silently on any error.
  Future<void> _handleTyping(
      StoryNode node, Map<String, dynamic> meta) async {
    final db = ref.read(databaseProvider);
    final threadId = _resolveThreadId(node);
    final duration = (meta['duration'] as int?) ?? 2000;

    // Create thread first so the UPDATE below isn't a silent no-op.
    await _ensureThread(threadId);

    await (db.update(db.threads)..where((t) => t.id.equals(threadId)))
        .write(const ThreadsCompanion(isTyping: Value(true)));

    _timer = Timer(Duration(milliseconds: duration), () async {
      try {
        await (db.update(db.threads)..where((t) => t.id.equals(threadId)))
            .write(const ThreadsCompanion(isTyping: Value(false)));

        await _processNodeType(node, {...meta, 'action': 'None'});
      } catch (e, stack) {
        print("DreadmoorOS ✗ Typing timer failed for '${node.id}': $e");
        print(stack);
        // Fallback: turn off typing indicator and advance to next node
        // so a failed NPC message doesn't permanently freeze the story.
        try {
          await (db.update(db.threads)..where((t) => t.id.equals(threadId)))
              .write(const ThreadsCompanion(isTyping: Value(false)));
        } catch (_) {}
        _advance(node.nextNodeId);
      }
    });
  }

  /// Creates a thread row if it doesn't already exist.
  Future<void> _ensureThread(String threadId) async {
    final db = ref.read(databaseProvider);
    final exists = await (db.select(db.threads)
          ..where((t) => t.id.equals(threadId)))
        .getSingleOrNull();
    if (exists != null) return;

    String title        = 'Unknown';
    String participants = 'unknown';
    bool   isSecret     = false;

    switch (threadId) {
      case 'intercept_amelia_michael':
        title        = 'Amelia & Michael';
        participants = 'amelia,michael';
        isSecret     = true;
        break;
      case 'group_dreadmoor_news':
        title        = 'Dreadmoor News';
        participants = 'amelia,chris,abigail,michael';
        break;
    }

    await db.into(db.threads).insert(ThreadsCompanion.insert(
      id:           threadId,
      title:        title,
      participants: participants,
      isSecret:     Value(isSecret),
    ));

    print("DreadmoorOS ✓ Created thread '$threadId'");
  }

  String _resolveThreadId(StoryNode node) {
    if (node.metadata != null && node.metadata!.isNotEmpty) {
      try {
        final decoded = jsonDecode(node.metadata!) as Map<String, dynamic>;
        final chat = decoded['chat'] as String?;
        if (chat != null) {
          if (chat == 'Group_Dreadmoor_News')           return 'group_dreadmoor_news';
          if (chat == 'Private_Unknown')                 return 'unknown';
          if (chat == 'Secret_Intercept_Amelia_Michael') return 'intercept_amelia_michael';
        }
      } catch (_) {}
    }

    final id = node.id;
    if (id.contains('GROUP') || id.startsWith('s3_') || id.startsWith('S3_'))
      return 'group_dreadmoor_news';
    if (id.contains('SECRET') || id.contains('s4_intercept') ||
        id.startsWith('s5_') || id.startsWith('S5_'))
      return 'intercept_amelia_michael';

    return node.senderId ?? 'unknown';
  }

  String _sanitize(String? input) {
    if (input == null) return '';
    final name = ref.read(playerStateProvider)?.name ?? 'Detective';
    return input.replaceAll('[PlayerName]', name);
  }

  /// FIX: three changes vs original
  /// 1. isPlayerMessage: Value(true)  → bubble on right (player) side
  /// 2. _isSubmittingChoice guard     → no duplicate on double-tap
  /// 3. waiting=false set AFTER DB insert → no input bar flicker
  void submitChoice(String targetNodeId, String choiceText) {
    if (_isSubmittingChoice) return;
    _isSubmittingChoice = true;

    final db       = ref.read(databaseProvider);
    final threadId = ref.read(activeThreadIdProvider) ?? 'unknown';

    db.into(db.messages).insert(
      MessagesCompanion.insert(
        threadId:        threadId,
        senderId:        'player',
        content:         Value(choiceText),
        type:            const Value('text'),
        sequence:        0,
        isPlayerMessage: const Value(true),
      ),
    ).then((_) {
      ref.read(waitingForChoiceProvider.notifier).state = false;
      _executeNode(targetNodeId);
    }).catchError((e) {
      print("DreadmoorOS ✗ submitChoice insert failed: $e");
      _isSubmittingChoice = false;
    });
  }

  void completePuzzle() => resume();

  void pause() {
    _timer?.cancel();
    ref.read(isSchedulerPausedProvider.notifier).state = true;
  }

  void resume() {
    ref.read(isSchedulerPausedProvider.notifier).state = false;
    final nextId = ref.read(activeNodeIdProvider);
    if (nextId != null) _executeNode(nextId);
  }

  void _advance(String? nextId) {
    if (nextId != null && nextId.isNotEmpty) {
      ref.read(activeNodeIdProvider.notifier).state = nextId;
      _executeNode(nextId);
    }
  }

  Future<void> _playSound(String path) async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource(path));
    } catch (_) {}
  }
}
