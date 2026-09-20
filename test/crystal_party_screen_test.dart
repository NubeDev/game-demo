import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/crystal_party/crystal_party_screen.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:provider/provider.dart';

/// Drives a real hold through the real widget tree.
///
/// The unit tests drive [Unicorn] directly, which proves the flight model but
/// NOT that a thumb on the screen reaches it. That gap is exactly where this
/// game's control could silently break: `onTapDown` alone does not fire until
/// a press resolves, so a hold implemented with taps alone would not lift her
/// until the child let go — and everything below the widget layer would still
/// pass. This file is the only thing that would catch that.
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

void main() {
  testWidgets('holding the screen lifts her, and letting go brings her down', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const CrystalPartyScreen()));
    await tester.pump();
    // Let the game load.
    await tester.pump(const Duration(milliseconds: 100));

    final screen = tester.getSize(find.byType(CrystalPartyScreen));
    // Press low and central, where a five-year-old's thumb actually lands —
    // and well inside the play area rather than in the home button's band.
    final thumb = Offset(screen.width * 0.5, screen.height * 0.8);

    final gesture = await tester.startGesture(thumb);
    // Hold. The press must take effect on the way DOWN, not when it resolves.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final state = tester.state(find.byType(CrystalPartyScreen));
    final game = (state as dynamic).gameForTest;
    final high = game.unicorn.airHeight as double;
    expect(
      high,
      greaterThan(50),
      reason: 'a held thumb on the real screen must lift her',
    );

    await gesture.up();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.unicorn.airHeight as double, lessThan(high));
  });

  testWidgets('a press in the home button band does NOT fly her', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const CrystalPartyScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final screen = tester.getSize(find.byType(CrystalPartyScreen));
    // Top-left of the band: not on the home button, but in its row.
    final gesture = await tester.startGesture(
      Offset(screen.width * 0.2, CrystalPartyScreen.topBandHeight / 2),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final state = tester.state(find.byType(CrystalPartyScreen));
    final game = (state as dynamic).gameForTest;
    expect(
      game.unicorn.airHeight as double,
      0,
      reason: 'the top band belongs to the home button, not the control',
    );

    await gesture.up();
  });

  testWidgets('there is no text anywhere a child looks', (tester) async {
    await tester.pumpWidget(_app(const CrystalPartyScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The player cannot read (CLAUDE.md §3). Not a label, not a score, not a
    // crystal count — the progress readouts are the trail and the arch.
    expect(find.byType(Text), findsNothing);
  });
}
