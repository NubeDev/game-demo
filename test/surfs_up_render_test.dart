@Tags(['render'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/surfs_up/surf.dart';
import 'package:little_games/games/surfs_up/surfs_up_game.dart';
import 'package:little_games/shared/kid_sounds.dart';

/// Drives the REAL game through a whole trip and saves frames as PNGs, so the
/// art can be looked at in place: does Koko stand on her board, does the
/// board sit on the wave, do the friends stand on the sand, is anything cut
/// off on a 4:3 tablet or a long phone.
///
/// Not a golden test — nothing is compared.
///
/// Run with: `flutter test --tags render \
///   --dart-define=SHOT_DIR=/tmp/surf-shots test/surfs_up_render_test.dart`
const _outDir = String.fromEnvironment('SHOT_DIR', defaultValue: '');

const _dt = 1 / 60;

SurfsUpGame _create() => SurfsUpGame(sounds: KidSounds(_SilentAudio()));

class _SilentAudio implements AudioController {
  @override
  void noSuchMethod(Invocation invocation) {}
}

Future<void> _shoot(SurfsUpGame game, String name) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  game.render(canvas);
  final image = await recorder.endRecording().toImage(
    game.size.x.toInt(),
    game.size.y.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (_outDir.isEmpty) return;
  final file = File('$_outDir/$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}

void _step(SurfsUpGame game, double seconds) {
  for (var t = 0.0; t < seconds; t += _dt) {
    game.update(_dt);
  }
}

void _until(SurfsUpGame game, bool Function() done, {double limit = 90}) {
  for (var t = 0.0; t < limit; t += _dt) {
    if (done()) return;
    game.update(_dt);
  }
  fail('never happened');
}

Future<void> _sized(SurfsUpGame game, double w, double h) async {
  game.onGameResize(Vector2(w, h));
  game.update(0);
}

/// Waits for the next catchable swell and taps.
void _catch(SurfsUpGame game) {
  _until(game, () => game.surf.inCatchWindow);
  _step(game, 0.3);
  game.tap();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWithGame('a whole trip, 16:9', _create, (game) async {
    await _sized(game, 1280, 720);
    final surf = game.surf;
    _step(game, 0.5);
    await _shoot(game, '01-sitting');
    _until(game, () => surf.incoming != null && surf.incoming!.x - surf.kokoX > -0.6);
    await _shoot(game, '02-swell-coming');
    _catch(game);
    _step(game, 0.2);
    await _shoot(game, '03-pop-up');
    _until(game, () => surf.phase == SurfPhase.riding);
    _step(game, 0.4);
    await _shoot(game, '04-riding');
    final high = surf.shells.firstWhere((s) => s.high);
    _until(game, () => surf.kokoX >= high.x - 0.8);
    await _shoot(game, '04b-high-shell-ahead');
    _until(game, () => surf.kokoX >= high.x - Surf.rideSpeed * Surf.hopTime / 2);
    game.tap();
    _step(game, Surf.hopTime / 2);
    await _shoot(game, '05-hop-for-shell');
    _until(game, () => surf.phase == SurfPhase.settling);
    _step(game, 0.3);
    await _shoot(game, '06-wave-done');
    _catch(game);
    _until(game, () => surf.phase == SurfPhase.settling);
    _catch(game);
    _until(game, () => surf.phase == SurfPhase.riding && surf.phaseTime > 5.3);
    await _shoot(game, '07-beach-ahead');
    _until(game, () => surf.phase == SurfPhase.arriving && surf.phaseTime > 0.4);
    await _shoot(game, '07b-gliding-in');
    _until(game, () => surf.phase == SurfPhase.party);
    _step(game, 0.6);
    await _shoot(game, '08-party');
    _until(game, () => surf.trip == 1);
    _step(game, 1.0);
    await _shoot(game, '09-midday');
    _until(game, () => surf.trip == 2);
    _until(game, () => surf.phase == SurfPhase.riding && surf.wavesCaught == 2);
    _step(game, 5.5);
    await _shoot(game, '10-sunset-beach');
    _until(game, () => surf.phase == SurfPhase.party);
    _step(game, 1.0);
    await _shoot(game, '11-sunset-party');
  });

  testWithGame('a 4:3 tablet', _create, (game) async {
    await _sized(game, 1024, 768);
    _catch(game);
    _until(game, () => game.surf.phase == SurfPhase.riding);
    _step(game, 1);
    await _shoot(game, '20-tablet-riding');
    _until(game, () => game.surf.phase == SurfPhase.party);
    _step(game, 0.5);
    await _shoot(game, '21-tablet-party');
  });

  testWithGame('a long phone', _create, (game) async {
    await _sized(game, 844, 390);
    _catch(game);
    _until(game, () => game.surf.phase == SurfPhase.riding);
    _step(game, 1);
    await _shoot(game, '22-phone-riding');
    _until(game, () => game.surf.phase == SurfPhase.party);
    _step(game, 0.5);
    await _shoot(game, '23-phone-party');
  });
}
