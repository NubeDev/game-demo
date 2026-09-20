import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/menu/game_tile.dart';
import 'package:little_games/menu/home_screen.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/shared/home_button.dart';
import 'package:little_games/shared/parental_gate.dart';
import 'package:provider/provider.dart';

/// Wraps a screen in the providers it needs, with in-memory persistence so
/// tests never touch shared_preferences.
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

void main() {
  group('home screen', () {
    testWidgets('shows a picture button per game and no child-facing text', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));

      // A tile per game. Deliberately not pinned to a number: games get added,
      // and a count here would fail every time one does without telling anyone
      // anything useful. What matters is that there ARE tiles and that none of
      // them is a dead end.
      final tiles = find.byType(GameTile);
      expect(tiles, findsWidgets);
      for (final element in tiles.evaluate()) {
        // Nothing on the menu may be a "coming soon" placeholder any more: a
        // child cannot read "not yet", so a tile that does not open a game
        // just reads as the screen being broken (CLAUDE.md §3).
        expect((element.widget as GameTile).comingSoon, isFalse);
      }

      // The player cannot read: nothing on the menu may render text
      // (CLAUDE.md §3). The settings cog is an icon, not a label.
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('no two games share a tile colour', (tester) async {
      // A child who cannot read picks their game by COLOUR AND SHAPE alone
      // (CLAUDE.md §3), so two identically-coloured tiles are two games they
      // cannot tell apart. Found by looking at the menu with seven games on
      // it: the seventh and the rocket were both orange, and adjacent.
      await tester.pumpWidget(_wrap(const HomeScreen()));

      final colours = <Color>[];
      final icons = <IconData>[];
      for (final element in find.byType(GameTile).evaluate()) {
        final tile = element.widget as GameTile;
        colours.add(tile.color);
        icons.add(tile.icon);
      }

      expect(colours.length, greaterThan(1));
      expect(
        colours.toSet().length,
        colours.length,
        reason: 'two games are the same colour',
      );
      expect(
        icons.toSet().length,
        icons.length,
        reason: 'two games have the same picture',
      );
    });

    testWidgets('game tiles are far bigger than the 80x80 minimum', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));

      final tile = tester.getSize(find.byType(GameTile).first);
      expect(tile.width, greaterThanOrEqualTo(80));
      expect(tile.height, greaterThanOrEqualTo(80));
    });
  });

  group('parental gate', () {
    testWidgets('settings are unreachable without completing the hold', (
      tester,
    ) async {
      var passed = false;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  ParentalGate.guard(context, onPass: () => passed = true),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The gate is shown, and it is text — deliberately, because the text is
      // the barrier (CLAUDE.md §4).
      expect(find.text('Grown-ups only'), findsOneWidget);

      // A quick tap, like a child would make, does not open anything.
      await tester.tap(find.byIcon(Icons.lock_outline_rounded));
      await tester.pumpAndSettle();
      expect(passed, isFalse);
    });

    testWidgets('a full 3-second hold opens it', (tester) async {
      var passed = false;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  ParentalGate.guard(context, onPass: () => passed = true),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Press and hold for the full duration without lifting.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.lock_outline_rounded)),
      );
      await tester.pump();
      await tester.pump(
        ParentalGate.holdDuration + const Duration(milliseconds: 100),
      );
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(passed, isTrue);
    });
  });

  group('home button', () {
    testWidgets('is at least 80x80', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: HomeButton())));

      final size = tester.getSize(find.byType(HomeButton));
      expect(size.width, greaterThanOrEqualTo(80));
      expect(size.height, greaterThanOrEqualTo(80));
    });
  });
}
