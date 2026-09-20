import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/quacky_the_duck/components/play_buttons.dart';
import 'package:little_games/games/quacky_the_duck/components/quacky.dart';
import 'package:little_games/games/quacky_the_duck/quacky_the_duck_screen.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:little_games/shared/home_button.dart';
import 'package:provider/provider.dart';

/// Drives real presses through the real widget tree.
///
/// The unit tests drive [Quacky] and the game directly, which proves the
/// chase and the skid but NOT that a thumb on the screen reaches them. That
/// gap is exactly where this game's controls could silently break — and Car
/// Trip's device run proved the point by finding a hit test that the whole
/// test suite had missed.
Widget _app(Widget child) {
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

Future<void> _load(WidgetTester tester) async {
  await tester.pumpWidget(_app(const QuackyTheDuckScreen()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('a thumb anywhere in the bottom-right dashes', (tester) async {
    await _load(tester);

    final screen = tester.getSize(find.byType(QuackyTheDuckScreen));
    final state = tester.state(find.byType(QuackyTheDuckScreen));
    final game = (state as dynamic).gameForTest as dynamic;

    // Deliberately NOT on the drawn button: a five-year-old mid-chase does not
    // look at their thumb, so the whole bottom-right quarter has to work.
    await tester.tapAt(Offset(screen.width * 0.72, screen.height * 0.66));
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      game.quacky.dashPower,
      greaterThan(0.0),
      reason: 'anywhere in the bottom-right quarter must dash, not just the '
          'circle drawn inside it',
    );
  });

  testWidgets('a thumb anywhere in the bottom-left ducks', (tester) async {
    await _load(tester);

    final screen = tester.getSize(find.byType(QuackyTheDuckScreen));
    final state = tester.state(find.byType(QuackyTheDuckScreen));
    final game = (state as dynamic).gameForTest as dynamic;

    await tester.tapAt(Offset(screen.width * 0.14, screen.height * 0.62));
    await tester.pump(const Duration(milliseconds: 16));

    expect(game.quacky.isDucking, isTrue);
  });

  testWidgets('the press lands on the way DOWN, not when it resolves', (
    tester,
  ) async {
    await _load(tester);

    final screen = tester.getSize(find.byType(QuackyTheDuckScreen));
    final state = tester.state(find.byType(QuackyTheDuckScreen));
    final game = (state as dynamic).gameForTest as dynamic;

    // A finger held down and NOT lifted. If the control waited for the press to
    // resolve, this would still be doing nothing — and in a timing game that
    // makes every press late (CLAUDE.md §3).
    final gesture = await tester.startGesture(
      Offset(screen.width * 0.8, screen.height * 0.8),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      game.quacky.dashPower,
      greaterThan(0.0),
      reason: 'a button that waits for the finger to lift feels broken to a '
          'child, and would make every press late',
    );
    await gesture.up();
  });

  testWidgets('both play buttons clear the 80x80 touch-target floor', (
    tester,
  ) async {
    await _load(tester);

    final buttons = find.byType(QuackyButton);
    expect(buttons, findsNWidgets(2));

    for (final element in buttons.evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget));
      // The kid rule, in a test: below this a five-year-old's finger covers
      // the target and misses it (CLAUDE.md §3).
      expect(size.width, greaterThanOrEqualTo(80));
      expect(size.height, greaterThanOrEqualTo(80));
    }
  });

  testWidgets('the home button is present, big, and far from both buttons', (
    tester,
  ) async {
    await _load(tester);

    expect(find.byType(HomeButton), findsOneWidget);
    final home = tester.getRect(find.byType(HomeButton));
    expect(home.width, greaterThanOrEqualTo(80));
    expect(home.height, greaterThanOrEqualTo(80));

    // It must not sit inside either play quarter, or a child leaving the game
    // would dash, and a child dashing would leave the game.
    final screen = tester.getSize(find.byType(QuackyTheDuckScreen));
    expect(
      home.bottom,
      lessThan(screen.height * 0.5),
      reason: 'the home button belongs in the top half, clear of both thumbs',
    );
  });

  testWidgets('there is no readable text anywhere on the screen', (
    tester,
  ) async {
    await _load(tester);

    // The player cannot read (CLAUDE.md §3). Semantics labels are fine — they
    // are for a parent's accessibility tooling and are never drawn.
    final texts = find.byType(Text).evaluate();
    expect(
      texts.map((e) => (e.widget as Text).data).where((t) => t != null),
      isEmpty,
      reason: 'a five-year-old cannot read a label, so there must not be one',
    );
  });

  testWidgets('both buttons carry a semantics label for a parent', (
    tester,
  ) async {
    await _load(tester);
    expect(find.bySemanticsLabel('Dash'), findsOneWidget);
    expect(find.bySemanticsLabel('Duck'), findsOneWidget);
  });
}
