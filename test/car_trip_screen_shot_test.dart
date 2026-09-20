@Tags(['render'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/car_trip/car_trip_screen.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:provider/provider.dart';

/// Renders Car Trip so it can actually be LOOKED at.
///
/// Not a golden test — nothing is compared. Everything in this game is drawn in
/// code, and `flutter test` cannot tell whether a trapezoid reads as a road,
/// whether the car reads as a car from behind, or whether a cone at the horizon
/// is big enough to see coming. Those are exactly the things this game has to
/// get right, and only eyes answer them.
///
///   flutter test --tags render --dart-define=SHOT_DIR=/tmp/shots
const _outDir = String.fromEnvironment('SHOT_DIR', defaultValue: '');

class _SilentAudio implements AudioController {
  @override
  void noSuchMethod(Invocation invocation) {}
}

const _shots = <(String, Size)>[
  ('tablet', Size(1280, 800)),
  ('iphone-se', Size(667, 375)),
  ('pixel', Size(892, 412)),
];

Widget _app(Size size) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) =>
            PlayerProgress(store: MemoryOnlyPlayerProgressPersistence()),
      ),
      Provider(
        create: (_) =>
            SettingsController(store: MemoryOnlySettingsPersistence()),
      ),
      // A silent stand-in, NOT a real AudioController: the real one preloads
      // the sfx through path_provider, which has no plugin in a widget test —
      // it throws MissingPluginException and fails the shot.
      Provider<AudioController>(create: (_) => _SilentAudio()),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: const MaterialApp(
        home: RepaintBoundary(key: Key('shot'), child: CarTripScreen()),
      ),
    ),
  );
}

/// Writes the current frame to a PNG.
///
/// Inside `runAsync` on purpose: `toImage()` is completed by the engine, and a
/// widget test's fake-async zone never runs that work — awaiting it directly
/// hangs the test outright, sometimes on the first shot and sometimes on the
/// second. `runAsync` is the documented way to wait on real async work from a
/// widget test.
Future<void> _save(WidgetTester tester, String name) async {
  if (_outDir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('shot')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_outDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  for (final (name, size) in _shots) {
    testWidgets('render $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(size));
      // Long enough for the Flame loop to lay the scene out and draw it.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // The empty road, with the hand hint still showing.
      await _save(tester, 'car-trip-$name-start');

      // Then a road that has been driven down for a while, which is the only
      // way to see things at every distance at once — at the horizon, halfway,
      // and about to go under the car.
      final state = tester.state<State<CarTripScreen>>(
        find.byType(CarTripScreen),
      );
      // ignore: avoid_dynamic_calls
      final game = (state as dynamic).gameForTest;

      // Drive by PUMPING REAL FRAMES rather than calling game.update() in a
      // tight loop. Hundreds of manual updates between frames leave the
      // binding with work it has not drawn, and the next
      // `RenderRepaintBoundary.toImage()` then never completes — the test
      // simply hangs. Letting the widget tester drive the clock keeps the
      // engine and the game in step, which is also closer to what a player
      // gets.
      const frame = Duration(milliseconds: 16);
      for (var i = 0; i < 300; i++) {
        // Holding a thumb on the steering area, wandering gently across the
        // road so the shot catches the car off the centre line.
        // ignore: avoid_dynamic_calls
        game.steerToScreenX(size.width * (0.5 + 0.09 * (i % 150) / 150));
        await tester.pump(frame);
      }
      await _save(tester, 'car-trip-$name-driving');
    });
  }
}
