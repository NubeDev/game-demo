import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/neil_the_seal/components/bellow_button.dart';
import 'package:little_games/games/neil_the_seal/neil_the_seal_screen.dart';
import 'package:little_games/games/neil_the_seal/world.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:little_games/shared/home_button.dart';
import 'package:provider/provider.dart';

/// Every screen a child will actually hold. A landscape phone is SHORT, not
/// just narrow — which is what this game's two corner buttons have to survive.
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

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_wrap(const NeilTheSealScreen()));
  // Two frames: the game's onLoad is async, and nothing has a size until the
  // GameWidget has been laid out once.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  for (final (name, size) in _sizes) {
    group(name, () {
      testWidgets('both buttons are there, big, and clear of each other', (
        tester,
      ) async {
        await _pumpAt(tester, size);
        expect(tester.takeException(), isNull);

        final home = tester.getRect(find.byType(HomeButton));
        final bellow = tester.getRect(find.byType(BellowButton));

        // Far past the 80×80 floor (CLAUDE.md §3).
        expect(home.shortestSide, greaterThanOrEqualTo(80));
        expect(bellow.shortestSide, greaterThanOrEqualTo(80));

        // The way out and the noisiest button in the game share a corner of the
        // screen. They must never share a finger.
        expect(
          home.overlaps(bellow),
          isFalse,
          reason: 'the home button and the bellow button overlap at $name',
        );
        expect(bellow.top - home.bottom, greaterThan(24));

        // Both fully on screen.
        for (final rect in [home, bellow]) {
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
        }
      });

      testWidgets('a tap anywhere in the town sends him', (tester) async {
        await _pumpAt(tester, size);
        final game =
            tester.state<State<NeilTheSealScreen>>(
                  find.byType(NeilTheSealScreen),
                )
                as dynamic;
        final world = (game.gameForTest as dynamic).town as NeilWorld;

        expect(world.state, NeilState.flopped);

        // Down at the left-hand end of the town: clear of Neil himself (a
        // touch on him is a rub, not a destination), clear of the bellow
        // button in the bottom right, and clear of the home button.
        await tester.tapAt(Offset(size.width * 0.12, size.height * 0.55));
        await tester.pump();

        expect(
          world.state,
          NeilState.galumphing,
          reason: 'a tap on the town did nothing at $name',
        );
      });

      testWidgets('a touch on Neil himself rubs him instead', (tester) async {
        await _pumpAt(tester, size);
        final game =
            tester.state<State<NeilTheSealScreen>>(
                  find.byType(NeilTheSealScreen),
                )
                as dynamic;
        final neil = (game.gameForTest as dynamic);
        final world = neil.town as NeilWorld;

        // Wherever he actually is on this screen, rather than a guess.
        final at = (neil.view as dynamic).offsetAt(world.neil) as Offset;
        await tester.tapAt(at);
        await tester.pump();

        expect(world.rubbing, greaterThan(0));
        expect(
          world.state,
          NeilState.flopped,
          reason: 'rubbing him sent him somewhere at $name',
        );
      });

      testWidgets('the bellow button bellows and moves nobody', (tester) async {
        await _pumpAt(tester, size);
        final game =
            tester.state<State<NeilTheSealScreen>>(
                  find.byType(NeilTheSealScreen),
                )
                as dynamic;
        final world = (game.gameForTest as dynamic).town as NeilWorld;
        final was = world.neil;

        await tester.tap(find.byType(BellowButton));
        await tester.pump();

        expect(world.bellows, 1);
        // A press on the button must never also send him somewhere — it sits
        // on top of a screen that is otherwise entirely a destination.
        expect(world.state, NeilState.flopped);
        expect(world.neil.x, was.x);
        expect(world.neil.y, was.y);
      });
    });
  }

  testWidgets('the home button is the same one every game uses', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(892, 412));
    expect(find.byType(HomeButton), findsOneWidget);
    // No confirmation, no text, no "are you sure" — a child cannot read one
    // and there is nothing to lose by leaving (CLAUDE.md §3).
    expect(find.byType(Text), findsNothing);
  });
}
