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

  GlobalScheduler(this.ref);

  // --------------------------------------------------
  // CORE LIFECYCLE
  // --------------------------------------------------

  /// Starts the story from a specific Node ID (e.g., 'SCENE_1_NEWS_ARTICLE')
  Future<void> processNode(String nodeId) async {
    _timer?.cancel();
    
    final db = ref.read(databaseProvider);
    
    // 1. Ensure characters are seeded for UI lookups
    await seedCharacters(db);

    // 2. Set global state
    ref.read(isSchedulerPausedProvider.notifier).state = false;
    ref.read(waitingForChoiceProvider.notifier).state = false;

    // 3. Begin execution
    await _executeNode(nodeId);
  }

  /// The Brain: Determines how to render the node based on its Obsidian 'Type'
  Future<void> _executeNode(String nodeId) async {
    final db = ref.read(databaseProvider);
    
    // Fetch node from the StoryNodes table (populated by our Obsidian Parser)
    final node = await db.getNextNode(nodeId);
    if (node == null) {
      print("DreadmoorOS Error: Node $nodeId not found in Database.");
      return;
    }

    // Determine timing
    int delay = 500;
    Map<String, dynamic> metadata = {};
    if (node.metadata != null) {
      metadata = jsonDecode(node.metadata!);
    }

    // Handle Typing Simulation
    if (metadata['action'] == 'Typing') {
      await _handleTyping(node, metadata);
      return; // handleTyping will call the next tick
    }

    // Handle Delays
    if (metadata['action'] == 'Pause') {
      delay = metadata['duration'] ?? 2000;
    }

    _timer = Timer(Duration(milliseconds: delay), () async {
      await _processNodeType(node, metadata);
    });
  }

  // --------------------------------------------------
  // NODE TYPE DISPATCHER
  // --------------------------------------------------

  Future<void> _processNodeType(StoryNode node, Map<String, dynamic> meta) async {
    final db = ref.read(databaseProvider);

    // Save the latest processed node to track story progression for UI changes
    await db.updateStoryFlag(node.id, bVal: true);

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
        // By default throw an error in debug mode so no unhandled types silently fail
        assert(false, "Unhandled node type: ${node.type} for node ${node.id}");
        _advance(node.nextNodeId);
    }
  }

  // --------------------------------------------------
  // SPECIFIC HANDLERS (FIXES YOUR ERRORS)
  // --------------------------------------------------

  bool hasProcessed(String nodeId) {
    // We check via game flags or activeNode tracking if a given node was seen
    final flags = ref.read(gameFlagsProvider).value ?? {};
    return flags.containsKey(nodeId) && flags[nodeId] == true;
  }

  Future<void> _handleS2SystemAdd(StoryNode node, Map<String, dynamic> meta) async {
    final db = ref.read(databaseProvider);

    // Write thread
    final threadId = 'group_dreadmoor_news';
    final existingThread = await (db.select(db.threads)..where((t) => t.id.equals(threadId))).getSingleOrNull();

    if (existingThread == null) {
      await db.into(db.threads).insert(ThreadsCompanion.insert(
        id: threadId,
        title: 'Dreadmoor News',
        participants: 'amelia,chris,abigail,michael',
      ));

      // Thread Members (using new schema)
      final members = ['amelia', 'chris', 'abigail', 'michael'];
      for (final m in members) {
        await db.into(db.threadMembers).insert(ThreadMembersCompanion.insert(
          threadId: threadId,
          characterId: m,
        ));
      }
    }

    // Insert system message into unknown thread
    final unknownThreadId = _resolveThreadId(node);
    await db.into(db.messages).insert(
      MessagesCompanion.insert(
        threadId: unknownThreadId,
        senderId: 'system',
        content: Value(node.content),
        type: const Value('system_label'),
        sequence: 0,
      ),
    );

    // Invalidate thread list provider (will happen automatically via Drift streams)
    _advance(node.nextNodeId);
  }

  void _handleS4VideoNode(StoryNode node, Map<String, dynamic> meta) {
    final assetPath = meta['file_asset'];
    if (assetPath != null) {
      final context = ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
      if (context != null) {
        MediaViewer.open(
          context,
          items: [MediaItem(path: assetPath, isVideo: true)],
          initialIndex: 0,
        );
      }
    }
    // Execution waits on MediaViewer to be dismissed.
    ref.read(activeNodeIdProvider.notifier).state = node.nextNodeId;
    pause();
  }

  Future<void> _handleSecretHacked(StoryNode node, Map<String, dynamic> meta) async {
    // Force navigate to SecretChatScreen replacing the stack
    final router = ref.read(appRouterProvider);
    ref.read(activeThreadIdProvider.notifier).state = 'intercept_amelia_michael';

    // We update UI flags here instead of in the UI component directly since it's a forced transition
    router.go(Routes.secret('intercept_amelia_michael'));

    _advance(node.nextNodeId);
  }

  void _handleS5ConnectionGlitch(StoryNode node, Map<String, dynamic> meta) {
    final context = ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
    if (context != null) {
      final overlay = Overlay.of(context, rootOverlay: true);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) => GlitchOverlay(
          duration: const Duration(milliseconds: 1000),
          onComplete: () {
            entry.remove();
            final router = ref.read(appRouterProvider);
            ref.read(activeAppProvider.notifier).state = PhoneApp.phone;
            router.go(Routes.messenger); // Pop SecretChatScreen

            _advance(node.nextNodeId);
          },
        ),
      );
      overlay.insert(entry);
    } else {
      _advance(node.nextNodeId);
    }
  }

  void _handleS6AcceptCall(StoryNode node, Map<String, dynamic> meta) {
    // The ActiveCallScreen is pushed internally by the OS overlay when phoneState updates,
    // so we don't need a GoRouter path for it. We just start the call via the provider.
    ref.read(phoneProvider.notifier).startCall('Unknown', 'Unknown Number', ref.read(gameClockProvider));

    ref.read(activeNodeIdProvider.notifier).state = node.nextNodeId;
    pause(); // Wait for call to end
  }

  Future<void> _handleChatMessage(StoryNode node, Map<String, dynamic> meta) async {
    final db = ref.read(databaseProvider);
    final threadId = _resolveThreadId(node);

    // This ensures videos are inserted as 'video' type, NOT text paths
    final msgType = node.type == 'Video_Message' ? 'video' : 'text';
    final content = node.content ?? meta['file_asset'] ?? '';

    final id = await db.into(db.messages).insert(
      MessagesCompanion.insert(
        nodeId: Value(node.id),
        threadId: threadId,
        senderId: node.senderId ?? 'unknown',
        content: Value(_sanitize(content)),
        type: Value(msgType),
        mediaPath: Value(meta['file_asset']),
        sequence: 0, // Logic handles sequence via ID/Timestamp now
      ),
    );

    _playSound('sfx/message_receive.mp3');
    _advance(node.nextNodeId);
  }

  Future<void> _handleSystemLabel(StoryNode node, Map<String, dynamic> meta) async {
    final db = ref.read(databaseProvider);

    // If it's a switch context (e.g., from Group chat to Secret chat)
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
      // Let UI know to show a notification if needed, then advance
      _advance(node.nextNodeId);
      return;
    }

    final threadId = ref.read(activeThreadIdProvider) ?? 'unknown';

    await db.into(db.messages).insert(
      MessagesCompanion.insert(
        threadId: threadId,
        senderId: 'system',
        content: Value(node.content),
        type: const Value('system_label'),
        sequence: 0,
      ),
    );
    _advance(node.nextNodeId);
  }

  void _handlePhoneCall(StoryNode node, Map<String, dynamic> meta) {
    // Determine whether this call can be declined
    final declineMeta = meta['next_on_decline'] as Map<String, dynamic>?;
    final canDecline = node.type != 'S6_Ringing_Final' && declineMeta != null;

    // Triggers the Full-Screen Phone UI via Riverpod
    ref.read(phoneProvider.notifier).receiveIncomingCall(
      node.content ?? "Unknown", 
      node.senderId ?? "Unknown Number",
      canDecline: canDecline,
      onDecline: () {
        if (canDecline && declineMeta != null) {
          final delaySeconds = declineMeta['delay_seconds'] as int? ?? 0;
          final target = declineMeta['target'] as String?;
          if (target != null) {
            // Scene 6 Persistence Logic: Use Future.delayed so it survives pause()
            Future.delayed(Duration(seconds: delaySeconds), () {
              _executeNode(target);
            });
          }
        }
      },
      onAccept: () {
        _advance(node.nextNodeId);
      }
    );
    pause(); // Scheduler waits for call resolution
  }

  void _handleNewsModule(StoryNode node, Map<String, dynamic> meta) {
    // We want to force route to the ArticleViewerScreen
    final router = ref.read(appRouterProvider);
    ref.read(activeAppProvider.notifier).state = PhoneApp.browser;

    // Set article_read to true
    ref.read(databaseProvider).updateStoryFlag('article_read', bVal: true);

    // Save article content so browser home screen can pull it
    final articlePayload = {
      'headline': meta['headline'] ?? '',
      'subheadline': meta['subheadline'] ?? '',
      'photo': meta['image_asset'] ?? '',
      'caption': meta['caption'] ?? '',
      'body': meta['body'] ?? []
    };

    ref.read(databaseProvider).into(ref.read(databaseProvider).notifications).insert(
      NotificationsCompanion.insert(
        id: 'news_${node.id}',
        type: 'article',
        title: 'News Alert',
        message: 'A new article is available.',
        createdAtMinutes: 0,
        payload: Value(jsonEncode({'article': articlePayload})),
      ),
      mode: InsertMode.insertOrReplace
    );

    // Route to the app container which will show the browser
    router.go(Routes.messenger); // Forces main OS view

    // We can't directly push a named route into the nested navigator from here easily without a key,
    // but the BrowserHomeScreen now checks for `article_read` and reads the notification.

    ref.read(activeNodeIdProvider.notifier).state = node.nextNodeId;
    pause(); // Wait for user to read article and dismiss
  }

  void _handleChoiceRequired(StoryNode node) {
    ref.read(waitingForChoiceProvider.notifier).state = true;
    ref.read(activeNodeIdProvider.notifier).state = node.id;
    // Execution stops here until user taps a choice button
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------

  Future<void> _handleTyping(StoryNode node, Map<String, dynamic> meta) async {
    final db = ref.read(databaseProvider);
    final threadId = _resolveThreadId(node);
    final duration = meta['duration'] ?? 2000;

    await (db.update(db.threads)..where((t) => t.id.equals(threadId)))
        .write(const ThreadsCompanion(isTyping: Value(true)));

    _timer = Timer(Duration(milliseconds: duration), () async {
      await (db.update(db.threads)..where((t) => t.id.equals(threadId)))
          .write(const ThreadsCompanion(isTyping: Value(false)));
      
      // After typing, immediately process the text content of the same node
      await _processNodeType(node, {...meta, 'action': 'None'});
    });
  }

  String _resolveThreadId(StoryNode node) {
    // In our new architecture, we determine thread by Scene Context or Node Sender
    if (node.metadata != null && node.metadata!.contains('chat')) {
      final chat = jsonDecode(node.metadata!)['chat'];
      if (chat == 'Group_Dreadmoor_News') return 'group_dreadmoor_news';
      if (chat == 'Private_Unknown') return 'unknown';
      if (chat == 'Secret_Intercept_Amelia_Michael') return 'intercept_amelia_michael';
    }

    // Fallback ID logic
    if (node.id.contains('GROUP') || node.id.contains('s3_')) return 'group_dreadmoor_news';
    if (node.id.contains('SECRET') || node.id.contains('s4_intercept') || node.id.contains('s5_')) return 'intercept_amelia_michael';
    return node.senderId ?? 'unknown';
  }

  String _sanitize(String? input) {
    if (input == null) return '';
    final playerName = ref.read(playerStateProvider)?.name ?? 'Detective';
    return input.replaceAll('[PlayerName]', playerName);
  }

  void submitChoice(String targetNodeId, String choiceText) {
    // Add player's message to the chat
    final db = ref.read(databaseProvider);
    final threadId = ref.read(activeThreadIdProvider) ?? 'unknown';

    db.into(db.messages).insert(
      MessagesCompanion.insert(
        threadId: threadId,
        senderId: 'player',
        content: Value(choiceText),
        type: const Value('text'),
        sequence: 0,
      ),
    );

    ref.read(waitingForChoiceProvider.notifier).state = false;
    _executeNode(targetNodeId);
  }

  void completePuzzle() {
    resume();
  }

  void pause() {
    _timer?.cancel();
    ref.read(isSchedulerPausedProvider.notifier).state = true;
  }

  void resume() {
    ref.read(isSchedulerPausedProvider.notifier).state = false;
    final nextId = ref.read(activeNodeIdProvider);
    if (nextId != null) {
      _executeNode(nextId);
    }
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
