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
import 'package:dreadmoor/features/diary/diary_scheduler_link.dart';
import 'package:dreadmoor/features/diary/diary_controller.dart';
import '../state/game_state.dart';
import '../state/scheduler_state.dart';
import '../persistence/seed_characters.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GLOBAL SCHEDULER
//
// Design principle: ZERO hardcoded episode logic.
// Every routing decision comes from the node's JSON metadata, not from
// node ID patterns or episode-specific type strings.
//
// How to add a new episode:
//   1. Add scenes to EpisodeManifest
//   2. Use the standard node types below in your JSON
//   3. Put ALL thread/context info in the JSON metadata fields
//   No changes to this file required.
//
// ── SUPPORTED NODE TYPES ─────────────────────────────────────────────────────
//
//   GENERIC (work in any episode):
//     Chat_Event          — NPC message in the thread defined by metadata.chat
//     Typing              — Shows typing indicator; metadata.duration (ms)
//     Pause               — Delays execution; metadata.duration (ms)
//                           Also supports metadata.time_passed for clock advance
//     Player_Choice       — Shows choice buttons; options in metadata.options
//                           Inherits thread context (no "chat" needed)
//     System_Event        — System actions: Push_Notification, Switch_Context,
//                           Add_To_Group, Trigger_Credits, Open_Diary_Lock
//     System_Notification — Inline system label message in current thread
//     News_Module         — Shows article; metadata contains headline/body/etc
//     IncomingCall        — Phone call; metadata.caller_id, next_on_decline,
//                           disable_decline (set true to force answer)
//     Video_Message       — Video bubble in chat; metadata.file_asset
//
//   SPECIAL STATES (force-navigates to a specific screen):
//     Secret_Hacked       — Forces SecretChatScreen; metadata.thread_id required
//
//   CINEMATIC EFFECTS:
//     Glitch_Effect       — Screen glitch then navigates to metadata.next_screen
//     Accept_Call         — Full-screen call UI; metadata.audio_asset
//
// ── HOW THREAD ROUTING WORKS ─────────────────────────────────────────────────
//
//   Thread is determined exclusively from metadata.chat in the JSON node.
//   No node ID pattern matching. No hardcoded thread IDs in this file.
//
//   In your JSON, message nodes that start a new thread need:
//     "chat": "thread_id_here"
//
//   Nodes that continue in the current thread should OMIT "chat" —
//   they inherit context from Switch_Context or the previous node.
//
//   The thread is auto-created if it doesn't exist, using:
//     "thread_title":    "Display name"           (optional, defaults to thread_id)
//     "thread_members":  ["char1", "char2"]       (optional)
//     "thread_secret":   true                     (optional, defaults false)
//
// ── FORCE CALLS (any episode) ────────────────────────────────────────────────
//
//   Use IncomingCall type with "disable_decline": true in metadata.
//   No special node type needed:
//     {
//       "id": "ep05_forced_call",
//       "type": "IncomingCall",
//       "caller_name": "Unknown",
//       "disable_decline": true,
//       "next": "ep05_after_call"
//     }
// ─────────────────────────────────────────────────────────────────────────────

class GlobalScheduler {
  final Ref ref;
  Timer? _timer;
  final _rng = Random();

  GlobalScheduler(this.ref);

  // ── Convenience accessors for the consolidated state ────────────────────
  SchedulerState get _state => ref.read(schedulerStateProvider);
  SchedulerStateNotifier get _stateNotifier =>
      ref.read(schedulerStateProvider.notifier);

  // --------------------------------------------------
  // CORE LIFECYCLE
  // --------------------------------------------------

  Future<void> processNode(String nodeId) async {
    _timer?.cancel();
    await seedCharacters(ref.read(databaseProvider));
    _stateNotifier.update((s) => const SchedulerState());
    await _executeNode(nodeId);
  }

  Future<void> _executeNode(String nodeId) async {
    if (nodeId.isEmpty) return;

    final db = ref.read(databaseProvider);
    final node = await db.getNextNode(nodeId);

    if (node == null) {
      print("DreadmoorOS ✗ Node '$nodeId' not found."
          " Was importPendingEpisodes() called?");
      return;
    }

    Map<String, dynamic> meta = {};
    if (node.metadata != null && node.metadata!.isNotEmpty) {
      try {
        meta = jsonDecode(node.metadata!) as Map<String, dynamic>;
      } catch (e) {
        print("DreadmoorOS ✗ Bad metadata on '$nodeId': $e");
      }
    }

    final action = (meta['action'] as String?) ?? '';
    print("DreadmoorOS → '$nodeId' [${node.type}]"
        "${action.isNotEmpty ? ' action=$action' : ''}");

    if (action == 'Typing') {
      await _handleTyping(node, meta);
      return;
    }

    final delay = 500;

    _timer = Timer(Duration(milliseconds: delay), () async {
      try {
        await _processNodeType(node, meta);
      } catch (e, st) {
        print("DreadmoorOS ✗ processNodeType failed on '$nodeId': $e\n$st");
        _advance(node.nextNodeId);
      }
    });
  }

  // --------------------------------------------------
  // NODE TYPE DISPATCHER
  // --------------------------------------------------

  Future<void> _processNodeType(
      StoryNode node, Map<String, dynamic> meta) async {
    await ref.read(databaseProvider).updateStoryFlag(node.id, bVal: true);

    switch (node.type) {
      // ── Chat message — any thread, any episode ─────────────────────────
      case 'Chat_Event':
      case 'Video_Message':
        await _handleChatMessage(node, meta);
        break;

      // ── Delay-only — no message, supports time_passed for clock ────────
      case 'Pause':
        await _handlePause(node, meta);
        break;

      // ── Player makes a choice — inherits thread context ────────────────
      case 'Player_Choice':
        _handleChoiceRequired(node, meta);
        break;

      // ── System actions — data-driven via metadata.action ──────────────
      case 'System_Event':
      case 'System_Notification':
        await _handleSystemEvent(node, meta);
        break;

      // ── News article ──────────────────────────────────────────────────
      case 'News_Module':
        _handleNewsModule(node, meta);
        break;

      // ── Phone calls ───────────────────────────────────────────────────
      // disable_decline in metadata forces answer (no special type needed)
      case 'IncomingCall':
      case 'Phone_Call_Event':
        _handlePhoneCall(node, meta);
        break;

      // ── Force SecretChatScreen ────────────────────────────────────────
      case 'Secret_Hacked':
        await _handleSecretHacked(node, meta);
        break;

      // ── Screen glitch effect then navigate ───────────────────────────
      case 'Glitch_Effect':
        _handleGlitchEffect(node, meta);
        break;

      // ── Accept call — full screen UI ─────────────────────────────────
      case 'Accept_Call':
        _handleAcceptCall(node, meta);
        break;

      // ── BACKWARD COMPATIBILITY ALIASES ────────────────────────────────
      // These exist only to support old episode JSON.
      // New episodes must use the standard types above.
      case 'Private_Unknown': // ep01 — use Chat_Event instead
      case 'S4_VIDEO_NODE': // ep01 — use Video_Message instead
      case 'Video_Node': // old name — use Video_Message instead
        await _handleChatMessage(node, meta);
        break;

      case 'S5_CONNECTION_GLITCH': // ep01 — use Glitch_Effect instead
        _handleGlitchEffect(node, meta);
        break;

      case 'S6_Accept_Call': // ep01 — use Accept_Call instead
        _handleAcceptCall(node, meta);
        break;

      case 'Force_Ringing': // old — use IncomingCall + disable_decline
      case 'S6_Ringing_Final': // ep01 — use IncomingCall + disable_decline
        _handlePhoneCall(node, {...meta, 'disable_decline': true});
        break;

      default:
        assert(
            false,
            "DreadmoorOS: Unhandled node type '${node.type}' "
            "on node '${node.id}'. Add a case or rename the type.");
        print("DreadmoorOS ✗ Unknown type '${node.type}' — advancing.");
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

  // ── Chat Message ─────────────────────────────────────────────────────────
  Future<void> _handleChatMessage(
      StoryNode node, Map<String, dynamic> meta) async {
    final db = ref.read(databaseProvider);
    final threadId = _resolveThreadId(node, meta);

    await _ensureThread(threadId, meta);

    final isVideo = node.type == 'Video_Message' ||
        node.type == 'Video_Node' ||
        node.type == 'S4_VIDEO_NODE';
    final content = node.content ?? (meta['file_asset'] as String?) ?? '';

    final mediaPath = meta['file_asset'] as String?;
    final mediaType =
        isVideo ? 'video' : (node.type == 'Image_Message' ? 'image' : 'text');
    final senderId = node.senderId ?? 'unknown';

    // Duplicate prevention for app restarts
    if (node.id.isNotEmpty) {
      final exists = await (db.select(db.messages)
            ..where((m) => m.nodeId.equals(node.id)))
          .getSingleOrNull();

      if (exists != null) {
        print("DreadmoorOS ⚠ Duplicate prevented for node '${node.id}'");
        _advance(node.nextNodeId);
        return;
      }
    }

    // Time is story-driven: time_passed is explicit in JSON.
    // duration is UI pacing only — never used for clock progression.
    final timePassed = (meta['time_passed'] as int?) ?? 0;
    ref.read(gameClockProvider.notifier).advanceTime(timePassed);
    final minutes = ref.read(gameClockProvider);
    final dt = getGameDateTime(minutes);

    final id = await db.into(db.messages).insert(
          MessagesCompanion.insert(
            nodeId: Value(node.id),
            threadId: threadId,
            senderId: senderId,
            content: Value(_sanitize(content)),
            type: Value(mediaType),
            mediaPath: Value(mediaPath),
            sequence: 0,
            timestamp: Value(dt),
          ),
        );

    // Save media to gallery table automatically
    if (mediaPath != null && (mediaType == 'video' || mediaType == 'image')) {
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              threadId: threadId,
              senderId: senderId,
              mediaType: mediaType,
              filePath: mediaPath,
            ),
          );
    }

    await (db.update(db.threads)..where((t) => t.id.equals(threadId)))
        .write(ThreadsCompanion(lastMessageId: Value(id)));

    final activeThread = _state.activeThreadId;

    if (activeThread != threadId) {
      final thread = await (db.select(db.threads)
            ..where((t) => t.id.equals(threadId)))
          .getSingleOrNull();

      final threadTitle = thread?.title ?? threadId;

      await db.into(db.notifications).insert(
            NotificationsCompanion.insert(
              id: 'msg_${node.id}',
              type: 'chat',
              title: threadTitle,
              message: _sanitize(content),
              createdAtMinutes: ref.read(gameClockProvider),
              payload: Value(jsonEncode({
                'threadId': threadId,
              })),
            ),
          );
    }

    _playSound('sfx/message_receive.mp3');

    if (activeThread == threadId) {
      _advance(node.nextNodeId);
    } else {
      print(
          "DreadmoorOS ⏸ '$threadId' not active — holding at '${node.nextNodeId}'");
      _stateNotifier.pauseAt(node.nextNodeId ?? '');
    }
  }

  // ── System Event — all actions data-driven ───────────────────────────────
  Future<void> _handleSystemEvent(
      StoryNode node, Map<String, dynamic> meta) async {
    final db = ref.read(databaseProvider);
    final action = (meta['action'] as String?) ?? '';

    switch (action) {
      case 'Open_Diary_Lock':
        final word = meta['word'] as String?;
        final pageId = meta['pageId'] as String?;

        if (word == null || word.isEmpty || pageId == null || pageId.isEmpty) {
          print("DreadmoorOS ⚠ Open_Diary_Lock missing data — skipping.");
          _advance(node.nextNodeId);
          return;
        }

        final controller = ref.read(diaryProvider.notifier);
        await controller.init(word, pageId);

        await db.updateStoryFlag('diaryUnlocked', bVal: true);

        final shouldPause = await handleDiary(ref, word, pageId);

        if (shouldPause) {
          _stateNotifier.startPuzzle(node.nextNodeId ?? '');
          pause();
          return;
        }

        _advance(node.nextNodeId);
        return;

      case 'Push_Notification':
        final title = meta['title'] as String?;
        final message = meta['message'] as String?;

        if (title != null && message != null) {
          final notifPayload = <String, dynamic>{
            ...meta,
            if (meta['thread_id'] != null) 'threadId': meta['thread_id'],
          };

          await db.into(db.notifications).insert(
                NotificationsCompanion.insert(
                  id: node.id,
                  type: 'system',
                  title: title,
                  message: message,
                  createdAtMinutes: 0,
                  payload: Value(jsonEncode(notifPayload)),
                ),
              );
        }

        _advance(node.nextNodeId);
        return;

      case 'Switch_Context':
        final target = meta['target'] as String?;
        if (target != null) {
          _stateNotifier.switchThread(target);
        }
        _advance(node.nextNodeId);
        return;

      case 'Launch_Minigame':
        print("DreadmoorOS ⚠ Launch_Minigame is deprecated — skipping.");
        _advance(node.nextNodeId);
        return;

      case 'Add_To_Group':
        final groupId = meta['thread_id'] as String?;
        if (groupId != null) {
          await _ensureThread(groupId, meta);
        }
        _advance(node.nextNodeId);
        return;

      case 'Trigger_Credits':
        print("DreadmoorOS ✓ Episode complete — ${node.content}");
        _stateNotifier.update((s) => s.copyWith(clearActiveNodeId: true));
        return;

      default:
        final threadId = _state.activeThreadId ?? 'unknown';
        await _ensureThread(threadId, {});
        await db.into(db.messages).insert(MessagesCompanion.insert(
              threadId: threadId,
              senderId: 'system',
              content: Value(node.content),
              type: const Value('system_label'),
              sequence: 0,
            ));
        _advance(node.nextNodeId);
    }
  }

  // ── News Module ──────────────────────────────────────────────────────────
  void _handleNewsModule(StoryNode node, Map<String, dynamic> meta) {
    final db = ref.read(databaseProvider);

    db.into(db.notifications).insert(
          NotificationsCompanion.insert(
            id: 'news_${node.id}',
            type: 'article',
            title: (meta['notification_title'] as String?) ?? 'News Alert',
            message: (meta['notification_body'] as String?) ??
                'A new article is available.',
            createdAtMinutes: 0,
            payload: Value(jsonEncode({
              'article': {
                'headline': meta['headline'] ?? '',
                'subheadline': meta['subheadline'] ?? '',
                'photo': meta['image_asset'] ?? '',
                'caption': meta['caption'] ?? '',
                'body': meta['body'] ?? [],
              }
            })),
          ),
          mode: InsertMode.insertOrReplace,
        );

    final flag = (meta['flag_name'] as String?) ?? 'article_read';
    db.updateStoryFlag(flag, bVal: true);

    ref.read(activeAppProvider.notifier).setApp(PhoneApp.browser);
    ref.read(appRouterProvider).go(Routes.messenger);

    _advance(node.nextNodeId);
  }

  // ── Phone Call — data-driven, no hardcoded types ─────────────────────────
  void _handlePhoneCall(StoryNode node, Map<String, dynamic> meta) {
    final declineMeta = meta['next_on_decline'] as Map<String, dynamic>?;
    final disableDecline = meta['disable_decline'] == true;

    // Can decline only if: not disabled AND decline metadata exists
    final canDecline = !disableDecline && declineMeta != null;

    final callerName =
        (meta['caller_name'] as String?) ?? node.content ?? 'Unknown';
    final callerNumber =
        (meta['caller_id'] as String?) ?? node.senderId ?? 'Unknown Number';

    ref.read(phoneProvider.notifier).receiveIncomingCall(
          callerName,
          callerNumber,
          canDecline: canDecline,
          onDecline: () {
            if (declineMeta != null) {
              final delay = (declineMeta['delay_seconds'] as int?) ?? 0;
              final target = declineMeta['target'] as String?;
              if (target != null) {
                Future.delayed(
                    Duration(seconds: delay), () => _executeNode(target));
              }
            }
          },
          onAccept: () => _advance(node.nextNodeId),
        );
    pause();
  }

  // ── Secret Hacked ────────────────────────────────────────────────────────
  Future<void> _handleSecretHacked(
      StoryNode node, Map<String, dynamic> meta) async {
    final threadId =
        (meta['thread_id'] as String?) ?? _resolveThreadId(node, meta);

    final enrichedMeta = {
      ...meta,
      'thread_secret': true,
    };

    await _ensureThread(threadId, enrichedMeta);
    _stateNotifier.switchThread(threadId);
    _advance(node.nextNodeId);
  }

  // ── Video Node — full-screen media viewer ────────────────────────────────
  void _handleVideoNode(StoryNode node, Map<String, dynamic> meta) {
    final assetPath = meta['file_asset'] as String?;
    if (assetPath == null) {
      print("DreadmoorOS ✗ Video_Node '${node.id}' missing file_asset.");
      _advance(node.nextNodeId);
      return;
    }

    final ctx =
        ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
    if (ctx == null) {
      _advance(node.nextNodeId);
      return;
    }

    _stateNotifier.update((s) => s.copyWith(activeNodeId: node.nextNodeId));
    MediaViewer.open(ctx,
            items: [GalleryMediaItem(path: assetPath, isVideo: true)])
        .then((_) => _advance(node.nextNodeId));
  }

  // ── Glitch Effect ────────────────────────────────────────────────────────
  void _handleGlitchEffect(StoryNode node, Map<String, dynamic> meta) {
    final ctx =
        ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
    if (ctx == null) {
      _advance(node.nextNodeId);
      return;
    }

    final duration = Duration(milliseconds: (meta['duration'] as int?) ?? 1000);
    final nextScreen = (meta['next_screen'] as String?) ?? 'messenger';

    final overlay = Overlay.of(ctx, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => GlitchOverlay(
        duration: duration,
        onComplete: () {
          entry.remove();
          if (nextScreen == 'phone') {
            ref.read(activeAppProvider.notifier).setApp(PhoneApp.phone);
          }
          ref.read(appRouterProvider).go(Routes.messenger);
          _advance(node.nextNodeId);
        },
      ),
    );
    overlay.insert(entry);
  }

  // ── Accept Call — full-screen call UI ────────────────────────────────────
  void _handleAcceptCall(StoryNode node, Map<String, dynamic> meta) {
    final callerName = (meta['caller_name'] as String?) ?? 'Unknown';
    final callerId = (meta['caller_id'] as String?) ?? 'Unknown Number';
    final audioPath = meta['audio_asset'] as String?;

    ref.read(phoneProvider.notifier).startCall(
          callerName,
          callerId,
          ref.read(gameClockProvider),
        );

    if (audioPath != null) {
      ref.read(phoneProvider.notifier).setCallAudioPath(audioPath);
    }

    _stateNotifier.update((s) => s.copyWith(activeNodeId: node.nextNodeId));
    pause();
  }

  // ── Choice Required — context-first thread resolution ────────────────────
  void _handleChoiceRequired(StoryNode node, Map<String, dynamic> meta) {
    _stateNotifier.setSubmitting(false);

    // Only use explicit "chat" if set. Otherwise inherit active thread.
    final explicitChat = (meta['chat'] as String?)?.isNotEmpty == true
        ? meta['chat'] as String
        : null;
    final threadId = explicitChat ?? _state.activeThreadId ?? 'unknown';

    // Always ensure the active thread matches where the choice appears
    _stateNotifier.switchThread(threadId);

    // Navigate to the thread if we're not already looking at it
    if (_state.activeThreadId != threadId || explicitChat != null) {
      ref.read(appRouterProvider).go(Routes.chat(threadId));
    }

    _stateNotifier.startChoice(node.id, threadId);
    ref
        .read(databaseProvider)
        .updateStoryFlag('active_choice_id', sVal: node.id);
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------

  // ── Pause — delay only, supports time_passed for game clock ──────────────
  Future<void> _handlePause(StoryNode node, Map<String, dynamic> meta) async {
    await ref.read(databaseProvider).updateStoryFlag(node.id, bVal: true);

    // Advance game time if the pause represents a narrative time jump
    final timePassed = (meta['time_passed'] as int?) ?? 0;
    if (timePassed > 0) {
      ref.read(gameClockProvider.notifier).advanceTime(timePassed);
    }

    final delay = (meta['duration'] as int?) ?? 2000;

    _timer = Timer(Duration(milliseconds: delay), () {
      _advance(node.nextNodeId);
    });
  }

  Future<void> _handleTyping(StoryNode node, Map<String, dynamic> meta) async {
    final db = ref.read(databaseProvider);
    final threadId = _resolveThreadId(node, meta);
    final duration = (meta['duration'] as int?) ?? 2000;

    await _ensureThread(threadId, meta);
    await (db.update(db.threads)..where((t) => t.id.equals(threadId)))
        .write(const ThreadsCompanion(isTyping: Value(true)));

    _timer = Timer(Duration(milliseconds: duration), () async {
      try {
        await (db.update(db.threads)..where((t) => t.id.equals(threadId)))
            .write(const ThreadsCompanion(isTyping: Value(false)));

        final activeThread = _state.activeThreadId;
        if (activeThread == threadId) {
          await _processNodeType(node, {...meta, 'action': 'None'});
        } else {
          print(
              "DreadmoorOS ⏸ Typing done — '$threadId' not active, holding at '${node.id}'");
          _stateNotifier.pauseAt(node.id);
        }
      } catch (e, st) {
        print("DreadmoorOS ✗ Typing timer failed on '${node.id}': $e\n$st");
        try {
          await (db.update(db.threads)..where((t) => t.id.equals(threadId)))
              .write(const ThreadsCompanion(isTyping: Value(false)));
        } catch (_) {}
        _advance(node.nextNodeId);
      }
    });
  }

  // ── Thread Resolution ────────────────────────────────────────────────────
  String _resolveThreadId(StoryNode node, Map<String, dynamic> meta) {
    final chat = meta['chat'] as String?;
    final threadId = meta['thread_id'] as String?;

    if (chat != null && chat.isNotEmpty) return chat;
    if (threadId != null && threadId.isNotEmpty) return threadId;

    final active = _state.activeThreadId;
    if (active != null && active.isNotEmpty) return active;

    return node.senderId ?? 'unknown';
  }

  // ── Thread Creation ──────────────────────────────────────────────────────
  Future<void> _ensureThread(
      String threadId, Map<String, dynamic> meta) async {
    final db = ref.read(databaseProvider);

    final exists = await (db.select(db.threads)
          ..where((t) => t.id.equals(threadId)))
        .getSingleOrNull();

    if (exists != null) return;

    final title = (meta['thread_title'] as String?) ?? threadId;
    final members =
        (meta['thread_members'] as List?)?.cast<String>() ?? <String>[];
    final isSecret = (meta['thread_secret'] as bool?) ?? false;
    final participants = members.isNotEmpty ? members.join(',') : threadId;

    await db.into(db.threads).insert(ThreadsCompanion.insert(
          id: threadId,
          title: title,
          participants: participants,
          isSecret: Value(isSecret),
        ));

    for (final memberId in members) {
      final charExists = await (db.select(db.characters)
            ..where((c) => c.id.equals(memberId)))
          .getSingleOrNull();
      if (charExists != null) {
        await db.into(db.threadMembers).insertOnConflictUpdate(
              ThreadMembersCompanion.insert(
                  threadId: threadId, characterId: memberId),
            );
      }
    }

    print("DreadmoorOS ✓ Thread '$threadId' "
        "(${members.length} members, secret=$isSecret)");
  }

  String _sanitize(String? input) {
    if (input == null) return '';
    return input.replaceAll(
        '[PlayerName]', ref.read(playerStateProvider)?.name ?? 'Detective');
  }

  void submitChoice(String targetNodeId, String choiceText) {
    final state = _state;
    if (state.isSubmittingChoice) return;
    _stateNotifier.setSubmitting(true);

    final db = ref.read(databaseProvider);
    final threadId = state.activeThreadId ?? 'unknown';

    // Player choices are instant (0 minutes)
    ref.read(gameClockProvider.notifier).advanceTime(0);
    final minutes = ref.read(gameClockProvider);
    final dt = getGameDateTime(minutes);

    db
        .into(db.messages)
        .insert(
          MessagesCompanion.insert(
            threadId: threadId,
            senderId: 'player',
            content: Value(choiceText),
            type: const Value('text'),
            sequence: 0,
            isPlayerMessage: const Value(true),
            timestamp: Value(dt),
          ),
        )
        .then((_) async {
      await (db.delete(db.storyState)
            ..where((t) => t.key.equals('active_choice_id')))
          .go();
      _stateNotifier.completeChoice(targetNodeId);
      _executeNode(targetNodeId);
    }).catchError((e) {
      print("DreadmoorOS ✗ submitChoice failed: $e");
      _stateNotifier.setSubmitting(false);
    });
  }

  void completePuzzle() {
    _stateNotifier.completePuzzle();
    resume();
  }

  void onPuzzleFailed() => pause();

  void resumeIfThreadActive(String threadId) {
    final state = _state;
    if (!state.isPaused) return;

    final nextNodeId = state.activeNodeId;
    if (nextNodeId == null || nextNodeId.isEmpty) return;

    if (state.activeThreadId == threadId) {
      print(
          "DreadmoorOS ▶ Thread '$threadId' opened — resuming at '$nextNodeId'");
      resume();
    }
  }

  void pause() {
    _timer?.cancel();
    _stateNotifier.update((s) => s.copyWith(isPaused: true));
  }

  void resume() {
    _stateNotifier.update((s) => s.copyWith(isPaused: false));
    final nextId = _state.activeNodeId;
    if (nextId != null) _executeNode(nextId);
  }

  void _advance(String? nextId) {
    if (nextId != null && nextId.isNotEmpty) {
      _stateNotifier.update((s) => s.copyWith(activeNodeId: nextId));
      _executeNode(nextId);
    }
  }

  Future<void> _playSound(String path) async {
    try {
      await AudioPlayer().play(AssetSource(path));
    } catch (_) {}
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
