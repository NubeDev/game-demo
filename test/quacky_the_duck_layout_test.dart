import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/quacky_the_duck/components/play_buttons.dart';
import 'package:little_games/games/quacky_the_duck/quacky_the_duck_screen.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:little_games/shared/home_button.dart';
import 'package:provider/provider.dart';

/// The controls must FIT and be REACHABLE on every screen a child will hold.
///
/// The two buttons are the entire game: a dash button that runs off a small
/// phone's edge means the child cannot play at all.
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
      child: const MaterialApp(home: QuackyTheDuckScreen()),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(size));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  for (final (name, size) in _sizes) {
    group(name, () {
      testWidgets('lays out with no overflow', (tester) async {
        await _pump(tester, size);
        expect(
          tester.takeException(),
          isNull,
          reason: 'an overflow stripe on a child\'s screen is a bug',
        );
      });

      testWidgets('every touch target clears 80x80', (tester) async {
        await _pump(tester, size);

        for (final element in find.byType(QuackyButton).evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          // The kid rule (CLAUDE.md §3).
          expect(rect.width, greaterThanOrEqualTo(80));
          expect(rect.height, greaterThanOrEqualTo(80));
          // And fully on screen: a button half off the edge is a button a
          // five-year-old's thumb slides off.
          expect(rect.left, greaterThanOrEqualTo(-0.5));
          expect(rect.right, lessThanOrEqualTo(size.width + 0.5));
          expect(rect.top, greaterThanOrEqualTo(-0.5));
          expect(rect.bottom, lessThanOrEqualTo(size.height + 0.5));
        }

        final home = tester.getRect(find.byType(HomeButton));
        expect(home.width, greaterThanOrEqualTo(80));
        expect(home.height, greaterThanOrEqualTo(80));
        expect(home.right, lessThanOrEqualTo(size.width + 0.5));
        expect(home.top, greaterThanOrEqualTo(-0.5));
      });

      testWidgets('the two buttons are in opposite bottom corners', (
        tester,
      ) async {
        await _pump(tester, size);

        final rects = find
            .byType(QuackyButton)
            .evaluate()
            .map((e) => tester.getRect(find.byWidget(e.widget)))
            .toList()
          ..sort((a, b) => a.left.compareTo(b.left));

        expect(rects.length, 2);
        final (duck, dash) = (rects.first, rects.last);
        expect(duck.center.dx, lessThan(size.width * 0.5));
        expect(dash.center.dx, greaterThan(size.width * 0.5));
        expect(duck.center.dy, greaterThan(size.height * 0.5));
        expect(dash.center.dy, greaterThan(size.height * 0.5));
        // They must not be able to be hit together by one hand.
        expect(
          dash.left - duck.right,
          greaterThan(size.width * 0.3),
          reason: 'the two buttons need the width of the screen between them',
        );
      });

      testWidgets('the home button cannot be hit while playing', (
        tester,
      ) async {
        await _pump(tester, size);

        final home = tester.getRect(find.byType(HomeButton));
        for (final element in find.byType(QuackyButton).evaluate()) {
          final button = tester.getRect(find.byWidget(element.widget));
          expect(
            home.overlaps(button),
            isFalse,
            reason: 'leaving the game mid-dash by accident would be miserable',
          );
        }
        // And it is in the top half, clear of both play quarters.
        expect(home.bottom, lessThan(size.height * 0.5));
      });

      testWidgets('a press anywhere in a bottom corner works', (tester) async {
        await _pump(tester, size);
        final state = tester.state(find.byType(QuackyTheDuckScreen));
        final game = (state as dynamic).gameForTest as dynamic;

        // The far corners — the least likely place a child aims, and the most
        // likely place a resting thumb lands.
        await tester.tapAt(Offset(size.width * 0.04, size.height * 0.96));
        await tester.pump(const Duration(milliseconds: 16));
        expect(game.quacky.isDucking, isTrue);

        await tester.tapAt(Offset(size.width * 0.96, size.height * 0.96));
        await tester.pump(const Duration(milliseconds: 16));
        expect(game.quacky.dashPower, greaterThan(0.0));
      });
    });
  }
}
