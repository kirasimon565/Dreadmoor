import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/messenger_state.dart';
import '../widgets/chat_bubble.dart';

class SecretChatScreen extends ConsumerWidget {
  final String threadId;
  const SecretChatScreen({Key? key, required this.threadId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesStreamProvider(threadId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('INTERCEPTED SIGNAL', style: TextStyle(fontFamily: 'MonoGlitch', color: Colors.greenAccent)),
        backgroundColor: Colors.grey[900],
      ),
      body: Stack(
        children: [
          // Glitch Background
          Positioned.fill(
             child: Container(
               color: Colors.black,
               child: Center(
                 child: Image.asset(
                   'assets/ui/glitch_overlay.png',
                   fit: BoxFit.cover,
                   color: Colors.green.withOpacity(0.2),
                   colorBlendMode: BlendMode.modulate,
                   errorBuilder: (c,o,s) => Container(color: Colors.black),
                 ),
               ),
             ),
          ),

          messagesAsync.when(
            data: (messages) {
              final reversedMessages = messages.reversed.toList();
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                itemCount: reversedMessages.length,
                itemBuilder: (context, index) {
                  final msg = reversedMessages[index];
                  return ChatBubble(
                    text: msg.content,
                    isMe: false, // In secret chat, nothing is "me" usually, or handled differently
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.green)),
            error: (e,s) => const Center(child: Text('SIGNAL LOST', style: TextStyle(color: Colors.green))),
          ),

          // Static overlay or noise could go here
        ],
      ),
    );
  }
}
