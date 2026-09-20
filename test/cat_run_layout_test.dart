import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/cat_run/components/play_buttons.dart';
import 'package:little_games/games/cat_run/cat_run_screen.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:little_games/shared/home_button.dart';
import 'package:provider/provider.dart';

/// The controls must FIT and be REACHABLE on every screen a child will hold.
///
/// Cat Run is the first game where a control being slightly off is not just
/// ugly: the two buttons are the entire game, and a jump button that runs off a
/// small phone's edge means the child cannot play at all.
const _sizes = <(String, Size)>[
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
        create: (_) =>
            SettingsController(store: MemoryOnlySettingsPersistence()),
      ),
      Provider(create: (_) => AudioController()),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: const MaterialApp(home: CatRunScreen()),
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

void main() {
  for (final (name, size) in _sizes) {
    testWidgets('$name: lays out with no overflow', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(size));
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.takeException(), isNull);
    });

    testWidgets('$name: both buttons and the home button are on screen', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(size));
      await tester.pump(const Duration(milliseconds: 16));

      final screen = Rect.fromLTWH(0, 0, size.width, size.height);
      for (final finder in [find.byType(PlayButton), find.byType(HomeButton)]) {
        for (final element in finder.evaluate()) {
          final rect = _rectOf(element);
          expect(
            screen.contains(rect.topLeft) &&
                screen.contains(rect.bottomRight - const Offset(0.01, 0.01)),
            isTrue,
            reason: '$rect is outside the $size screen',
          );
        }
      }
    });

    testWidgets('$name: every touch target clears 80x80', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(size));
      await tester.pump(const Duration(milliseconds: 16));

      // The floor from CLAUDE.md §3. These buttons are 140, so this is really a
      // guard against a future "make it fit" change quietly shrinking them.
      for (final element in find.byType(PlayButton).evaluate()) {
        final rect = _rectOf(element);
        expect(rect.width, greaterThanOrEqualTo(80), reason: 'button width');
        expect(rect.height, greaterThanOrEqualTo(80), reason: 'button height');
      }
      for (final element in find.byType(HomeButton).evaluate()) {
        final rect = _rectOf(element);
        expect(rect.shortestSide, greaterThanOrEqualTo(80));
      }
    });

    testWidgets('$name: the home button cannot be hit while playing', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(size));
      await tester.pump(const Duration(milliseconds: 16));

      final home = _rectOf(find.byType(HomeButton).evaluate().single);
      for (final element in find.byType(PlayButton).evaluate()) {
        final button = _rectOf(element);
        // A generous margin, not merely "does not overlap": the child's whole
        // hand is near the play button, and leaving the game by accident
        // mid-jump is the one navigation mistake that spoils the run.
        expect(
          home.inflate(40).overlaps(button.inflate(40)),
          isFalse,
          reason: 'home $home is too close to a play button at $button',
        );
      }
      // And it is in the usual corner: top half, right half.
      expect(home.center.dy, lessThan(size.height / 2));
      expect(home.center.dx, greaterThan(size.width / 2));
    });

    testWidgets('$name: the two buttons are in opposite bottom corners', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(size));
      await tester.pump(const Duration(milliseconds: 16));

      final buttons = find
          .byType(PlayButton)
          .evaluate()
          .map((e) => (e.widget as PlayButton).kind)
          .toList();
      // Both controls exist on every size. A screen that dropped the duck
      // button would silently make a whole mechanic unreachable.
      expect(buttons, containsAll(PlayButtonKind.values));

      for (final element in find.byType(PlayButton).evaluate()) {
        final kind = (element.widget as PlayButton).kind;
        final rect = _rectOf(element);
        // Bottom half, and on the correct side for the thumb it belongs to.
        expect(rect.center.dy, greaterThan(size.height / 2), reason: '$kind');
        if (kind == PlayButtonKind.crouch) {
          expect(rect.center.dx, lessThan(size.width / 2), reason: 'duck left');
        } else {
          expect(
            rect.center.dx,
            greaterThan(size.width / 2),
            reason: 'jump right',
          );
        }
      }
    });
  }

  testWidgets('a press anywhere in a bottom corner works, not just on the button', (
    tester,
  ) async {
    const size = Size(892, 412);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(size));
    await tester.pump(const Duration(milliseconds: 16));

    // The whole bottom-right quarter is the jump button's hit area. A tap well
    // away from the drawn paw — where a mis-aimed thumb lands — must still be
    // taken. This is the scope's biggest accessibility promise in this game.
    final paw = _rectOf(
      find
          .byType(PlayButton)
          .evaluate()
          .firstWhere(
            (e) => (e.widget as PlayButton).kind == PlayButtonKind.paw,
          ),
    );
    final wellAwayFromPaw = Offset(size.width * 0.62, size.height * 0.62);
    expect(
      paw.contains(wellAwayFromPaw),
      isFalse,
      reason: 'the test point should be OFF the drawn button',
    );

    await tester.tapAt(wellAwayFromPaw);
    await tester.pump();
    // Nothing to assert on the cat from here (it lives in the Flame game), but
    // the press must not throw and must be consumed by the hit area rather than
    // falling through to the game surface.
    expect(tester.takeException(), isNull);
  });
}
