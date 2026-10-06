import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/little_train/little_train_game.dart';
import 'package:little_games/games/little_train/little_train_screen.dart';
import 'package:little_games/games/little_train/ride.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:little_games/shared/home_button.dart';
import 'package:provider/provider.dart';

/// Drives real taps through the real widget tree, on screens the game ships
/// to. The model tests prove the ride; these prove a thumb reaches it.
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
      Provider<AudioController>(create: (_) => _SilentAudio()),
    ],
    child: MaterialApp(home: child),
  );
}

/// The real AudioController preloads through the audio plugin, which a
/// headless test does not have — and `runAsync` below would let it try.
class _SilentAudio implements AudioController {
  @override
  void noSuchMethod(Invocation invocation) {}
}

Future<LittleTrainGame> _load(WidgetTester tester, Size screen) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(const LittleTrainScreen()));
  final state = tester.state(find.byType(LittleTrainScreen));
  final game = (state as dynamic).gameForTest as LittleTrainGame;
  // Decoding the pictures is real async work, which the widget test's fake
  // clock never runs on its own.
  await tester.runAsync(() => game.loaded);
  await tester.pump(const Duration(milliseconds: 100));
  // Roll for a moment so the train is moving.
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return game;
}

const _screens = {
  'tablet': Size(1024, 768),
  '16:9': Size(1280, 720),
  'small phone': Size(667, 375),
};

void main() {
  for (final MapEntry(key: name, value: size) in _screens.entries) {
    group(name, () {
      testWidgets('a tap anywhere in the play area brakes the train', (
        tester,
      ) async {
        final game = await _load(tester, size);
        expect(game.ride.phase, TrainPhase.cruising);
        // Low and to the left — nowhere near the train or a passenger. There
        // is nothing to aim at in this game.
        await tester.tapAt(Offset(size.width * 0.1, size.height * 0.9));
        await tester.pump(const Duration(milliseconds: 16));
        expect(game.ride.phase, TrainPhase.braking);
      });

      testWidgets('a tap in the home button band does not brake', (
        tester,
      ) async {
        final game = await _load(tester, size);
        await tester.tapAt(Offset(size.width * 0.4, 40));
        await tester.pump(const Duration(milliseconds: 16));
        expect(game.ride.phase, TrainPhase.cruising);
      });

      testWidgets('the home button is big and inside its own band', (
        tester,
      ) async {
        await _load(tester, size);
        final home = tester.getRect(find.byType(HomeButton));
        expect(home.width, greaterThanOrEqualTo(80));
        expect(home.height, greaterThanOrEqualTo(80));
        expect(home.bottom, lessThanOrEqualTo(LittleTrainScreen.topBandHeight));
        expect(home.right, lessThanOrEqualTo(size.width));
      });

      testWidgets('the whole train and some line ahead are on screen', (
        tester,
      ) async {
        final game = await _load(tester, size);
        final rear = game.screenX(game.ride.trainX - Ride.trainLength);
        expect(rear, greaterThanOrEqualTo(0), reason: 'last wagon cut off');
        // At least a wagon's length of line ahead, so a passenger is seen
        // before the train is on top of them.
        expect(
          size.width - game.frontX,
          greaterThan(Ride.wagonWidth * game.unit * 1.5),
        );
      });
    });
  }
}
