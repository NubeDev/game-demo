@Tags(['render'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/games/cat_run/components/cat.dart';
import 'package:little_games/games/cat_run/components/obstacle.dart';
import 'package:little_games/games/cat_run/components/play_buttons.dart';
import 'package:little_games/games/cat_run/obstacles.dart';

/// Renders the placeholder cat, the obstacles and the buttons to PNGs so they
/// can actually be LOOKED at.
///
/// Not a golden test — nothing is compared. It exists because everything here is
/// drawn in code, and `flutter test` cannot tell whether a blob reads as a cat,
/// whether a pancaked cat reads as funny rather than hurt, or whether the
/// crouch button reads as "duck". Those are the things this game has to get
/// right and they are only answerable by eye.
const _outDir = String.fromEnvironment('SHOT_DIR', defaultValue: '');

/// Paints one component, at a size, onto a PNG.
Future<void> _shoot(
  String name,
  Size size,
  void Function(Canvas canvas) paint,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  // A pale backing, so a light-coloured cat is visible at all.
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

/// Each posture the child will see, including all four slapsticks. A cat that
/// reads as HURT in any of these is a bug, not a cosmetic issue.
final _catPostures = <String, void Function(Cat cat)>{
  'running': (_) {},
  'jumping-rising': (cat) => cat.jump(),
  'ducking': (cat) => cat.duck(),
  'idle-sitting': (cat) => cat.sit(),
  'ears-flat': (cat) => cat.earFlatten = 1,
  'miss-tumble': (cat) => cat.bonk(MissStyle.tumble),
  'miss-pancake': (cat) => cat.bonk(MissStyle.pancake),
  'miss-splash': (cat) => cat.bonk(MissStyle.splash),
};

void main() {
  // testWithFlameGame, not a bare FlameGame: a hand-built game never finishes
  // mounting under flutter_test and the render loop hangs forever.
  for (final entry in _catPostures.entries) {
    testWithFlameGame('the cat: ${entry.key}', (game) async {
      final cat = Cat(position: Vector2(70, 130));
      await game.ensureAdd(cat);
      entry.value(cat);
      // Part way into whatever it is doing, so the shot catches the middle of
      // the animation rather than its first frame.
      for (var i = 0; i < 18; i++) {
        game.update(1 / 60);
      }

      await _shoot('cat-${entry.key}', const Size(200, 160), (canvas) {
        canvas.save();
        // These shots are about the POSTURE — the squash, the lean, the face —
        // so the cat is framed wherever it is. The jumping cat renders itself
        // lifted by its air height, which on this small canvas puts it off the
        // top; adding the height back keeps it in shot. The arc itself is the
        // next set of shots down, against a real ground line.
        canvas.translate(
          cat.position.x - cat.size.x / 2,
          cat.position.y - cat.size.y + cat.airHeight,
        );
        cat.render(canvas);
        canvas.restore();
      });
    });
  }

  for (final kind in ObstacleKind.all) {
    testWithFlameGame('the obstacle: ${kind.id}', (game) async {
      final obstacle = Obstacle(kind: kind, position: Vector2(50, 140));
      await game.ensureAdd(obstacle);
      for (var i = 0; i < 10; i++) {
        game.update(1 / 60);
      }

      await _shoot('obstacle-${kind.id}', const Size(200, 160), (canvas) {
        // The ground line too, so it is clear what "on the ground" means and
        // whether a duck obstacle really leaves a gap to fit through.
        canvas.drawRect(
          const Rect.fromLTWH(0, 140, 200, 3),
          Paint()..color = const Color(0xFF9FDF95),
        );
        canvas.save();
        canvas.translate(
          obstacle.position.x,
          obstacle.position.y - obstacle.size.y,
        );
        obstacle.render(canvas);
        canvas.restore();
      });
    });
  }

  // THE JUMP ARC, at the size of a real phone in landscape.
  //
  // Every other shot here is one posture on a blank field, which is exactly how
  // the jump came to be shipped broken: the cat's `airHeight` never reached the
  // canvas, and a single-frame portrait of a squashed cat looks identical
  // whether or not it is ten feet in the air.
  //
  // This one draws the whole arc against the real ground line and the tallest
  // obstacle, so two things are answerable by eye: does the cat visibly LEAVE
  // the ground, and does it stay on the screen at the top of the arc.
  for (final phone in const [
    ('phone', Size(780, 390)), // iPhone-ish, landscape: the tightest headroom
    ('tablet', Size(1024, 768)), // iPad-ish, landscape
  ]) {
    testWithFlameGame('the jump arc: ${phone.$1}', (game) async {
      final size = phone.$2;
      final groundY = size.height * 0.7; // Scenery.groundFraction = 0.3
      final cat = Cat(position: Vector2(size.width * 0.28, groundY));
      await game.ensureAdd(cat);
      cat.fitTo(headroom: groundY);

      await _shoot('jump-arc-${phone.$1}', size, (canvas) {
        canvas.drawRect(
          Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
          Paint()..color = const Color(0xFF9FDF95),
        );
        // The tallest thing the cat has to clear, drawn at its hitbox height.
        canvas.drawRect(
          Rect.fromLTWH(
            size.width * 0.55,
            groundY - ObstacleKind.tallestJumpable,
            83,
            ObstacleKind.tallestJumpable,
          ),
          Paint()..color = const Color(0xFFC98B5A),
        );

        // Step the arc and draw every 6th frame, ghosted and nudged along, so
        // the whole jump reads as one shape in a single still.
        cat.jump();
        for (var i = 0; i * (1 / 60) < Cat.jumpDuration; i++) {
          cat.update(1 / 60);
          if (i % 6 != 0) continue;
          canvas.saveLayer(
            Offset.zero & size,
            Paint()..color = const Color(0x77FFFFFF),
          );
          // Where the game puts the cat: feet on the ground line. The cat's own
          // render lifts it by its air height — that lift is what is under test.
          canvas.translate(
            cat.position.x - cat.size.x / 2 + i * 2.4,
            groundY - cat.size.y,
          );
          cat.render(canvas);
          canvas.restore();
        }
      });
    });
  }

  // The buttons are painted directly rather than pumped through a widget
  // tree: a RepaintBoundary.toImage inside testWidgets stalls in this
  // environment, and all that is wanted here is the icon artwork.
  for (final kind in PlayButtonKind.values) {
    test('the button: ${kind.name}', () async {
      // These two icons ARE the instructions — there is no text anywhere in the
      // game. If a child cannot tell which is jump and which is duck, it does
      // not work at all.
      await _shoot('button-${kind.name}', const Size(140, 140), (canvas) {
        canvas.drawCircle(
          const Offset(70, 70),
          67,
          Paint()..color = const Color(0xFFB7E4C7),
        );
        buttonIconPainter(kind).paint(canvas, const Size(140, 140));
      });
    });
  }
}
