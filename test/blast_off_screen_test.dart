import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/blast_off/blast_off_screen.dart';
import 'package:little_games/games/blast_off/components/big_button.dart';
import 'package:little_games/games/blast_off/countdown.dart';
import 'package:little_games/menu/game_tile.dart';
import 'package:little_games/menu/home_screen.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:little_games/shared/home_button.dart';
import 'package:provider/provider.dart';

/// Every screen a child will actually hold. The menu now carries four games,
/// and a landscape phone is SHORT, not just narrow — the layout that broke
/// Dress the Dog was only ever caught at these sizes.
const _sizes = <(String, Size)>[
  ('pixel landscape', Size(892, 412)),
  ('small phone landscape', Size(740, 360)),
  ('iphone se landscape', Size(667, 375)),
  ('large phone landscape', Size(956, 440)),
  ('tablet landscape', Size(1280, 800)),
];

Widget _wrap(Widget child) {
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
    child: MaterialApp(home: child),
  );
}

Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_wrap(child));
  await tester.pump();
}

void main() {
  group('the menu still fits with a fourth game', () {
    for (final (name, size) in _sizes) {
      testWidgets('$name shows every game, big enough to hit', (tester) async {
        await _pumpAt(tester, size, const HomeScreen());

        // Everything visible at once: no scrolling, because a five-year-old
        // does not discover that content exists off-screen (CLAUDE.md §3).
        expect(find.byType(GameTile), findsNWidgets(4));
        expect(tester.takeException(), isNull);

        for (final tile in tester.widgetList<GameTile>(find.byType(GameTile))) {
          expect(
            tile.size,
            greaterThanOrEqualTo(80),
            reason: 'touch target floor, $name',
          );
        }
      });
    }

    testWidgets('and still has no text on it', (tester) async {
      await _pumpAt(tester, const Size(892, 412), const HomeScreen());
      expect(find.byType(Text), findsNothing);
    });
  });

  group('blast off screen', () {
    testWidgets('offers the lengths and a way to start, with no text', (
      tester,
    ) async {
      await _pumpAt(tester, const Size(892, 412), const BlastOffScreen());

      // Three presets, less, more, and GO. Every one is a picture, and the
      // chosen length shows as dots, so a child who cannot read can set and
      // start a countdown with no text at all (CLAUDE.md §3).
      expect(find.byType(BigButton), findsNWidgets(6));
      expect(find.bySemanticsLabel('less'), findsOneWidget);
      expect(find.bySemanticsLabel('more'), findsOneWidget);

      // The ONLY text on the screen is the adult's clock readout. If anything
      // else here ever renders text, it is a bug — this assertion is the
      // guard on the one exception the game is allowed.
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('0:10'), findsOneWidget, reason: 'the default rung');
    });

    testWidgets('every button clears the 80x80 floor', (tester) async {
      for (final (name, size) in _sizes) {
        await _pumpAt(tester, size, const BlastOffScreen());

        // The RENDERED size, not the requested one: the waiting row scales
        // down to fit a narrow phone, and it is the size under the child's
        // thumb that has to clear 80x80 (CLAUDE.md §3).
        for (final element in find.byType(BigButton).evaluate()) {
          final box = element.renderObject! as RenderBox;
          final onScreen = MatrixUtils.transformRect(
            box.getTransformTo(null),
            Offset.zero & box.size,
          );
          expect(onScreen.width, greaterThanOrEqualTo(80), reason: name);
          expect(onScreen.height, greaterThanOrEqualTo(80), reason: name);
        }

        final home = tester.getSize(find.byType(HomeButton));
        expect(home.width, greaterThanOrEqualTo(80), reason: name);
        expect(tester.takeException(), isNull, reason: name);
      }
    });

    testWidgets('more and less change the time, and the dots show it', (
      tester,
    ) async {
      await _pumpAt(tester, const Size(892, 412), const BlastOffScreen());

      Iterable<AnimatedContainer> dots() =>
          tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));

      // The dots are the only readout of the length, so "it got longer" has
      // to be visible in them.
      final before = dots().map((d) => d.constraints?.maxWidth).toList();

      await tester.tap(find.bySemanticsLabel('more'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        dots().map((d) => d.constraints?.maxWidth).toList(),
        isNot(equals(before)),
        reason: 'one more dot fills when the countdown gets longer',
      );

      // And back again.
      await tester.tap(find.bySemanticsLabel('less'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(dots().map((d) => d.constraints?.maxWidth).toList(), before);
    });

    testWidgets('a preset jumps straight to a length', (tester) async {
      await _pumpAt(tester, const Size(892, 412), const BlastOffScreen());

      // Three presets, each reachable in one tap — a child who just wants to
      // go never has to step.
      expect(find.bySemanticsLabel(RegExp('^preset ')), findsNWidgets(3));

      await tester.tap(find.bySemanticsLabel('preset 300s'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the clock shows the time being set, and follows more/less', (
      tester,
    ) async {
      await _pumpAt(tester, const Size(892, 412), const BlastOffScreen());

      // It starts on the default rung and must move when the child does.
      expect(find.text('0:10'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('more'));
      await tester.pump();
      expect(find.text('0:15'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('less'));
      await tester.pump();
      expect(find.text('0:10'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('preset 300s'));
      await tester.pump();
      expect(find.text('5:00'), findsOneWidget);
    });

    testWidgets('pause holds the countdown, play carries it on', (
      tester,
    ) async {
      await _pumpAt(tester, const Size(892, 412), const BlastOffScreen());

      await tester.tap(find.bySemanticsLabel('preset 300s'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('go'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Pause is offered the whole time the countdown is underway.
      expect(find.bySemanticsLabel('pause'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('pause'));
      await tester.pump();

      // It swaps to play in place, and stop stays beside it.
      expect(find.bySemanticsLabel('play'), findsOneWidget);
      expect(find.bySemanticsLabel('pause'), findsNothing);
      expect(find.bySemanticsLabel('stop'), findsOneWidget);

      // Held: the clock must not move while paused.
      final held = tester.widget<Text>(find.byType(Text)).data;
      await tester.pump(const Duration(seconds: 3));
      expect(tester.widget<Text>(find.byType(Text)).data, held);

      await tester.tap(find.bySemanticsLabel('play'));
      await tester.pump();
      expect(find.bySemanticsLabel('pause'), findsOneWidget);
    });

    testWidgets('after the launch the child is offered another one', (
      tester,
    ) async {
      // The regression this pins: the "again" button used to wait on a clock
      // that only advances inside the Flame loop, and the loop stops once the
      // launch has nothing left to animate. The button never appeared, so the
      // child was left on a dead screen with nothing to press but home — at
      // the best moment in the game. It looked exactly like a crash.
      await _pumpAt(tester, const Size(892, 412), const BlastOffScreen());

      await tester.tap(find.bySemanticsLabel('go'));
      await tester.pump();

      // Run the countdown right through to the launch. The Flame loop does
      // not advance at wall-clock speed under the test binding, so the frames
      // are pumped until the launch actually lands rather than for a fixed
      // number of them.
      for (var i = 0; i < 60 * 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (find.bySemanticsLabel('again').evaluate().isNotEmpty) break;
      }

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('again'), findsOneWidget);
      expect(
        find.byType(HomeButton),
        findsOneWidget,
        reason: 'and the way out is still there',
      );
      // It also has to be a real, hittable button: it once laid out at zero
      // width off the top of the screen, which looked exactly like the game
      // having crashed.
      final button = tester.getRect(find.bySemanticsLabel('again'));
      expect(button.width, greaterThanOrEqualTo(80));
      expect(button.height, greaterThanOrEqualTo(80));
      expect(
        tester.getRect(find.byType(Scaffold)).contains(button.center),
        isTrue,
        reason: 'the again button must be on screen',
      );

      await tester.tap(find.bySemanticsLabel('again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.bySemanticsLabel('again'), findsNothing);
    });

    testWidgets('the way home is always there, before and during a count', (
      tester,
    ) async {
      await _pumpAt(tester, const Size(892, 412), const BlastOffScreen());
      expect(find.byType(HomeButton), findsOneWidget);

      // Start it, and the child must still be able to leave — a countdown
      // that traps them until zero would be the worst version of this game.
      await tester.tap(find.bySemanticsLabel('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(HomeButton), findsOneWidget);
      expect(
        find.bySemanticsLabel('stop'),
        findsOneWidget,
        reason: 'stopping is always offered, and costs nothing',
      );
    });
  });

  /// The controls are one row on EVERY screen.
  ///
  /// They used to wrap onto a second row when narrow, which made the control
  /// band 268px tall — more than a landscape iPhone SE can spare — and the
  /// rocket was then drawn underneath the buttons, which also stole its taps.
  /// When the row will not fit, the ± steppers drop out instead.
  group('the controls stay on one row', () {
    for (final (name, size) in _sizes) {
      testWidgets('$name: every length is still reachable', (tester) async {
        await _pumpAt(tester, size, const BlastOffScreen());

        // The presets never drop: they are the child's whole route to
        // choosing a length, and between them they reach every rung.
        expect(
          find.bySemanticsLabel(RegExp('^preset')),
          findsNWidgets(CountdownLength.presets.length),
        );
        // GO never drops either.
        expect(find.bySemanticsLabel('go'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$name: no control is under the 80x80 floor', (tester) async {
        await _pumpAt(tester, size, const BlastOffScreen());

        // FittedBox scales the row, so the RENDERED size is what matters —
        // a button laid out at 92 but painted at 70 is still a miss for a
        // five-year-old (CLAUDE.md §3).
        for (final element in find.byType(BigButton).evaluate()) {
          final box = element.renderObject! as RenderBox;
          final painted = MatrixUtils.transformRect(
            box.getTransformTo(null),
            Offset.zero & box.size,
          );
          expect(
            painted.shortestSide,
            greaterThanOrEqualTo(79.9),
            reason: '$name: a control shrank below the touch-target floor',
          );
        }
      });
    }

    testWidgets('a narrow screen drops the steppers, not the presets', (
      tester,
    ) async {
      await _pumpAt(tester, const Size(667, 375), const BlastOffScreen());
      expect(find.bySemanticsLabel('less'), findsNothing);
      expect(find.bySemanticsLabel('more'), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp('^preset')),
        findsNWidgets(CountdownLength.presets.length),
        reason: 'the child route must survive; the adult nudge buttons may not',
      );
    });

    testWidgets('a roomy screen keeps the steppers', (tester) async {
      await _pumpAt(tester, const Size(1280, 800), const BlastOffScreen());
      expect(find.bySemanticsLabel('less'), findsOneWidget);
      expect(find.bySemanticsLabel('more'), findsOneWidget);
    });
  });
}
