import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/persistence/drift_database.dart';
import 'core/state/game_state.dart';
import 'ui/navigation/app_router.dart';
import 'ui/theme/dreadmoor_theme.dart';

void main() async {
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

  // âœ… Warm up the singleton DB connection before anything else
  await AppDatabase.init();

  // âœ… Load player from DB into memory before the router ever fires.
  // This means the router redirect has a synchronous value on the very
  // first frame â€” no async gap, no bounce back to setup.
  final db = AppDatabase.instance;
  final existingPlayer =
      await (db.select(db.players)..limit(1)).getSingleOrNull();

  // Catch async errors globally (Drift / video / scheduler safety)
  runZonedGuarded(
    () => runApp(
      ProviderScope(
        overrides: [
          // âœ… Seeds playerStateProvider with the DB value before first frame.
          // Router redirect reads this synchronously â€” always up to date.
          playerStateProvider.overrideWith((ref) => existingPlayer),
        ],
        child: const DreadmoorApp(),
      ),
    ),
    (error, stack) {
      debugPrint('ðŸ”¥ Uncaught error: $error');
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
    debugPrint('ðŸ“± App lifecycle changed: $state');
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
            backgroundColor: const Color(0xFF0A0A0A),
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
