import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/navigation/app_router.dart';
import 'ui/theme/dreadmoor_theme.dart';

void main() {
  runApp(const ProviderScope(child: DreadmoorApp()));
}

class DreadmoorApp extends ConsumerWidget {
  const DreadmoorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Dreadmoor',
      theme: DreadmoorTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
