import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/game_state.dart';
import '../../core/models/script_models.dart';
import '../../core/scheduler/global_scheduler.dart';

class ChoiceOverlay extends ConsumerWidget {
  const ChoiceOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = ref.watch(waitingForChoiceProvider);
    if (!waiting) return const SizedBox.shrink();

    final scheduler = ref.read(globalSchedulerProvider);
    final choices = scheduler.getCurrentChoices();

    if (choices == null || choices.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.8),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('CHOOSE WISELY', style: TextStyle(fontFamily: 'Cinzel', color: Colors.white, letterSpacing: 2)),
              const SizedBox(height: 20),
              ...choices.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => scheduler.submitChoice(c.jumpto),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.purple, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      c.text,
                      style: const TextStyle(fontSize: 16, fontFamily: 'Merriweather'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
