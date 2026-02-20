import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/messenger_state.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/choice_overlay.dart';
import '../widgets/gun_typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String threadId;
  const ChatScreen({Key? key, required this.threadId}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.threadId));
    final threadAsync = ref.watch(threadProvider(widget.threadId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: threadAsync.when(
          data: (t) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t?.title ?? 'Chat', style: const TextStyle(fontFamily: 'Cinzel', fontSize: 18)),
              // Participants could go here
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (e,s) => const Text('Error'),
        ),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
             child: Image.asset(
               'assets/backgrounds/chat_bg_texture.png',
               fit: BoxFit.cover,
               errorBuilder: (c,o,s) => Container(color: Colors.black),
             ),
          ),

          Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    final reversedMessages = messages.reversed.toList();
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                      itemCount: reversedMessages.length,
                      itemBuilder: (context, index) {
                        final msg = reversedMessages[index];
                        return ChatBubble(
                          text: msg.content,
                          isMe: msg.isPlayerMessage,
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e,s) => Center(child: Text('Error: $e')),
                ),
              ),

              // Typing Indicator Area
              threadAsync.maybeWhen(
                data: (thread) {
                   if (thread != null && thread.isTyping) {
                     return const GunTypingIndicator();
                   }
                   return const SizedBox.shrink();
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),

          // Choice Overlay
          const Positioned.fill(child: ChoiceOverlay()),
        ],
      ),
    );
  }
}
