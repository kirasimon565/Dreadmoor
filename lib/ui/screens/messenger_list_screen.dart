import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/state/messenger_state.dart';
import '../navigation/routes.dart';
import '../theme/colors.dart';
import '../widgets/gun_typing_indicator.dart';

class MessengerListScreen extends ConsumerWidget {
  const MessengerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(threadsStreamProvider);

    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/messenger_bg_texture.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.72),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Positioned.fill(child: Opacity(opacity: 0.035, child: Image.asset('assets/ui/glitch_overlay.png', fit: BoxFit.cover))),
          SafeArea(
            child: Column(
              children: [
                const _MessengerHeader(),
                Expanded(
                  child: threadsAsync.when(
                    data: (threads) => ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: threads.length,
                      itemBuilder: (context, index) => _ThreadTile(item: threads[index]),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator(color: DreadmoorColors.accentCyan)),
                    error: (_, __) => Center(child: Text('THREAD FEED OFFLINE', style: GoogleFonts.michroma(fontSize: 10, letterSpacing: 1.5, color: DreadmoorColors.textSecondary))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessengerHeader extends StatelessWidget {
  const _MessengerHeader();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06), width: 0.5)),
          ),
          child: Stack(
            children: [
              Center(child: Image.asset('assets/ui/messenger_weapon_logo.png', height: 28)),
              Positioned(right: 20, top: 0, bottom: 0, child: Center(child: Icon(Icons.search_rounded, size: 20, color: DreadmoorColors.textSecondary))),
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.push(Routes.playerProfile),
                    child: Icon(Icons.person_outline_rounded, size: 20, color: DreadmoorColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.item});

  final ThreadWithLastMessage item;

  @override
  Widget build(BuildContext context) {
    final isUnread = item.thread.unreadCount > 0;
    final ts = item.lastMessage == null ? '' : DateFormat('HH:mm').format(item.lastMessage!.timestamp).toUpperCase();

    return GestureDetector(
      onTap: () => context.go(Routes.chat(item.thread.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isUnread ? 0.06 : 0.025),
                    border: Border.all(
                      width: 0.5,
                      color: isUnread ? DreadmoorColors.accentCyan.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _ThreadAvatar(name: item.thread.title),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.thread.title.toUpperCase(), style: GoogleFonts.michroma(fontSize: 13, letterSpacing: 1.5, color: DreadmoorColors.textPrimary)),
                                Text(ts, style: GoogleFonts.inter(fontSize: 10, letterSpacing: 1.2, color: DreadmoorColors.textMeta)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            item.thread.isTyping
                                ? const CompactGunTypingIndicator()
                                : Text(
                                    item.lastMessage?.content ?? 'NO SIGNAL',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontSize: 13, color: DreadmoorColors.textSecondary),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isUnread)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: DreadmoorColors.accentCyan,
                    boxShadow: [BoxShadow(color: DreadmoorColors.glowCyan, blurRadius: 6)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThreadAvatar extends StatelessWidget {
  const _ThreadAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final charId = name.toLowerCase().split(' ').first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Image.asset(
        'assets/characters/$charId.png',
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 52,
          height: 52,
          color: Colors.white.withOpacity(0.05),
          alignment: Alignment.center,
          child: Text(name.characters.first.toUpperCase(), style: GoogleFonts.michroma(fontSize: 12, color: DreadmoorColors.textPrimary)),
        ),
      ),
    );
  }
}
