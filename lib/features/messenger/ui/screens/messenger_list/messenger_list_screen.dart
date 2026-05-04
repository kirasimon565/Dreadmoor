import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/core/state/scheduler_state.dart';
import 'package:dreadmoor/features/messenger/ui/messenger_navigator.dart';

// ── PALETTE (from mockup) ─────────────────────────────────────────────────────
const _kBg      = Color(0xFF6D8693); // body background
const _kHeader  = Color(0xFF5B7A8A); // header card
const _kTile    = Color(0xFF7BA1AF); // message tile
const _kPri     = Color(0xFFDFEBF4); // primary text
const _kSec     = Color(0xFFBAD5E0); // secondary / preview text

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
        backgroundColor: _kHeader,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('NEW CONNECTION',
            style: GoogleFonts.oxygen(
                color: _kPri,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        content: TextField(
          style: const TextStyle(color: _kPri),
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Enter frequency / number',
            hintStyle: TextStyle(color: _kSec.withOpacity(0.7)),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _kSec)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _kPri)),
          ),
          onChanged: (v) => phoneNumber = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: TextStyle(color: _kSec.withOpacity(0.8))),
          ),
          TextButton(
            onPressed: () async {
              if (phoneNumber.isEmpty) return;
              final db = ref.read(databaseProvider);
              final character = await (db.select(db.characters)
                    ..where((c) =>
                        c.phoneNumber.equals(phoneNumber)))
                  .getSingleOrNull();
              if (!ctx.mounted) return;
              if (character == null) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Frequency not found.')));
                return;
              }
              final existing = await (db.select(db.threads)
                    ..where((t) => t.id.equals(character.id)))
                  .getSingleOrNull();
              if (existing == null) {
                await db.into(db.threads).insert(
                  ThreadsCompanion.insert(
                    id: character.id,
                    title: character.name,
                    participants: character.id,
                  ),
                );
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
                Navigator.of(ctx).pushNamed(
                    MessengerRoutes.chat,
                    arguments: character.id);
              }
            },
            child: Text('ESTABLISH',
                style: GoogleFonts.oxygen(
                    color: _kPri, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

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
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── HEADER — rounded bottom corners, from mockup ─────────────
          // ── HEADER — rounded bottom corners, from mockup ─────────────
Container(
  height: 70,
  decoration: const BoxDecoration(
    color: _kHeader,
    borderRadius: BorderRadius.vertical(
      bottom: Radius.circular(30),
    ),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // Left: Settings icon
      GestureDetector(
        onTap: () => context.push('/settings'),
        child: const Icon(
          Icons.settings_outlined,
          color: _kPri,
          size: 28,
        ),
      ),

      // Center: Title (takes remaining space)
      Expanded(
        child: Center(
          child: Text(
            'MESSENGER',
            style: GoogleFonts.oxygen(
              fontSize: 22,
              color: _kPri,
              fontWeight: FontWeight.w300,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),

      // Right: Add contact icon
      GestureDetector(
        onTap: () => _showAddContactDialog(context),
        child: const Icon(
          Icons.person_add_outlined,
          color: _kPri,
          size: 28,
        ),
      ),
    ],
  ),
),

          // ── THREAD LIST ──────────────────────────────────────────────
          Expanded(
            child: StreamBuilder(
              stream: threadsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: _kPri));
                }
                final rows = snapshot.data!;
                if (rows.isEmpty) {
                  return Center(
                    child: Text('No connections found.',
                        style: GoogleFonts.oxygen(
                            color: _kSec, fontSize: 15)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(
                      top: 20, left: 20, right: 20, bottom: 24),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final thread = rows[i].readTable(db.threads);
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
  final Thread     thread;
  final Message?   message;
  final Character? character;

  const _ThreadTile(
      {required this.thread, this.message, this.character});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(schedulerStateProvider.notifier).switchThread(thread.id);
        Navigator.of(context).pushNamed(
          thread.isSecret
              ? MessengerRoutes.secret
              : MessengerRoutes.chat,
          arguments: thread.id,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _kTile,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular avatar — 55px as in mockup
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black12,
                border: Border.all(
                    color: Colors.white24, width: 2),
              ),
              child: ClipOval(
                child: character?.avatarPath != null
                    ? Image.asset(
                        character!.avatarPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person,
                                size: 30,
                                color: Colors.black26),
                      )
                    : const Icon(Icons.person,
                        size: 30, color: Colors.black26),
              ),
            ),

            const SizedBox(width: 15),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.title.toUpperCase(),
                    style: GoogleFonts.oxygen(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kPri,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message?.content ?? 'No messages yet.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.oxygen(
                      fontSize: 14,
                      color: _kSec,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (thread.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: _kPri),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
