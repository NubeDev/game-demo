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

      // One playable game plus two "coming soon" placeholders.
      expect(find.byType(GameTile), findsNWidgets(3));

      // The player cannot read: nothing on the menu may render text
      // (CLAUDE.md §3). The settings cog is an icon, not a label.
      expect(find.byType(Text), findsNothing);
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
      await tester.pump(ParentalGate.holdDuration + const Duration(milliseconds: 100));
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
