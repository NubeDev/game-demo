@Tags(['render'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/games/quacky_the_duck/components/chase_target.dart';
import 'package:little_games/games/quacky_the_duck/components/hazard.dart';
import 'package:little_games/games/quacky_the_duck/components/play_buttons.dart';
import 'package:little_games/games/quacky_the_duck/components/quacky.dart';
import 'package:little_games/games/quacky_the_duck/park.dart';

/// Renders the placeholder duck, the chase targets, the hazards and the buttons
/// to PNGs so they can actually be LOOKED at.
///
/// Not a golden test — nothing is compared. It exists because everything here
/// is drawn in code, and `flutter test` cannot tell whether a blob reads as a
/// duck, whether the eyebrows read as *grumpy* rather than *angry*, whether the
/// child up ahead reads as **laughing rather than frightened** — which is the
/// single most important thing about this game's art — or whether the flat-duck
/// button reads as "duck". Those are only answerable by eye.
///
/// Run with: `flutter test --tags render \
///   --dart-define=SHOT_DIR=/tmp/quacky-shots test/quacky_the_duck_render_test.dart`
const _outDir = String.fromEnvironment('SHOT_DIR', defaultValue: '');

/// Paints one component, at a size, onto a PNG.
Future<void> _shoot(
  String name,
  Size size,
  void Function(Canvas canvas) paint,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  // A pale backing, so a pale duck is visible at all.
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEAF8FF));
  paint(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  if (_outDir.isEmpty) return;
  final file = File('$_outDir/$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}

/// Every posture the child will see. A duck that reads as ANGRY rather than
/// comically grumpy in any of these is a bug, not a cosmetic issue.
final _postures = <String, void Function(Quacky q)>{
  'waddling': (_) {},
  'dashing': (q) => q.dash(),
  'ducking': (q) => q.duck(),
  'huffing-after-a-bonk': (q) => q.bonk(),
  'sitting-idle': (q) => q.sit(),
};

void main() {
  // testWithFlameGame, not a bare FlameGame: a hand-built game never finishes
  // mounting under flutter_test and the render loop hangs forever.

  // --- Quacky, in every posture and at both ends of his mood -------------
  for (final entry in _postures.entries) {
    for (final mood in [Mood.furious, Mood.delighted]) {
      testWithFlameGame('quacky: ${entry.key} (${mood.name})', (game) async {
        final quacky = Quacky(position: Vector2(90, 140));
        await game.ensureAdd(quacky);
        quacky.mood = mood;
        entry.value(quacky);
        // Part way in, so the shot catches the middle of the animation rather
        // than its first frame.
        for (var i = 0; i < 18; i++) {
          game.update(1 / 60);
        }

        await _shoot(
          'quacky-${entry.key}-${mood.name}',
          const Size(220, 170),
          (canvas) {
            canvas.save();
            canvas.translate(
              quacky.position.x - quacky.size.x / 2,
              quacky.position.y - quacky.size.y,
            );
            quacky.render(canvas);
            canvas.restore();
          },
        );
      });
    }
  }

  // --- the whole mood ladder, side by side --------------------------------
  //
  // The one shot that answers "can a child see him cheering up?". If the five
  // faces are not obviously different in a row, the progress signal does not
  // work and the bread rolls are carrying the game alone.
  testWithFlameGame('quacky: the whole mood ladder', (game) async {
    final ducks = <Quacky>[];
    for (final mood in Mood.values) {
      final q = Quacky(position: Vector2(90, 140));
      await game.ensureAdd(q);
      q.mood = mood;
      ducks.add(q);
    }
    for (var i = 0; i < 6; i++) {
      game.update(1 / 60);
    }

    await _shoot('quacky-mood-ladder', Size(200.0 * ducks.length, 170), (
      canvas,
    ) {
      for (final (i, q) in ducks.indexed) {
        canvas.save();
        canvas.translate(i * 200.0 + 30, q.position.y - q.size.y);
        q.render(canvas);
        canvas.restore();
      }
    });
  });

  // --- the chase targets --------------------------------------------------
  //
  // THE most important shots in this file. Every one of these must read as
  // delighted. A child who looks frightened here is a bug in the game's
  // premise, not in its art (see the scope's *Kid-rules impact*).
  for (final kind in ChaseKind.values) {
    for (final handingOver in [false, true]) {
      testWithFlameGame(
        'chase target: ${kind.name}${handingOver ? " handing over" : ""}',
        (game) async {
          final target = ChaseTarget(
            kind: kind,
            position: Vector2(110, 175),
          );
          await game.ensureAdd(target);
          target.closeness = handingOver ? 1 : 0.4;
          if (handingOver) target.handOver();
          for (var i = 0; i < 20; i++) {
            game.update(1 / 60);
          }

          await _shoot(
            'target-${kind.name}${handingOver ? "-handover" : ""}',
            const Size(240, 200),
            (canvas) {
              canvas.save();
              canvas.translate(
                target.position.x - target.size.x / 2,
                target.position.y - target.size.y,
              );
              target.render(canvas);
              canvas.restore();
            },
          );
        },
      );
    }
  }

  // --- the hazards --------------------------------------------------------
  for (final kind in HazardKind.all) {
    testWithFlameGame('hazard: ${kind.id}', (game) async {
      final hazard = Hazard(kind: kind, position: Vector2(30, 150));
      await game.ensureAdd(hazard);
      for (var i = 0; i < 6; i++) {
        game.update(1 / 60);
      }

      await _shoot('hazard-${kind.id}', const Size(280, 180), (canvas) {
        canvas.save();
        canvas.translate(hazard.position.x, hazard.position.y - hazard.size.y);
        hazard.render(canvas);
        canvas.restore();
      });
    });
  }

  // --- a duck hazard with a duck under it, at the real clearance ----------
  //
  // The shot that answers "is the gap under a bench obviously a gap?". If the
  // child cannot SEE a way through, the duck button means nothing to them.
  for (final kind in HazardKind.withAction(HazardAction.duck)) {
    testWithFlameGame('clearance: ${kind.id}', (game) async {
      const groundY = 150.0;
      final quacky = Quacky(position: Vector2(120, groundY));
      final hazard = Hazard(
        kind: kind,
        position: Vector2(60, _duckY(kind, groundY)),
      );
      await game.ensureAdd(quacky);
      await game.ensureAdd(hazard);
      quacky.duck();
      for (var i = 0; i < 8; i++) {
        game.update(1 / 60);
      }

      await _shoot('clearance-${kind.id}', const Size(300, 200), (canvas) {
        // The ground line, so the gap is readable.
        canvas.drawRect(
          Rect.fromLTWH(0, groundY, 300, 200 - groundY),
          Paint()..color = const Color(0xFF9FDF95),
        );
        canvas.save();
        canvas.translate(hazard.position.x, hazard.position.y - hazard.size.y);
        hazard.render(canvas);
        canvas.restore();
        canvas.save();
        canvas.translate(
          quacky.position.x - quacky.size.x / 2,
          quacky.position.y - quacky.size.y,
        );
        quacky.render(canvas);
        canvas.restore();
      });
    });
  }

  // --- the two buttons ----------------------------------------------------
  //
  // These ARE the instructions. There is no text to fall back on, so if the
  // leaning duck does not say "go" and the flat duck does not say "get down",
  // the game has no controls a child can discover.
  for (final kind in QuackyButtonKind.values) {
    test('button: ${kind.name}', () async {
      await _shoot('button-${kind.name}', const Size(140, 140), (canvas) {
        canvas.drawCircle(
          const Offset(70, 70),
          70,
          Paint()..color = const Color(0xFFFFB03A),
        );
        quackyButtonIconPainter(kind).paint(canvas, const Size(140, 140));
      });
    });
  }
}

/// Mirrors `QuackyTheDuckGame.duckHazardYFor`, which is the real placement.
double _duckY(HazardKind kind, double groundY) {
  const clearance = 18.0;
  final bottom = groundY - Quacky.duckedHeight - clearance;
  return bottom + (kind.size.height - kind.hitBox.height);
}
