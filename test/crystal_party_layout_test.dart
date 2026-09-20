import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/crystal_party/components/unicorn.dart';
import 'package:little_games/games/crystal_party/crystal_party_screen.dart';
import 'package:little_games/games/crystal_party/world.dart';
import 'package:little_games/menu/game_tile.dart';
import 'package:little_games/menu/home_screen.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:little_games/shared/home_button.dart';
import 'package:provider/provider.dart';

/// The control must be reachable on every screen a child will hold.
///
/// In this game the control IS the screen, so what matters is the other way
/// round from Cat Run: the play area must cover almost everything, and the
/// home button must still be reachable without flying her by accident.
const _sizes = <(String, Size)>[
  ('pixel landscape', Size(892, 412)),
  ('small phone landscape', Size(740, 360)),
  ('iphone se landscape', Size(667, 375)),
  ('large phone landscape', Size(956, 440)),
  ('tablet landscape', Size(1280, 800)),
];

Widget _app(Widget child, Size size) {
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
      child: MaterialApp(home: child),
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
    group(name, () {
      testWidgets('lays out with no overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_app(const CrystalPartyScreen(), size));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('the home button is big, cornered and clear of the play '
          'area', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_app(const CrystalPartyScreen(), size));
        await tester.pump();

        final home = _rectOf(find.byType(HomeButton).evaluate().single);
        // The kid rule (CLAUDE.md §3).
        expect(home.width, greaterThanOrEqualTo(80));
        expect(home.height, greaterThanOrEqualTo(80));
        // On screen, in the top-right corner.
        expect(home.right, lessThanOrEqualTo(size.width));
        expect(home.top, greaterThanOrEqualTo(0));

        // And entirely OUT of the play area, so a thumb reaching for home
        // never flies her instead.
        expect(
          home.bottom,
          lessThanOrEqualTo(CrystalPartyScreen.topBandHeight),
          reason: 'the home button must not sit inside the hold area',
        );
      });

      testWidgets('the play area is almost the whole screen', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_app(const CrystalPartyScreen(), size));
        await tester.pump();

        // The whole screen is the button — the largest target in the app, and
        // the reason there is nothing here to aim at or miss.
        final area = find.byWidgetPredicate(
          (w) => w is GestureDetector && w.onPanDown != null,
        );
        final rect = _rectOf(area.evaluate().single);
        expect(rect.width, closeTo(size.width, 1));
        expect(
          rect.height,
          greaterThan(size.height * 0.6),
          reason: 'the hold area must dominate the screen',
        );
      });
    });

    testWidgets('$name: every menu tile clears the 80x80 kid rule', (
      tester,
    ) async {
      // This is the test that stops a newly added game quietly shrinking the
      // tiles below what a five-year-old can hit. Deliberately NOT pinned to a
      // game count any more — the count changes every time a game lands, and
      // an assertion that has to be edited alongside the change it is meant to
      // catch is not guarding anything.
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(const HomeScreen(), size));
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'the menu overflowed');

      final tiles = find.byType(GameTile);
      expect(
        tiles.evaluate().length,
        greaterThanOrEqualTo(8),
        reason: 'every game on the menu must be one of these tiles',
      );
      for (final element in tiles.evaluate()) {
        final rect = _rectOf(element);
        expect(rect.width, greaterThanOrEqualTo(80));
        expect(rect.height, greaterThanOrEqualTo(80));
        // And on screen: nothing may need scrolling to reach.
        expect(rect.left, greaterThanOrEqualTo(-0.5));
        expect(rect.right, lessThanOrEqualTo(size.width + 0.5));
        expect(rect.top, greaterThanOrEqualTo(-0.5));
        expect(rect.bottom, lessThanOrEqualTo(size.height + 0.5));
      }
    });
  }

  group('the sky fits every screen', () {
    test('a short screen still gets a sky worth flying in', () {
      for (final (name, size) in _sizes) {
        final unicorn = Unicorn(position: Vector2.zero());
        // The ground line the game uses.
        final groundY = size.height * 0.8;
        unicorn.fitTo(headroom: groundY);

        expect(
          unicorn.ceiling,
          greaterThanOrEqualTo(Unicorn.minCeiling),
          reason: '$name: the sky collapsed',
        );
        // And a pink crystal at the very top is still inside it, or the child
        // could see a crystal they cannot reach.
        final highestPink = CrystalPartyWorld.pinkHigh * unicorn.ceiling;
        expect(highestPink, lessThanOrEqualTo(unicorn.ceiling), reason: name);
      }
    });
  });
}
