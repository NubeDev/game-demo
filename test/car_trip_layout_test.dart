import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/car_trip/car_trip_screen.dart';
import 'package:little_games/games/car_trip/components/horn_button.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:little_games/shared/home_button.dart';
import 'package:provider/provider.dart';

/// The controls must FIT and be REACHABLE on every screen a child will hold.
///
/// Car Trip has fewer controls than Cat Run but a harder layout problem: the
/// steering area is the bottom half of the screen, and both buttons sit on top
/// of it. If the horn creeps under the thumb, every honk swerves the car; if
/// the home button does, the child leaves the game by accident.
const _sizes = <(String, Size)>[
  ('pixel landscape', Size(892, 412)),
  ('small phone landscape', Size(740, 360)),
  ('iphone se landscape', Size(667, 375)),
  ('large phone landscape', Size(956, 440)),
  ('tablet landscape', Size(1280, 800)),
  // 2.22:1 — the shape of the emulator this was first driven on, and of the
  // long thin phones that keep getting longer and thinner.
  ('very wide phone landscape', Size(1200, 540)),
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
      Provider(create: (_) => AudioController()),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: const MaterialApp(home: CarTripScreen()),
    ),
  );
}

Rect _rectOf(Element element) {
  final box = element.renderObject! as RenderBox;
  return MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
}

Rect _only(Finder finder) {
  final elements = finder.evaluate().toList();
  expect(elements, hasLength(1));
  return _rectOf(elements.single);
}

void main() {
  for (final (name, size) in _sizes) {
    group(name, () {
      Future<void> pump(WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(size));
        await tester.pump(const Duration(milliseconds: 16));
      }

      testWidgets('lays out with no overflow', (tester) async {
        await pump(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the horn and the home button are on screen and big', (
        tester,
      ) async {
        await pump(tester);
        final screen = Rect.fromLTWH(0, 0, size.width, size.height);

        for (final finder in [
          find.byType(HornButton),
          find.byType(HomeButton),
        ]) {
          final rect = _only(finder);
          expect(
            screen.contains(rect.topLeft) && screen.contains(rect.bottomRight),
            isTrue,
            reason: '$rect runs off a ${size.width}x${size.height} screen',
          );
          // The kid rule, checked rather than assumed (CLAUDE.md §3).
          expect(rect.width, greaterThanOrEqualTo(80));
          expect(rect.height, greaterThanOrEqualTo(80));
        }
      });

      testWidgets('the horn cannot be hit while reaching for home', (
        tester,
      ) async {
        await pump(tester);
        final horn = _only(find.byType(HornButton));
        final home = _only(find.byType(HomeButton));

        expect(horn.overlaps(home), isFalse);
        // Opposite corners, so neither is in the other's reach: leaving must
        // never be a thing that happens by accident mid-honk.
        expect(
          (horn.center - home.center).distance,
          greaterThan(size.shortestSide * 0.6),
        );
      });

      testWidgets('the steering area covers the bottom half and leaves the '
          'home button alone', (tester) async {
        await pump(tester);
        final steering = _only(find.byKey(CarTripScreen.steeringKey));
        final home = _only(find.byType(HomeButton));

        // It reaches the very bottom, and both side edges: a thumb anywhere
        // down there steers.
        expect(steering.bottom, closeTo(size.height, 0.5));
        expect(steering.left, 0);
        expect(steering.right, closeTo(size.width, 0.5));
        expect(steering.height, greaterThan(size.height * 0.4));

        // And it never reaches the home button.
        expect(steering.overlaps(home), isFalse);
      });
    });
  }

  testWidgets('a thumb on the steering area drives the car, anywhere in it', (
    tester,
  ) async {
    const size = Size(1280, 800);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(size));
    await tester.pump(const Duration(milliseconds: 16));

    final state = tester.state<State<CarTripScreen>>(
      find.byType(CarTripScreen),
    );
    // ignore: avoid_dynamic_calls
    final game = (state as dynamic).gameForTest;

    // Press well off to the right, near the bottom corner — nowhere near the
    // car, which is the entire point of a steering AREA rather than a wheel.
    final gesture = await tester.startGesture(const Offset(1100, 720));
    await tester.pump(const Duration(milliseconds: 16));
    for (var i = 0; i < 40; i++) {
      game.update(1 / 60);
    }

    expect(
      game.car.lateral,
      greaterThan(0.5),
      reason: 'a thumb in the bottom-right corner did not steer the car right',
    );

    // And letting go stops the car rather than doing anything dramatic.
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 16));
    for (var i = 0; i < 200; i++) {
      game.update(1 / 60);
    }
    expect(game.speedFactor, 0);
  });
}
