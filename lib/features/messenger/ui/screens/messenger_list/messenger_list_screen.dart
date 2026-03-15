import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/features/messenger/ui/messenger_navigator.dart';

// ── COLOURS (extracted from screenshot) ──────────────────────────────────────
const _kBg       = Color(0xFF4A6D7C); // muted teal-slate — whole screen
const _kCard     = Color(0xFF3D5D6B); // slightly darker for tile
const _kTextPri  = Colors.white;
const _kTextSec  = Color(0xFFBDD0D8); // lighter teal-white for preview

class MessengerListScreen extends ConsumerStatefulWidget {
  const MessengerListScreen({super.key});

  @override
  ConsumerState<MessengerListScreen> createState() =>
      _MessengerListScreenState();
}

class _MessengerListScreenState
    extends ConsumerState<MessengerListScreen> {

  void _showAddContactDialog(BuildContext context) {
    String phoneNumber = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: Text('NEW CONNECTION',
            style: GoogleFonts.spaceGrotesk(
                color: _kTextPri,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        content: TextField(
          style: const TextStyle(color: _kTextPri),
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Enter frequency / number',
            hintStyle: TextStyle(color: _kTextSec.withOpacity(0.6)),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _kTextSec)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white)),
          ),
          onChanged: (v) => phoneNumber = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: TextStyle(color: _kTextSec.withOpacity(0.7))),
          ),
          TextButton(
            onPressed: () async {
              if (phoneNumber.isEmpty) return;
              final db = ref.read(databaseProvider);
              final character = await (db.select(db.characters)
                    ..where(
                        (c) => c.phoneNumber.equals(phoneNumber)))
                  .getSingleOrNull();

              if (!ctx.mounted) return;
              if (character == null) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Frequency not found.')));
                return;
              }

              final threadId = character.id;
              final existing = await (db.select(db.threads)
                    ..where((t) => t.id.equals(threadId)))
                  .getSingleOrNull();

              if (existing == null) {
                await db.into(db.threads).insert(
                  ThreadsCompanion.insert(
                    id:           threadId,
                    title:        character.name,
                    participants: character.id,
                  ),
                );
              }

              if (ctx.mounted) {
                Navigator.pop(ctx);
                Navigator.of(ctx).pushNamed(
                    MessengerRoutes.chat,
                    arguments: threadId);
              }
            },
            child: Text('ESTABLISH',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db  = ref.watch(databaseProvider);
    final top = MediaQuery.of(context).padding.top;

    final threadsStream = (db.select(db.threads)
          ..orderBy([(t) => OrderingTerm(
              expression: t.lastMessageId,
              mode: OrderingMode.desc)]))
        .join([
          leftOuterJoin(db.messages,
              db.messages.id.equalsExp(db.threads.lastMessageId)),
          leftOuterJoin(db.characters,
              db.characters.id.equalsExp(db.threads.id)),
        ]).watch();

    return Scaffold(
      // Full-screen teal-slate — no separate header colour
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── HEADER ────────────────────────────────────────────────────
          // Same background as body — no border, no divider.
          SizedBox(
            height: top + 64,
            child: Padding(
              padding: EdgeInsets.only(top: top),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Settings — left
                  Positioned(
                    left: 4,
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: _kTextPri, size: 22),
                      onPressed: () => context.push('/settings'),
                    ),
                  ),

                  // Title — centred
                  Text(
                    'MESSENGER',
                    style: GoogleFonts.spaceGrotesk(
                      color: _kTextPri,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.5,
                    ),
                  ),

                  // Add contact — right
                  Positioned(
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.person_add_outlined,
                          color: _kTextPri, size: 22),
                      onPressed: () =>
                          _showAddContactDialog(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── THREAD LIST ───────────────────────────────────────────────
          Expanded(
            child: StreamBuilder(
              stream: threadsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: _kTextPri));
                }

                final rows = snapshot.data!;
                if (rows.isEmpty) {
                  return Center(
                    child: Text(
                      'No connections found.',
                      style: GoogleFonts.spectral(
                          color: _kTextSec, fontSize: 15),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final thread =
                        rows[i].readTable(db.threads);
                    final message =
                        rows[i].readTableOrNull(db.messages);
                    final character =
                        rows[i].readTableOrNull(db.characters);

                    return _ThreadTile(
                      thread:    thread,
                      message:   message,
                      character: character,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── THREAD TILE ───────────────────────────────────────────────────────────────

class _ThreadTile extends ConsumerWidget {
  final Thread    thread;
  final Message?  message;
  final Character? character;

  const _ThreadTile({
    required this.thread,
    this.message,
    this.character,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = thread.unreadCount > 0;

    return GestureDetector(
      onTap: () {
        ref.read(activeThreadIdProvider.notifier).state = thread.id;
        Navigator.of(context).pushNamed(
          thread.isSecret
              ? MessengerRoutes.secret
              : MessengerRoutes.chat,
          arguments: thread.id,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          // Subtle unread accent border
          border: hasUnread
              ? Border.all(color: Colors.white.withOpacity(0.5), width: 1.2)
              : null,
        ),
        child: Row(
          children: [
            // ── CIRCULAR AVATAR ──────────────────────────────────────────
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2A4A5A),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: thread.isSecret
                    ? const Icon(Icons.security,
                        color: Color(0xFF9B2222), size: 28)
                    : (character?.avatarPath != null
                        ? Image.asset(
                            character!.avatarPath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person,
                                    color: _kTextSec, size: 28),
                          )
                        : const Icon(Icons.person,
                            color: _kTextSec, size: 28)),
              ),
            ),

            const SizedBox(width: 14),

            // ── TEXT CONTENT ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.title.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      color: _kTextPri,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message?.content ?? 'No messages yet.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spectral(
                      color: _kTextSec,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // ── UNREAD DOT ────────────────────────────────────────────────
            if (hasUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
