import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dreadmoor/core/persistence/drift_database.dart';
import 'package:dreadmoor/core/state/game_state.dart';

// Guard: this screen must never appear in release builds
class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // FIX 7: Hard gate on debug mode — release builds see nothing
    if (!kDebugMode) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: SizedBox.shrink()),
      );
    }
    return const _DebugScreenBody();
  }
}

// ─────────────────────────────────────────────────────────────
// Main body — StatefulWidget for loading/error/refresh state
// FIX 6: Was ConsumerWidget — can't manage local state for
//         loading indicators or triggering DB inspector refresh
// ─────────────────────────────────────────────────────────────

class _DebugScreenBody extends ConsumerStatefulWidget {
  const _DebugScreenBody();

  @override
  ConsumerState<_DebugScreenBody> createState() => _DebugScreenBodyState();
}

class _DebugScreenBodyState extends ConsumerState<_DebugScreenBody>
    with SingleTickerProviderStateMixin {
  // Which action button is currently loading
  String? _loadingAction;

  // Increment to force DB inspector rebuild
  int _inspectorRefreshKey = 0;

  // Cursor blink
  late AnimationController _cursorController;
  late Animation<double> _cursorOpacity;

  // Accumulated log lines shown in the terminal output
  final List<_LogEntry> _log = [];

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
    _cursorOpacity = CurvedAnimation(
      parent: _cursorController,
      curve: Curves.easeInOut,
    );
    _pushLog('DREADMOOR DEBUG CONSOLE v1.0', _LogLevel.system);
    _pushLog('Build: ${kDebugMode ? "DEBUG" : "RELEASE"}', _LogLevel.system);
    _pushLog('Ready.', _LogLevel.ok);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  void _pushLog(String msg, _LogLevel level) {
    setState(() => _log.add(_LogEntry(msg, level)));
  }

  // FIX 2: All actions are async — handle loading state, errors, and
  //         result feedback properly instead of silent VoidCallback
  Future<void> _run(
    String actionKey,
    String label,
    Future<void> Function() action,
  ) async {
    if (_loadingAction != null) return;
    setState(() => _loadingAction = actionKey);
    _pushLog('> $label', _LogLevel.cmd);
    try {
      await action();
      _pushLog('  OK', _LogLevel.ok);
      setState(() => _inspectorRefreshKey++);
    } catch (e) {
      _pushLog('  ERR: $e', _LogLevel.error);
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.read(databaseProvider); // FIX 1: read not watch
    // FIX 1: scheduler read on demand inside _run lambdas, not watched here

    return Scaffold(
      backgroundColor: const Color(0xFF080D08),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // ── Terminal output log ──────────────────────────────
          _TerminalLog(log: _log, cursorOpacity: _cursorOpacity),

          // ── Divider ──────────────────────────────────────────
          Container(height: 1, color: const Color(0xFF1A3A1A)),

          // ── Action panels ─────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _section('CORE'),
                _dangerAction(
                  key: 'nuke',
                  label: 'NUKE DATABASE',
                  icon: Icons.delete_forever_rounded,
                  context: context,
                  onConfirm: () => _run('nuke', 'NUKE DATABASE', () async {
                    await db.batch((b) {
                      b.deleteAll(db.messages);
                      b.deleteAll(db.threads);
                      b.deleteAll(db.players);
                      b.deleteAll(db.storyState);
                      b.deleteAll(db.episodes);
                    });
                    ref.read(playerStateProvider.notifier).state = null;
                    if (context.mounted) context.go('/');
                  }),
                ),

                _section('EPISODES'),
                _termAction(
                  key: 'ep01_start',
                  label: 'START EP01 / AMELIA CHAT',
                  onTap: () =>
                      _run('ep01_start', 'START EP01 / AMELIA CHAT', () async {
                        // FIX 1: ref.read inside lambda, not ref.watch in build
                        final scheduler = ref.read(globalSchedulerProvider);
                        await scheduler.startThread('ep01', 'amelia_chat');
                        if (context.mounted) context.go('/messenger');
                      }),
                ),
                _termAction(
                  key: 'replay',
                  label: 'REPLAY CURRENT THREAD',
                  onTap: () =>
                      _run('replay', 'REPLAY CURRENT THREAD', () async {
                        final ep = ref.read(currentEpisodeIdProvider);
                        final thread = ref.read(activeThreadIdProvider);
                        if (ep == null || thread == null) {
                          throw Exception('No active episode or thread');
                        }
                        final scheduler = ref.read(globalSchedulerProvider);
                        await scheduler.startThread(ep, thread);
                        if (context.mounted) context.go('/chat/$thread');
                      }),
                ),

                _section('FLAGS'),
                _termAction(
                  key: 'unlock_flags',
                  label: 'UNLOCK ALL FLAGS',
                  onTap: () =>
                      _run('unlock_flags', 'UNLOCK ALL FLAGS', () async {
                        // FIX 4: insertOrReplace — original insert() crashes if
                        //         the flag key already exists in StoryState
                        await db.batch((b) {
                          for (final flag in [
                            'found_factory_phone',
                            'confronted_amelia',
                            'visited_factory',
                            'saw_highway_crash',
                            'found_diary_01',
                            'trusted_detective',
                            'contacted_informant',
                            'found_recording',
                            'confronted_mayor',
                          ]) {
                            b.insert(
                              db.storyState,
                              StoryStateCompanion.insert(
                                key: flag,
                                value: const Value(true),
                              ),
                              mode: InsertMode.insertOrReplace, // FIX 4
                            );
                          }
                        });
                      }),
                ),
                _termAction(
                  key: 'clear_flags',
                  label: 'CLEAR ALL FLAGS',
                  onTap: () => _run('clear_flags', 'CLEAR ALL FLAGS', () async {
                    await db.delete(db.storyState).go();
                  }),
                ),

                _section('TIME'),
                _termAction(
                  key: 'time_7d',
                  label: 'SIMULATE +7 DAYS',
                  onTap: () => _run('time_7d', 'SIMULATE +7 DAYS', () async {
                    // FIX 3: Was `updated_at - 7` which subtracts 7ms.
                    // Drift stores dateTime as Unix milliseconds.
                    // 7 days = 7 * 24 * 60 * 60 * 1000 = 604800000 ms
                    const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
                    await db.customUpdate(
                      'UPDATE story_state SET updated_at = updated_at - $sevenDaysMs',
                    );
                  }),
                ),
                _termAction(
                  key: 'time_1d',
                  label: 'SIMULATE +1 DAY',
                  onTap: () => _run('time_1d', 'SIMULATE +1 DAY', () async {
                    const oneDayMs = 24 * 60 * 60 * 1000;
                    await db.customUpdate(
                      'UPDATE story_state SET updated_at = updated_at - $oneDayMs',
                    );
                  }),
                ),

                _section('DB INSPECTOR'),
                // FIX 5: Key forces FutureBuilder to re-run after every action
                _DbInspector(db: db, refreshKey: _inspectorRefreshKey),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF080D08),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4CAF50)),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'DEBUG CONSOLE',
            style: GoogleFonts.sourceCodePro(
              color: const Color(0xFF4CAF50),
              fontSize: 13,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        if (_loadingAction != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: const Color(0xFF4CAF50).withOpacity(0.7),
              ),
            ),
          ),
      ],
    );
  }

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Text(
            '// $label',
            style: GoogleFonts.sourceCodePro(
              fontSize: 10,
              letterSpacing: 2.5,
              color: const Color(0xFF2E6B2E),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: const Color(0xFF1A3A1A))),
        ],
      ),
    );
  }

  Widget _termAction({
    required String key,
    required String label,
    required VoidCallback onTap,
  }) {
    final isLoading = _loadingAction == key;
    final isDisabled = _loadingAction != null && !isLoading;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(
              color: isLoading
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF1A3A1A),
              width: 1,
            ),
            color: isLoading
                ? const Color(0xFF4CAF50).withOpacity(0.07)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Text(
                '\$',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 12,
                  color: const Color(0xFF2E6B2E),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 12,
                    letterSpacing: 0.5,
                    color: isDisabled
                        ? const Color(0xFF2E6B2E)
                        : const Color(0xFF7CBF7C),
                  ),
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: const Color(0xFF4CAF50).withOpacity(0.7),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF2E6B2E),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dangerAction({
    required String key,
    required String label,
    required IconData icon,
    required BuildContext context,
    required VoidCallback onConfirm,
  }) {
    final isLoading = _loadingAction == key;
    final isDisabled = _loadingAction != null && !isLoading;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: isDisabled
            ? null
            : () => _showDangerConfirm(context, label, onConfirm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(
              color: isLoading ? Colors.red : Colors.red.withOpacity(0.4),
              width: 1,
            ),
            color: Colors.red.withOpacity(isLoading ? 0.1 : 0.04),
          ),
          child: Row(
            children: [
              Text(
                '!',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 12,
                  color: Colors.red.withOpacity(0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 12,
                    letterSpacing: 0.5,
                    color: Colors.red.withOpacity(isDisabled ? 0.3 : 0.8),
                  ),
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.red.withOpacity(0.7),
                  ),
                )
              else
                Icon(icon, color: Colors.red.withOpacity(0.5), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showDangerConfirm(
    BuildContext context,
    String label,
    VoidCallback onConfirm,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D150D),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'CONFIRM',
          style: GoogleFonts.sourceCodePro(
            color: Colors.red,
            fontSize: 13,
            letterSpacing: 3,
          ),
        ),
        content: Text(
          'Run: $label?\nThis cannot be undone.',
          style: GoogleFonts.sourceCodePro(
            color: const Color(0xFF7CBF7C),
            fontSize: 12,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: GoogleFonts.sourceCodePro(
                color: const Color(0xFF2E6B2E),
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: Text(
              'CONFIRM',
              style: GoogleFonts.sourceCodePro(
                color: Colors.red,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Terminal log output
// ─────────────────────────────────────────────────────────────

enum _LogLevel { system, cmd, ok, error }

class _LogEntry {
  final String text;
  final _LogLevel level;
  _LogEntry(this.text, this.level);
}

class _TerminalLog extends StatefulWidget {
  final List<_LogEntry> log;
  final Animation<double> cursorOpacity;

  const _TerminalLog({required this.log, required this.cursorOpacity});

  @override
  State<_TerminalLog> createState() => _TerminalLogState();
}

class _TerminalLogState extends State<_TerminalLog> {
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant _TerminalLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.log.length != oldWidget.log.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Color _levelColor(_LogLevel l) => switch (l) {
    _LogLevel.system => const Color(0xFF2E6B2E),
    _LogLevel.cmd => const Color(0xFF7CBF7C),
    _LogLevel.ok => const Color(0xFF4CAF50),
    _LogLevel.error => Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: const Color(0xFF040804),
      padding: const EdgeInsets.all(12),
      child: ListView.builder(
        controller: _scroll,
        itemCount: widget.log.length + 1, // +1 for cursor line
        itemBuilder: (context, i) {
          if (i == widget.log.length) {
            // Blinking cursor on last line
            return Row(
              children: [
                Text(
                  '> ',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 11,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                FadeTransition(
                  opacity: widget.cursorOpacity,
                  child: Container(
                    width: 7,
                    height: 13,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            );
          }
          final entry = widget.log[i];
          return Text(
            entry.text,
            style: GoogleFonts.sourceCodePro(
              fontSize: 11,
              height: 1.5,
              color: _levelColor(entry.level),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DB Inspector
// FIX 5: Keyed so parent can increment refreshKey to force a
//         fresh FutureBuilder re-run after each action.
//         Original had a single static FutureBuilder that never
//         updated.
// ─────────────────────────────────────────────────────────────

class _DbInspector extends StatelessWidget {
  final AppDatabase db;
  final int refreshKey;

  const _DbInspector({required this.db, required this.refreshKey});

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(refreshKey), // FIX 5
      child: FutureBuilder(
        future: Future.wait([
          db.select(db.players).get(),
          db.select(db.threads).get(),
          db.select(db.messages).get(),
          db.select(db.storyState).get(),
          db.select(db.episodes).get(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'querying...',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 11,
                  color: const Color(0xFF2E6B2E),
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return _dbLine('ERR: ${snapshot.error}', isError: true);
          }
          if (!snapshot.hasData) return const SizedBox.shrink();

          final players = snapshot.data![0] as List<Player>;
          final threads = snapshot.data![1] as List<Thread>;
          final messages = snapshot.data![2] as List<Message>;
          final flags = snapshot.data![3] as List<StoryStateData>;
          final episodes = snapshot.data![4] as List<Episode>;

          final activeFlags = flags
              .where((f) => f.value)
              .map((f) => f.key)
              .toList();

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1A3A1A)),
              color: const Color(0xFF040804),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dbLine('players     ${players.length}'),
                _dbLine('threads     ${threads.length}'),
                _dbLine('messages    ${messages.length}'),
                _dbLine('episodes    ${episodes.length}'),
                _dbLine(
                  'flags       ${flags.length} total, ${activeFlags.length} active',
                ),
                if (activeFlags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(height: 1, color: const Color(0xFF1A3A1A)),
                  const SizedBox(height: 8),
                  for (final f in activeFlags) _dbLine('  ✓ $f'),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _dbLine(String text, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.sourceCodePro(
          fontSize: 11,
          height: 1.5,
          color: isError
              ? Colors.red.withOpacity(0.8)
              : const Color(0xFF4A7F4A),
        ),
      ),
    );
  }
}
