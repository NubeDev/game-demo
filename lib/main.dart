import 'package:flame/flame.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_lifecycle/app_lifecycle.dart';
import 'audio/audio_controller.dart';
import 'player_progress/player_progress.dart';
import 'router.dart';
import 'settings/settings.dart';
import 'shared/kid_palette.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Rive 0.14+ requires its native runtime to be initialised before any file is
  // loaded. Must happen before any RiveCharacter is created (CLAUDE.md §2).
  //
  // Nothing loads a .riv yet — no character art exists. This stays because the
  // failure it prevents is a confusing one: a .riv added later without it fails
  // at load with no obvious cause.
  await RiveNative.init();

  // Landscape only, both ways round so it doesn't matter which way the tablet
  // is picked up. Locked at the Flutter level here; the native manifests also
  // declare it so the OS never offers portrait.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await Flame.device.setLandscape();
  await Flame.device.fullScreen();

  runApp(const LittleGamesApp());
}

class LittleGamesApp extends StatelessWidget {
  const LittleGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => PlayerProgress()),
          Provider(create: (context) => SettingsController()),
          // Set up audio.
          ProxyProvider2<
            SettingsController,
            AppLifecycleStateNotifier,
            AudioController
          >(
            // Ensures that music starts immediately.
            lazy: false,
            create: (context) => AudioController(),
            update: (context, settings, lifecycleNotifier, audio) {
              audio!.attachDependencies(lifecycleNotifier, settings);
              return audio;
            },
            dispose: (context, audio) => audio.dispose(),
          ),
        ],
        child: MaterialApp.router(
          title: 'Little Games',
          // The template's 8-bit "NES" theme and pixel font are wrong for this
          // audience — hard arcade edges read as harsh, and the font is
          // illegible to an adult in the parent area at small sizes. Plain
          // rounded Material instead.
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: KidPalette.playColors[4],
            ),
            scaffoldBackgroundColor: KidPalette.menuBackground,
          ),
          routerConfig: router,
        ),
      ),
    );
  }
}
