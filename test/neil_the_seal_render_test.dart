@Tags(['render'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/games/neil_the_seal/components/neil_painter.dart';
import 'package:little_games/games/neil_the_seal/components/progress_shells.dart';
import 'package:little_games/games/neil_the_seal/components/town_backdrop.dart';
import 'package:little_games/games/neil_the_seal/components/town_layer.dart';
import 'package:little_games/games/neil_the_seal/town.dart';
import 'package:little_games/games/neil_the_seal/world.dart';

/// Renders Neil, the props and every location to PNGs so they can actually be
/// LOOKED at.
///
/// Not a golden test — nothing is compared. It exists because everything here is
/// drawn in code and `flutter test` cannot tell whether a grey blob reads as a
/// seal, whether a squashed car reads as *bouncy* rather than *wrecked*, or
/// whether a sleeping animal reads as content rather than as ill. Those are the
/// things this game has to get right, and they are only answerable by eye.
///
///     flutter test --tags render --dart-define=SHOT_DIR=/tmp/shots
const _outDir = String.fromEnvironment('SHOT_DIR', defaultValue: '');

Future<void> _shoot(
  String name,
  Size size,
  void Function(Canvas canvas) paint,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEAF8FF));
  paint(canvas);
  final image = await recorder
      .endRecording()
      .toImage(size.width.toInt(), size.height.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  if (_outDir.isEmpty) return;
  final file = File('$_outDir/$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}

const _size = Size(900, 460);
const _view = TownView(width: 900, height: 460);

/// Runs the world on for [seconds] so a shot catches the middle of an
/// animation rather than its first frame.
void _run(NeilWorld world, double seconds) {
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    world.update(1 / 60);
  }
}

/// Fills the shells, then runs [into] seconds into the nap.
void _napUntil(NeilWorld world, double into) {
  for (final prop in [...world.props.where((p) => p.kind.isFloppable)]) {
    world.tapAt(prop.spot);
    for (var t = 0.0; t < 8 && world.state != NeilState.napping; t += 1 / 60) {
      world.update(1 / 60);
    }
    if (world.state == NeilState.napping) break;
  }
  _run(world, into);
}

void main() {
  /// Every state a child will see him in. One that reads as SAD, ill or
  /// frightening in any of these is a bug, not a cosmetic issue — a two-tonne
  /// wild animal is alarming unless every single pose is soft.
  final postures = <String, void Function(NeilWorld world)>{
    'flopped': (_) {},
    'mid-heave': (w) {
      w.tapAt(const TownSpot(0.9, 0.6));
      _run(w, 0.55);
    },
    'landing': (w) {
      w.tapAt(const TownSpot(0.52, 0.58));
      _run(w, 3);
    },
    'being-rubbed': (w) {
      for (var i = 0; i < 20; i++) {
        w.rub();
        w.update(1 / 60);
      }
    },
    'dozing': (w) => _run(w, NeilWorld.idleBeforeSleep + 2),
    // The yawn is a single second at the top of the nap, and it is the beat
    // that telegraphs the snore — so the shot has to stop the moment the nap
    // starts rather than running on past it.
    'yawning': (w) {
      _napUntil(w, 0.55);
    },
    'snoring': (w) {
      _napUntil(w, NeilWorld.snoreAt + 0.4);
    },
  };

  for (final entry in postures.entries) {
    test('Neil: ${entry.key}', () async {
      final world = NeilWorld(place: TownPlace.beach);
      entry.value(world);
      await _shoot('neil-${entry.key}', _size, (canvas) {
        NeilPainter.paint(canvas, _view, world);
      });
    });
  }

  test('Neil close up, and his face on the bellow button', () async {
    await _shoot('neil-face', const Size(320, 240), (canvas) {
      NeilPainter.paintHead(canvas, const Offset(120, 120), 60);
      NeilPainter.paintHead(canvas, const Offset(250, 90), 32, open: 1);
      NeilPainter.paintHead(canvas, const Offset(250, 180), 32, asleep: true);
    });
  });

  /// The props, each at rest, fully squashed, and mid-springback. The
  /// difference between "squashed" and "wrecked" is the whole game, and it is
  /// only settled by looking.
  test('every prop: at rest, squashed, springing back', () async {
    final world = NeilWorld(place: TownPlace.mainStreet);
    for (final kind in PropKind.floppables) {
      await _shoot('prop-${kind.id}', const Size(560, 240), (canvas) {
        for (var i = 0; i < 3; i++) {
          final prop = Prop(kind: kind, spot: const TownSpot(0.5, 0.6));
          if (i == 1) {
            prop.occupied = true;
            for (var t = 0.0; t < 0.5; t += 1 / 60) {
              prop.tick(1 / 60);
            }
          } else if (i == 2) {
            prop.squash = -0.5; // the overshoot: taller than it started
          }
          final layer = TownLayer(world: world)
            ..size = Vector2(560 / 3, 240);
          canvas.save();
          canvas.translate(i * 560 / 3, 0);
          // One prop at a time, centred in its own third of the shot.
          layer.world.props
            ..clear()
            ..add(prop);
          layer.render(canvas);
          canvas.restore();
        }
      });
    }
  });

  /// Every location, whole. This is the shot that answers "does this read as a
  /// small Tasmanian seaside town, or as coloured rectangles?".
  for (final place in TownPlace.values) {
    test('the town: ${place.name}', () async {
      final world = NeilWorld(place: place);
      _run(world, 0.2);

      final backdrop = TownBackdrop(place: place)..size = Vector2(900, 460);
      final layer = TownLayer(world: world)..size = Vector2(900, 460);
      final shells = ProgressShells(position: Vector2(24, 24))
        ..size = Vector2(ProgressShells.widthFor(NeilWorld.dotsPerNap), 30)
        ..filled = 2;

      await _shoot('town-${place.name}', _size, (canvas) {
        backdrop.render(canvas);
        layer.render(canvas);
        canvas.save();
        canvas.translate(24, 24);
        shells.render(canvas);
        canvas.restore();
      });
    });
  }

  test('the nap: the town gathered, the fish, the snore', () async {
    final world = NeilWorld(place: TownPlace.caravanPark);
    _napUntil(world, NeilWorld.snoreAt + 0.6);

    final backdrop = TownBackdrop(place: world.place)..size = Vector2(900, 460);
    final layer = TownLayer(world: world)..size = Vector2(900, 460);
    await _shoot('town-the-nap', _size, (canvas) {
      backdrop.render(canvas);
      layer.render(canvas);
    });
  });

  test('the town mid-squash, with Neil on a car', () async {
    final world = NeilWorld(place: TownPlace.mainStreet);
    final car = world.props.firstWhere((p) => p.kind.id == 'car');
    world.tapAt(car.spot);
    _run(world, 6);

    final backdrop = TownBackdrop(place: world.place)..size = Vector2(900, 460);
    final layer = TownLayer(world: world)..size = Vector2(900, 460);
    await _shoot('town-neil-on-a-car', _size, (canvas) {
      backdrop.render(canvas);
      layer.render(canvas);
    });
  });
}
