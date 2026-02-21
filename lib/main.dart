import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For system overlay control
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/navigation/app_router.dart';
import 'ui/theme/dreadmoor_theme.dart';

void main() async {
  // Ensure Flutter is ready before we mess with the system UI
  WidgetsFlutterBinding.ensureInitialized();

  // Set the system bars to transparent to create an immersive cinematic feel
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: DreadmoorApp()));
}

class DreadmoorApp extends ConsumerWidget {
  const DreadmoorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Dreadmoor',
      // We will ensure DreadmoorTheme.darkTheme is stripped of "Material defaults"
      theme: DreadmoorTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      
      // Global builder to add a "Grain" or "Vignette" overlay across all screens
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A), // Real Noir Background
          body: Stack(
            children: [
              child!,
              // Sublte vignette effect to make the edges of the screen darker
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
        );
      },
    );
  }
}
