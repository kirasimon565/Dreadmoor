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
//     Player_Choice       — Shows choice buttons; options in metadata.options
//     System_Event        — System actions: Push_Notification, Switch_Context,
//                           Add_To_Group, Trigger_Credits
//     System_Notification — Inline system label message in current thread
//     News_Module         — Shows article; metadata contains headline/body/etc
//     IncomingCall        — Phone call; metadata.caller_id, next_on_decline
//     Video_Message       — Video bubble in chat; metadata.file_asset
//
//   SPECIAL STATES (force-navigates to a specific screen):
//     Secret_Hacked       — Forces SecretChatScreen; metadata.thread_id required
//     Force_Ringing       — Disables decline button on IncomingCall
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
//   In your JSON, every message node must have:
//     "chat": "thread_id_here"
//
//   The thread is auto-created if it doesn't exist, using:
//     "thread_title":    "Display name"           (optional, defaults to thread_id)
//     "thread_members":  ["char1", "char2"]       (optional)
//     "thread_secret":   true                     (optional, defaults false)
//
//   Example:
//     {
//       "id": "ep02_msg_01",
//       "type": "Chat_Event",
//       "chat": "amelia_private",
//       "thread_title": "Amelia Stone",
//       "thread_members": ["amelia"],
//       "sender": "amelia",
//       "text": "We need to talk.",
//       "next": "ep02_msg_02"
//     }
// ─────────────────────────────────────────────────────────────────────────────

class GlobalScheduler {
  final Ref ref;
  Timer? _timer;
  final _rng = Random();
  bool _isSubmittingChoice = false;

  GlobalScheduler(this.ref);

  // --------------------------------------------------
  // CORE LIFECYCLE
  // --------------------------------------------------

  Future<void> processNode(String nodeId) async {
    _timer?.cancel();
    await seedCharacters(ref.read(databaseProvider));
    ref.read(isSchedulerPausedProvider.notifier).setPaused(false);
    ref.read(waitingForChoiceProvider.notifier).setWaiting(false);
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

    final delay =
        action == 'Pause' ? ((meta['duration'] as int?) ?? 2000) : 500;

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
  //
  // Each case maps to a BEHAVIOUR, not an episode.
  // New episodes reuse these same types — no new cases needed.
  // --------------------------------------------------

  Future<void> _processNodeType(
      StoryNode node, Map<String, dynamic> meta) async {
    await ref.read(databaseProvider).updateStoryFlag(node.id, bVal: true);

    switch (node.type) {
      // ── Chat message — any thread, any episode ─────────────────────────
      case 'Chat_Event':
      case 'Private_Unknown': // ep01 alias — kept for back-compat
      case 'Video_Message':
        await _handleChatMessage(node, meta);
        break;

      // ── Player makes a choice ──────────────────────────────────────────
      case 'Player_Choice':
        _handleChoiceRequired(node, meta);
        break;

      // ── System actions — data-driven via metadata.action ──────────────
      // Supported actions: Push_Notification, Switch_Context,
      //                    Add_To_Group, Trigger_Credits
      case 'System_Event':
      case 'System_Notification':
        await _handleSystemEvent(node, meta);
        break;

      // ── News article ──────────────────────────────────────────────────
      case 'News_Module':
        _handleNewsModule(node, meta);
        break;

      // ── Phone calls ───────────────────────────────────────────────────
      case 'IncomingCall':
      case 'Phone_Call_Event':
      case 'Force_Ringing': // disables decline button
        _handlePhoneCall(node, meta);
        break;

      // ── Force SecretChatScreen ────────────────────────────────────────
      // Requires metadata: { "thread_id": "some_thread_id" }
      case 'Secret_Hacked':
        await _handleSecretHacked(node, meta);
        break;

      // ── Full-screen video playback ────────────────────────────────────
      // Requires metadata: { "file_asset": "path/to/video.mp4" }
      case 'Video_Node':
      case 'S4_VIDEO_NODE': // ep01 alias — kept for back-compat
        // Treat as a chat message with video attached
        await _handleChatMessage(node, meta);
        break;

      // ── Screen glitch effect then navigate ───────────────────────────
      // Optional metadata: { "next_screen": "messenger" | "phone" }
      case 'Glitch_Effect':
      case 'S5_CONNECTION_GLITCH': // ep01 alias — kept for back-compat
        _handleGlitchEffect(node, meta);
        break;

      // ── Accept call — full screen UI ─────────────────────────────────
      // Optional metadata: { "audio_asset": "path/to/audio.mp3" }
      case 'Accept_Call':
      case 'S6_Accept_Call': // ep01 alias — kept for back-compat
        _handleAcceptCall(node, meta);
        break;

      default:
        // In debug: crash loudly so you know immediately.
        // In release: skip and advance so the story never permanently freezes.
        assert(
            false,
            "DreadmoorOS: Unhandled node type '${node.type}' "
            "on node '${node.id}'. Add a case or rename the type.");
        print("DreadmoorOS ✗ Unknown type '${node.type}' — advancing.");
        _advance(node.nextNodeId);
    }
  }

  // --------------------------------------------------
  // HANDLERS — all data-driven, no episode assumptions
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

    // Creates thread + members from JSON metadata if not already in DB.
    await _ensureThread(threadId, meta);

    final isVideo = node.type == 'Video_Message' ||
        node.type == 'Video_Node' ||
        node.type == 'S4_VIDEO_NODE';
    final content = node.content ?? (meta['file_asset'] as String?) ?? '';

    final mediaPath = meta['file_asset'] as String?;
    final mediaType =
        isVideo ? 'video' : (node.type == 'Image_Message' ? 'image' : 'text');
    final senderId = node.senderId ?? 'unknown';

    // TEMP: diagnostic log — remove once duplication is confirmed fixed.
    // If this prints twice for the same node ID, the scheduler is replaying.
    // Expected: exactly ONE line per node per session.
    print("🔥 INSERT ATTEMPT → ${node.id}");

    // FIX: skip if this node's message was already inserted (e.g. app restart).
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

    final activeThread = ref.read(activeThreadIdProvider);

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

    // Option B: insert immediately but pause until the player is viewing
    // this thread. If the thread is already active, advance normally.
    // If not, store the next node and wait — _resumeIfThreadActive() is
    // called by the scheduler whenever activeThreadId changes.
    if (activeThread == threadId) {
      _advance(node.nextNodeId);
    } else {
      // Pause and remember where to resume when the thread opens.
      print(
          "DreadmoorOS ⏸ '$threadId' not active — holding at '${node.nextNodeId}'");
      ref.read(isSchedulerPausedProvider.notifier).setPaused(true);
      ref.read(activeNodeIdProvider.notifier).setId(node.nextNodeId);
    }
  }

  // ── System Event — all actions data-driven ───────────────────────────────
  //
  // action: Push_Notification  → sets a story flag by name
  // action: Switch_Context     → changes active thread
  // action: Add_To_Group       → creates group thread + members from metadata
  // action: Trigger_Credits    → end of episode
  // (no action)                → inline system label message in current thread
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
          ref.read(waitingForPuzzleProvider.notifier).setWaiting(true);
          // CRITICAL: store the next node BEFORE pausing.
          // resume() calls _executeNode(activeNodeId) — if this isn't set
          // first, resume() has no continuation point and the story dies.
          ref.read(activeNodeIdProvider.notifier).setId(node.nextNodeId);
          pause();
          return;
        }

        _advance(node.nextNodeId);
        return;

      case 'Push_Notification':
        final title = meta['title'] as String?;
        final message = meta['message'] as String?;

        if (title != null && message != null) {
          // Normalise payload so the banner can always read `threadId`.
          // JSON nodes use `thread_id`; the banner reads `payload['threadId']`.
          // Spread meta first, then remap the key — consistent regardless of
          // how the JSON was authored.
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
        return; // CRITICAL: prevent any fallthrough

      case 'Switch_Context':
        // target: the thread ID to switch to
        final target = meta['target'] as String?;
        if (target != null) {
          ref.read(activeThreadIdProvider.notifier).setId(target);
        }
        _advance(node.nextNodeId);
        return;

      case 'Launch_Minigame':
        // Arcade-style minigames have been replaced with story-driven
        // puzzle mechanics (e.g., Diary Lock System).
        // This case is deprecated and left here for backward compatibility
        // or silent skipping.
        print("DreadmoorOS ⚠ Launch_Minigame is deprecated — skipping.");
        _advance(node.nextNodeId);
        return;

      case 'Add_To_Group':
        // Creates the group thread and members only.
        // Does NOT insert a system message — the group chat's first
        // Chat_Event node already inserts "[PlayerName] was added to
        // the group.", preventing duplication.
        final groupId = meta['thread_id'] as String?;
        if (groupId != null) {
          await _ensureThread(groupId, meta);
        }
        _advance(node.nextNodeId);
        return;

      case 'Trigger_Credits':
        // End of episode — handle as needed by your credits screen
        print("DreadmoorOS ✓ Episode complete — ${node.content}");
        ref.read(activeNodeIdProvider.notifier).setId(null);
        return;

      default:
        // No recognised action = inline system label in current thread
        final threadId = ref.read(activeThreadIdProvider) ?? 'unknown';
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

    // flag_name lets each episode use its own unlock flag
    final flag = (meta['flag_name'] as String?) ?? 'article_read';
    db.updateStoryFlag(flag, bVal: true);

    ref.read(activeAppProvider.notifier).setApp(PhoneApp.browser);
    ref.read(appRouterProvider).go(Routes.messenger);

    _advance(node.nextNodeId);
  }

  // ── Phone Call ───────────────────────────────────────────────────────────
  void _handlePhoneCall(StoryNode node, Map<String, dynamic> meta) {
    final declineMeta = meta['next_on_decline'] as Map<String, dynamic>?;
    // Force_Ringing type OR explicit disable_decline flag disables the button
    final canDecline = node.type != 'Force_Ringing' &&
        node.type != 'S6_Ringing_Final' &&
        (meta['disable_decline'] != true) &&
        declineMeta != null;

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

  // ── Secret Hacked — switch context to secret thread ─────────────────────
  // Requires metadata: { "thread_id": "...", "thread_title": "...",
  //                      "thread_members": [...], "thread_secret": true }
  // Behaves like Switch_Context: ensures thread exists, sets activeThreadId,
  // then immediately advances. No navigation, no delays.
  Future<void> _handleSecretHacked(
      StoryNode node, Map<String, dynamic> meta) async {
    final threadId =
        (meta['thread_id'] as String?) ?? _resolveThreadId(node, meta);

    // Force thread_secret = true regardless of what meta says
    final enrichedMeta = {
      ...meta,
      'thread_secret': true,
    };

    await _ensureThread(threadId, enrichedMeta);
    ref.read(activeThreadIdProvider.notifier).setId(threadId);
    _advance(node.nextNodeId);
  }

  // ── Video Node — full-screen media viewer ────────────────────────────────
  // Requires metadata: { "file_asset": "assets/video/clip.mp4" }
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

    ref.read(activeNodeIdProvider.notifier).setId(node.nextNodeId);
    // Requires media_viewer.dart: void open → Future<void> open
    MediaViewer.open(ctx,
            items: [GalleryMediaItem(path: assetPath, isVideo: true)])
        .then((_) => _advance(node.nextNodeId));
  }

  // ── Glitch Effect ────────────────────────────────────────────────────────
  // Optional metadata: { "next_screen": "messenger" | "phone" }
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

    final audioPath = meta['audio_asset'] as String?; // ✅ NEW

    ref.read(phoneProvider.notifier).startCall(
          callerName,
          callerId,
          ref.read(gameClockProvider),
        );

    // FIX: use public notifier method instead of directly setting .state
    // In Riverpod 3, Notifier.state is protected — external assignment silently
    // fails, so callAudioPath was never stored and ActiveCallScreen got null.
    if (audioPath != null) {
      ref.read(phoneProvider.notifier).setCallAudioPath(audioPath);
    }

    ref.read(activeNodeIdProvider.notifier).setId(node.nextNodeId);
    pause();
  }

  // ── Choice Required ──────────────────────────────────────────────────────
  void _handleChoiceRequired(StoryNode node, Map<String, dynamic> meta) {
    _isSubmittingChoice = false;
    final threadId = _resolveThreadId(node, meta);

    if (threadId.isNotEmpty) {
      ref.read(activeThreadIdProvider.notifier).setId(threadId);

      // FIX: navigate to the thread the choice belongs to.
      // Without this, ChoiceOverlay renders over whatever screen the player
      // is currently on. If they're in group chat and the choice is for the
      // 'unknown' private thread, the choice appears in the wrong chat.
      final currentThread = ref.read(activeThreadIdProvider);
      if (currentThread != threadId) {
        ref.read(appRouterProvider).go(Routes.chat(threadId));
      }
    }

    ref.read(waitingForChoiceProvider.notifier).setWaiting(true);
    ref.read(activeNodeIdProvider.notifier).setId(node.id);
    ref
        .read(databaseProvider)
        .updateStoryFlag('active_choice_id', sVal: node.id);
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------

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

        // Option B: only process the node (which calls _handleChatMessage)
        // if the thread is currently active. If not, pause and wait.
        final activeThread = ref.read(activeThreadIdProvider);
        if (activeThread == threadId) {
          await _processNodeType(node, {...meta, 'action': 'None'});
        } else {
          print(
              "DreadmoorOS ⏸ Typing done — '$threadId' not active, holding at '${node.id}'");
          ref.read(isSchedulerPausedProvider.notifier).setPaused(true);
          // Store this node so resume() re-executes it (typing + message)
          ref.read(activeNodeIdProvider.notifier).setId(node.id);
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

  // ── Thread Resolution — 100% data-driven ─────────────────────────────────
  //
  // Priority order:
  //   1. metadata.chat       — explicit thread ID in the JSON node (preferred)
  //   2. metadata.thread_id  — alternative key used by system nodes
  //   3. activeThreadId      — whatever thread is currently open
  //   4. node.senderId       — last resort fallback
  //
  // NO node ID pattern matching. NO hardcoded thread IDs.
  String _resolveThreadId(StoryNode node, Map<String, dynamic> meta) {
    final chat = meta['chat'] as String?;
    final threadId = meta['thread_id'] as String?;

    if (chat != null && chat.isNotEmpty) return chat;
    if (threadId != null && threadId.isNotEmpty) return threadId;

    // Fall back to currently active thread if the JSON didn't specify
    final active = ref.read(activeThreadIdProvider);
    if (active != null && active.isNotEmpty) return active;

    return node.senderId ?? 'unknown';
  }

  // ── Thread Creation — fully data-driven ──────────────────────────────────
  //
  // All thread metadata comes from the JSON node:
  //   thread_title:   display name in messenger list
  //   thread_members: list of character IDs
  //   thread_secret:  true/false
  //
  // If not provided, thread is created with the threadId as title
  // and no members (safe — chat still works, header shows fallback avatar).
  Future<void> _ensureThread(String threadId, Map<String, dynamic> meta) async {
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
    if (_isSubmittingChoice) return;
    _isSubmittingChoice = true;

    final db = ref.read(databaseProvider);
    final threadId = ref.read(activeThreadIdProvider) ?? 'unknown';

    // Player choices carry no time_passed — replies are instant (0 minutes).
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
      ref.read(waitingForChoiceProvider.notifier).setWaiting(false);
      _executeNode(targetNodeId);
    }).catchError((e) {
      print("DreadmoorOS ✗ submitChoice failed: $e");
      _isSubmittingChoice = false;
    });
  }

  void completePuzzle() {
    // FIX: clear waitingForPuzzle before resuming.
    // Without this the scheduler stays paused because
    // waitingForPuzzleProvider is never set back to false.
    ref.read(waitingForPuzzleProvider.notifier).setWaiting(false);
    resume();
  }

  /// Called when the minigame ends in failure.
  /// Keeps the scheduler paused so the player must retry
  /// before the story can continue.
  void onPuzzleFailed() => pause();

  /// Called by ChatScreen and SecretChatScreen in initState when the
  /// player opens a thread. If the scheduler is paused waiting for this
  /// exact thread, it resumes from the stored activeNodeId.
  ///
  /// REPLAY SAFETY: when _handleChatMessage pauses (thread not active), it
  /// stores node.nextNodeId — the NEXT node — not the current one.
  /// So resumeIfThreadActive always advances forward, never re-runs the
  /// message that triggered the pause. The 🔥 INSERT ATTEMPT log should
  /// appear exactly once per node even when the player taps a notification
  /// to open the thread.
  ///
  /// The notification banner onTap itself does NOT call processNode, resume,
  /// or _advance — it only sets state and navigates. Scheduler continuation
  /// happens here, one level up, driven by ChatScreen.initState.
  void resumeIfThreadActive(String threadId) {
    final isPaused = ref.read(isSchedulerPausedProvider);
    if (!isPaused) return;

    final nextNodeId = ref.read(activeNodeIdProvider);
    if (nextNodeId == null || nextNodeId.isEmpty) return;

    final active = ref.read(activeThreadIdProvider);
    if (active == threadId) {
      print(
          "DreadmoorOS ▶ Thread '$threadId' opened — resuming at '$nextNodeId'");
      resume();
    }
  }

  void pause() {
    _timer?.cancel();
    ref.read(isSchedulerPausedProvider.notifier).setPaused(true);
  }

  void resume() {
    ref.read(isSchedulerPausedProvider.notifier).setPaused(false);
    final nextId = ref.read(activeNodeIdProvider);
    if (nextId != null) _executeNode(nextId);
  }

  void _advance(String? nextId) {
    if (nextId != null && nextId.isNotEmpty) {
      ref.read(activeNodeIdProvider.notifier).setId(nextId);
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
