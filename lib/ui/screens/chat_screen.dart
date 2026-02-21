import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/state/messenger_state.dart';
import '../theme/colors.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/choice_overlay.dart';
import '../widgets/gun_typing_indicator.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key, required this.threadId});

  final String threadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesStreamProvider(threadId));
    final threadAsync = ref.watch(threadProvider(threadId));

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/chat_bg_texture.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.75),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Positioned.fill(child: Opacity(opacity: 0.03, child: Image.asset('assets/ui/glitch_overlay.png', fit: BoxFit.cover))),
          Column(
            children: [
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: Container(
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06), width: 0.5)),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 16,
                            top: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: context.pop,
                              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white.withOpacity(0.55)),
                            ),
                          ),
                          Center(
                            child: threadAsync.when(
                              data: (thread) => Text((thread?.title ?? 'THREAD').toUpperCase(), style: GoogleFonts.michroma(fontSize: 12, letterSpacing: 2, color: DreadmoorColors.textPrimary)),
                              loading: () => Text('SYNCING', style: GoogleFonts.michroma(fontSize: 10, letterSpacing: 2, color: DreadmoorColors.textMeta)),
                              error: (_, __) => Text('SIGNAL LOST', style: GoogleFonts.michroma(fontSize: 10, letterSpacing: 2, color: DreadmoorColors.accentRed)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: messagesAsync.when(
                  data: (messages) => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return threadAsync.asData?.value?.isTyping == true ? const GunTypingIndicator() : const SizedBox.shrink();
                      }
                      final message = messages[index];
                      return ChatBubble(text: message.content, isMe: message.isPlayerMessage);
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator(color: DreadmoorColors.accentCyan)),
                  error: (_, __) => Center(child: Text('MESSAGE FEED ERROR', style: GoogleFonts.michroma(fontSize: 10, letterSpacing: 2, color: DreadmoorColors.accentRed))),
                ),
              ),
            ],
          ),
          const Positioned.fill(child: ChoiceOverlay()),
        ],
      ),
    );
  }
}
