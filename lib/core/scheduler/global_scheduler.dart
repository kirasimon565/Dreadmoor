import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/time/game_clock.dart';
import 'package:dreadmoor/features/phone/phone_state.dart';
import 'package:dreadmoor/features/notifications/notification_state.dart';
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
  Future<void> startFromNode(String nodeId) async {
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

    switch (node.type) {
      case 'Chat_Event':
      case 'Video_Message':
        await _handleChatMessage(node, meta);
        break;
        
      case 'Player_Choice':
        _handleChoiceRequired(node);
        break;

      case 'News_Module':
        _handleNewsModule(node, meta);
        break;

      case 'Phone_Call_Event':
        _handlePhoneCall(node, meta);
        break;

      case 'System_Notification':
        await _handleSystemLabel(node);
        break;
        
      default:
        _advance(node.nextNodeId);
    }
  }

  // --------------------------------------------------
  // SPECIFIC HANDLERS (FIXES YOUR ERRORS)
  // --------------------------------------------------

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

  Future<void> _handleSystemLabel(StoryNode node) async {
    final db = ref.read(databaseProvider);
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
    // Triggers the Full-Screen Phone UI via Riverpod
    ref.read(phoneProvider.notifier).receiveIncomingCall(
      node.content ?? "Unknown", 
      node.senderId ?? "0000"
    );
    pause(); // Scheduler waits for call resolution
  }

  void _handleNewsModule(StoryNode node, Map<String, dynamic> meta) {
    // Triggers News Overlay
    ref.read(navigationProvider.notifier).navigateToNews(node.id);
    pause();
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
    if (node.id.contains('GROUP')) return 'group_news';
    if (node.id.contains('SECRET')) return 'intercept_amelia_michael';
    return node.senderId ?? 'unknown';
  }

  String _sanitize(String? input) {
    if (input == null) return '';
    final playerName = ref.read(playerProvider).name;
    return input.replaceAll('[PlayerName]', playerName);
  }

  void _advance(String? nextId) {
    if (nextId != null && nextId.isNotEmpty) {
      _executeNode(nextId);
    }
  }

  void pause() {
    _timer?.cancel();
    ref.read(isSchedulerPausedProvider.notifier).state = true;
  }

  void resume() {
    ref.read(isSchedulerPausedProvider.notifier).state = false;
    final nextId = ref.read(activeNodeIdProvider);
    if (nextId != null) _executeNode(nextId);
  }

  Future<void> _playSound(String path) async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource(path));
    } catch (_) {}
  }
}
