import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/persistence/drift_database.dart';
import 'core/state/game_state.dart';
import 'ui/navigation/app_router.dart';
import 'ui/theme/dreadmoor_theme.dart';

import 'features/notifications/notification_state.dart';
import 'features/phone/phone_state.dart';
import 'ui/widgets/notification_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await AppDatabase.init();

  final db = AppDatabase.instance;

  final existingPlayer = await (db.select(
    db.players,
  )..limit(1)).getSingleOrNull();

  runZonedGuarded(
    () => runApp(
      ProviderScope(
        overrides: [
          playerStateProvider.overrideWith(() {
            return _PreloadedPlayerStateNotifier(existingPlayer);
          }),
        ],
        child: const DreadmoorApp(),
      ),
    ),
    (error, stack) {
      debugPrint('🔥 Uncaught error: $error');
    },
  );
}

class _PreloadedPlayerStateNotifier extends PlayerStateNotifier {
  final Player? _initialPlayer;
  _PreloadedPlayerStateNotifier(this._initialPlayer);

  @override
  Player? build() => _initialPlayer;
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
    final scheduler = ref.read(globalSchedulerProvider);
    final phoneState = ref.read(phoneProvider);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      scheduler.pause();
    }

    // Only resume the scheduler if we are NOT currently in the middle of a phone call.
    // If we are in a call, we want the scheduler to remain paused until the call finishes.
    if (state == AppLifecycleState.resumed) {
      if (phoneState.callState == CallState.idle) {
        scheduler.resume();
      }
    }

    debugPrint('📱 App lifecycle changed: $state');
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Dreadmoor',
      theme: DreadmoorTheme.lightTheme,
      darkTheme: DreadmoorTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,

      builder: (context, child) {
        final media = MediaQuery.of(context);

        return MediaQuery(
          data: media.copyWith(
            textScaleFactor: media.textScaleFactor.clamp(0.9, 1.1),
          ),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: child!,
          ),
        );
      },
    );
  }
}
