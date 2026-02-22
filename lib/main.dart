import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For system overlay control
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/navigation/app_router.dart';
import 'ui/theme/dreadmoor_theme.dart';

void main() async {
  // Ensure Flutter is ready before we mess with the system UI
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation (cinematic portrait feel)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar + dark nav bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Catch async errors globally (Drift / video / scheduler safety)
  runZonedGuarded(
    () => runApp(const ProviderScope(child: DreadmoorApp())),
    (error, stack) {
      debugPrint('🔥 Uncaught error: $error');
    },
  );
}

class DreadmoorApp extends ConsumerStatefulWidget {
  const DreadmoorApp({super.key});

  @override
  ConsumerState<DreadmoorApp> createState() => _DreadmoorAppState();
}

class _DreadmoorAppState extends ConsumerState<DreadmoorApp>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: Pause scheduler/video when backgrounded
    // TODO: Resume when foregrounded
    debugPrint('📱 App lifecycle changed: $state');
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Dreadmoor',
      theme: DreadmoorTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,

      // Global vignette + text scale clamp
      builder: (context, child) {
        final media = MediaQuery.of(context);

        return MediaQuery(
          data: media.copyWith(
            textScaleFactor: media.textScaleFactor.clamp(0.9, 1.1),
          ),
          child: Scaffold(
            backgroundColor: const Color(0xFF0A0A0A), // Real Noir Background
            body: Stack(
              children: [
                child!,
                // Subtle vignette effect (darken edges)
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
