import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dreadmoor/ui/navigation/routes.dart';
import 'package:dreadmoor/core/state/game_state.dart';
import 'package:dreadmoor/features/minigame/ghost_trace/state/ghost_trace_notifier.dart';

class GhostTraceScreen extends ConsumerStatefulWidget {
  const GhostTraceScreen({super.key});

  @override
  ConsumerState<GhostTraceScreen> createState() => _GhostTraceScreenState();
}

class _GhostTraceScreenState extends ConsumerState<GhostTraceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ghostTraceProvider.notifier).init('ghost_trace_ep01');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ghostTraceProvider);

    if (state.cooldownUntil != null && DateTime.now().isBefore(state.cooldownUntil!)) {
      final diff = state.cooldownUntil!.difference(DateTime.now());
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'TRACE LOCKED\nNETWORK COOLDOWN ACTIVE',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'TRY AGAIN IN ${diff.inMinutes}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  context.go(Routes.messenger);
                },
                child: const Text('Return to OS'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isCompleted) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'TRACE SUCCESSFUL\nATTACKER IDENTIFIED',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  ref.read(globalSchedulerProvider).resume();
                  ref.read(waitingForPuzzleProvider.notifier).setWaiting(false);
                  context.go(Routes.messenger);
                },
                child: const Text('Return to OS'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // HUD
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TIME: ${state.timeRemaining}s', style: const TextStyle(color: Colors.cyan)),
                  Text('HEARTS: ${state.hearts}', style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),

            // Game Area using Flame
            Expanded(
              child: state.isExposePhase
                  ? GestureDetector(
                      onTap: () {
                        // In a real implementation this would be a UI puzzle to reconstruct the identity
                        ref.read(ghostTraceProvider.notifier).winGame();
                      },
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('RECONSTRUCT IDENTITY', style: TextStyle(color: Colors.green, fontSize: 20)),
                              const SizedBox(height: 20),
                              Text('TARGET: ${state.targetIp} | TAG: ${state.targetTag}', style: const TextStyle(color: Colors.cyan)),
                              Text('SCRAMBLED: ${state.scrambledString}', style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 20),
                              const Text('[TAP HERE TO WIN - SIMULATING PUZZLE SUBMISSION]', style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                         ref.read(ghostTraceProvider.notifier).increaseConfidence(0.2);
                      },
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('NETWORK SCAN PHASE', style: TextStyle(color: Colors.green, fontSize: 20)),
                              const SizedBox(height: 20),
                              Text('CONFIDENCE: ${(state.traceConfidence * 100).toInt()}%', style: const TextStyle(color: Colors.cyan)),
                              const SizedBox(height: 20),
                              const Text('[TAP HERE TO IDENTIFY SUSPICIOUS NODE/TRACE HOPS]', style: TextStyle(color: Colors.white54)),
                            ]
                          )
                        )
                      )
                  )
            ),
          ],
        ),
      ),
    );
  }
}
