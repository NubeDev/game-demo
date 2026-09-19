import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/dress_the_dog/components/dog.dart';
import 'package:little_games/games/dress_the_dog/components/wardrobe_rail.dart';
import 'package:little_games/games/dress_the_dog/components/weather_switch.dart';
import 'package:little_games/games/dress_the_dog/dress_the_dog_screen.dart';
import 'package:little_games/games/dress_the_dog/wardrobe.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:little_games/shared/home_button.dart';
import 'package:provider/provider.dart';

/// The screen must FIT, on every screen a child will actually hold.
///
/// This exists because it did not: on a phone in landscape (~400dp tall) the
/// full-size wardrobe rail ran off the bottom — "BOTTOM OVERFLOWED BY 133
/// PIXELS" on an Android emulator — while the only layout test rendered at
/// tablet size, where everything fit. Small sizes are the cases that break, so
/// they are the ones pinned here.
const _sizes = <(String, Size)>[
  // The Android emulator this was caught on, and phones around it.
  ('pixel landscape', Size(892, 412)),
  ('small phone landscape', Size(740, 360)),
  ('iphone se landscape', Size(667, 375)),
  ('large phone landscape', Size(956, 440)),
  ('tablet landscape', Size(1280, 800)),
];

Widget _app(Size size) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) =>
            PlayerProgress(store: MemoryOnlyPlayerProgressPersistence()),
      ),
      Provider(
        create: (_) => SettingsController(store: MemoryOnlySettingsPersistence()),
      ),
      Provider(create: (_) => AudioController()),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: const MaterialApp(home: DressTheDogScreen()),
    ),
  );
}

void main() {
  for (final (name, size) in _sizes) {
    testWidgets('$name: lays out with no overflow', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(size));
      await tester.pump(const Duration(milliseconds: 16));

      // A RenderFlex overflow is reported as an exception, not a failure.
      expect(tester.takeException(), isNull);
    });

    testWidgets('$name: every control is fully on screen', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(size));
      await tester.pump(const Duration(milliseconds: 16));

      final screen = Rect.fromLTWH(0, 0, size.width, size.height);

      void expectInside(Finder finder, String what) {
        for (final element in finder.evaluate()) {
          final box = element.renderObject! as RenderBox;
          // Painted bounds, so a scaled widget is measured as drawn.
          final rect = MatrixUtils.transformRect(
            box.getTransformTo(null),
            Offset.zero & box.size,
          );
          expect(
            screen.contains(rect.topLeft) &&
                screen.contains(rect.bottomRight - const Offset(0.01, 0.01)),
            isTrue,
            reason: '$what at $rect is outside the $size screen',
          );
        }
      }

      // The dog too, not just the controls: a dog half off the left edge is
      // exactly the kind of break the control-only checks used to miss.
      expectInside(find.byType(Dog), 'dog');
      expectInside(find.byType(HomeButton), 'home button');
      expectInside(find.byType(WardrobeRail), 'wardrobe rail');
      expectInside(find.byType(WeatherSwitch), 'weather switch');
    });

    testWidgets('$name: controls stay past the 80x80 kid rule', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(size));
      await tester.pump(const Duration(milliseconds: 16));

      // CLAUDE.md §3: a target smaller than 80x80 is one a coarse finger
      // cannot hit. Shrinking to fit must never cross that line.
      for (final element in find
          .byType(WardrobeRail)
          .evaluate()) {
        final rail = element.widget as WardrobeRail;
        expect(WardrobeRail.tileSizeFor(rail.scale), greaterThanOrEqualTo(80));
      }
      for (final element in find.byType(WeatherSwitch).evaluate()) {
        final sw = element.widget as WeatherSwitch;
        expect(WeatherSwitch.sizeFor(sw.scale), greaterThanOrEqualTo(80));
      }
    });

    testWidgets('$name: home button does not cover the rail', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(size));
      await tester.pump(const Duration(milliseconds: 16));

      // The PAINTED bounds, transforms included. The dog is drawn through a
      // Transform.scale, whose render box still reports the unscaled size —
      // measuring that instead would report overlaps that are not on screen.
      Rect rectOf(Finder f) {
        final box = f.evaluate().single.renderObject! as RenderBox;
        return MatrixUtils.transformRect(
          box.getTransformTo(null),
          Offset.zero & box.size,
        );
      }

      // The way out must never be blocked, and a reach for a coat must never
      // land on it either (CLAUDE.md §3).
      expect(
        rectOf(find.byType(HomeButton))
            .overlaps(rectOf(find.byType(WardrobeRail))),
        isFalse,
      );
      expect(
        rectOf(find.byType(WeatherSwitch))
            .overlaps(rectOf(find.byType(WardrobeRail))),
        isFalse,
      );

      // Nothing sits on top of the dog either — a button over its legs reads
      // as part of the dog to a child aiming at it.
      final dog = rectOf(find.byType(Dog));
      expect(dog.overlaps(rectOf(find.byType(WardrobeRail))), isFalse,
          reason: 'rail overlaps the dog');
      expect(dog.overlaps(rectOf(find.byType(WeatherSwitch))), isFalse,
          reason: 'weather buttons overlap the dog');
      expect(dog.overlaps(rectOf(find.byType(HomeButton))), isFalse,
          reason: 'home button overlaps the dog');
    });
  }

  testWidgets('every slot fits, not just the first', (tester) async {
    // The rail is as tall as its fullest slot; a slot with more items than
    // 'head' must not overflow when the child taps its tab.
    const size = Size(892, 412);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(size));
    await tester.pump(const Duration(milliseconds: 16));

    // The four slot tabs are the first four tap targets in the rail.
    for (var i = 0; i < Slot.values.length; i++) {
      final tabs = find.descendant(
        of: find.byType(WardrobeRail),
        matching: find.byType(GestureDetector),
      );
      await tester.tapAt(tester.getCenter(tabs.at(i)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull, reason: 'slot ${Slot.values[i]}');
    }
  });
}
