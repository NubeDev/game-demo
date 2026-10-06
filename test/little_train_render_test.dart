@Tags(['render'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/little_train/little_train_game.dart';
import 'package:little_games/games/little_train/ride.dart';
import 'package:little_games/shared/kid_sounds.dart';

/// Drives the REAL game through a whole ride and saves frames as PNGs, so the
/// generated art can be looked at in place: does the train sit on the rails,
/// do riders show over the wagon side, does a leap read as climbing in, is
/// anything cut off on a 4:3 tablet or a long phone.
///
/// Not a golden test — nothing is compared. Generated art is exactly the kind
/// of thing a green suite says nothing about.
///
/// Run with: `flutter test --tags render \
///   --dart-define=SHOT_DIR=/tmp/train-shots test/little_train_render_test.dart`
const _outDir = String.fromEnvironment('SHOT_DIR', defaultValue: '');

const _dt = 1 / 60;

LittleTrainGame _create() => LittleTrainGame(sounds: KidSounds(_SilentAudio()));

/// Never reaches the audio plugin, which a headless test does not have.
class _SilentAudio implements AudioController {
  @override
  void noSuchMethod(Invocation invocation) {}
}

Future<void> _shoot(LittleTrainGame game, String name) async {
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

void _step(LittleTrainGame game, double seconds) {
  for (var t = 0.0; t < seconds; t += _dt) {
    game.update(_dt);
  }
}

void _until(LittleTrainGame game, bool Function() done, {double limit = 90}) {
  for (var t = 0.0; t < limit; t += _dt) {
    if (done()) return;
    game.update(_dt);
  }
  fail('never happened');
}

Future<void> _sized(LittleTrainGame game, double w, double h) async {
  game.onGameResize(Vector2(w, h));
  game.update(0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWithGame('a whole ride, 16:9', _create, (game) async {
    await _sized(game, 1280, 720);
    final ride = game.ride;
    _step(game, 1.2);
    await _shoot(game, '01-start');

    final first = ride.passengers[0];
    _until(game, () => first.stopX - ride.trainX < ride.viewAhead * 0.6);
    await _shoot(game, '02-next-stop');

    _until(game, () => ride.doorX(0) + Ride.brakeDistance >= first.stopX);
    game.tap();
    _until(game, () => first.state == PassengerState.boarding && first.t > 0.45);
    await _shoot(game, '03-perfect-leap');
    _until(game, () => first.state == PassengerState.riding);
    _step(game, 0.4);
    await _shoot(game, '04-one-aboard');

    final second = ride.passengers[1];
    _until(game, () => second.state == PassengerState.chasing);
    _step(game, 0.35);
    await _shoot(game, '05-wait-for-me');

    _until(game, () => ride.wagonsFilled == 3);
    _step(game, 0.5);
    await _shoot(game, '06-full-train');

    _until(game, () => ride.phase == TrainPhase.arrived);
    _step(game, 0.7);
    await _shoot(game, '07-we-are-here');
    _step(game, 1.9);
    await _shoot(game, '08-bye-bye');
    _step(game, 2.2);
    await _shoot(game, '09-veil');

    for (final land in ['forest', 'seaside', 'snow']) {
      _until(game, () => ride.land.name == land);
      final p = ride.passengers[0];
      _until(game, () => p.stopX - ride.trainX < ride.viewAhead * 0.5);
      await _shoot(game, '10-$land');
    }
  });

  testWithGame('a 4:3 tablet', _create, (game) async {
    await _sized(game, 1024, 768);
    final ride = game.ride;
    _until(game, () => ride.passengers[0].stopX - ride.trainX < ride.viewAhead * 0.6);
    await _shoot(game, '20-tablet');
  });

  testWithGame('a long phone', _create, (game) async {
    await _sized(game, 844, 390);
    final ride = game.ride;
    _until(game, () => ride.passengers[0].stopX - ride.trainX < ride.viewAhead * 0.6);
    await _shoot(game, '21-phone');
  });
}
