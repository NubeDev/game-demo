import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/surfs_up/surf.dart';
import 'package:little_games/games/surfs_up/surfs_up_game.dart';
import 'package:little_games/games/surfs_up/surfs_up_screen.dart';
import 'package:little_games/player_progress/persistence/memory_player_progress_persistence.dart';
import 'package:little_games/player_progress/player_progress.dart';
import 'package:little_games/settings/persistence/memory_settings_persistence.dart';
import 'package:little_games/settings/settings.dart';
import 'package:little_games/shared/home_button.dart';
import 'package:provider/provider.dart';

/// Drives real taps through the real widget tree. The model tests prove the
/// sea; these prove a thumb reaches it.
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

class _SilentAudio implements AudioController {
  @override
  void noSuchMethod(Invocation invocation) {}
}

Future<SurfsUpGame> _load(WidgetTester tester, Size screen) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(const SurfsUpScreen()));
  final state = tester.state(find.byType(SurfsUpScreen));
  final game = (state as dynamic).gameForTest as SurfsUpGame;
  // Rasterising the SVG cast is real async work.
  await tester.runAsync(() => game.loaded);
  await tester.pump(const Duration(milliseconds: 100));
  return game;
}

/// Pumps frames until [done], or fails.
Future<void> _until(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 60 * 30; i++) {
    if (done()) return;
    await tester.pump(const Duration(milliseconds: 16));
  }
  fail('never got there');
}

const _screens = {
  'tablet': Size(1024, 768),
  '16:9': Size(1280, 720),
  'small phone': Size(667, 375),
};

void main() {
  for (final MapEntry(key: name, value: size) in _screens.entries) {
    group(name, () {
      testWidgets('a tap anywhere in the play area catches the wave', (
        tester,
      ) async {
        final game = await _load(tester, size);
        await _until(tester, () => game.surf.inCatchWindow);
        // Bottom-left — nowhere near Koko. There is nothing to aim at.
        await tester.tapAt(Offset(size.width * 0.1, size.height * 0.9));
        await tester.pump(const Duration(milliseconds: 16));
        expect(game.surf.phase, SurfPhase.poppingUp);
      });

      testWidgets('a tap in the home button band does not', (tester) async {
        final game = await _load(tester, size);
        await _until(tester, () => game.surf.inCatchWindow);
        await tester.tapAt(Offset(size.width * 0.3, 40));
        await tester.pump(const Duration(milliseconds: 16));
        expect(game.surf.phase, SurfPhase.paddling);
      });

      testWidgets('the home button is big enough', (tester) async {
        await _load(tester, size);
        final box = tester.getSize(find.byType(HomeButton));
        expect(box.width, greaterThanOrEqualTo(80));
        expect(box.height, greaterThanOrEqualTo(80));
      });
    });
  }
}
