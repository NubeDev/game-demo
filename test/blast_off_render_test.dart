@Tags(['render'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/games/blast_off/blast_off_screen.dart';
import 'package:little_games/games/blast_off/components/launch_pad.dart';
import 'package:little_games/games/blast_off/components/rocket.dart';
import 'package:little_games/games/blast_off/countdown.dart';

/// Renders the rocket at every length on the ladder, so the size ladder can be
/// LOOKED at.
///
/// Not a golden test — nothing is compared. `blast_off_rocket_size_test.dart`
/// asserts the numbers (each rung bigger than the last, never under 80px wide,
/// never off the top). What no assertion can answer is the only question that
/// matters here: does a child SEE that this rocket is the big one? That is a
/// judgement about a picture, so this produces the picture.
const _outDir = String.fromEnvironment('SHOT_DIR', defaultValue: '');

const _screens = <(String, Size)>[
  ('tablet', Size(1280, 800)),
  ('pixel', Size(892, 412)),
  ('iphone-se', Size(667, 375)),
];

void main() {
  // testWithFlameGame, not a bare FlameGame or a GameWidget: a hand-built game
  // never finishes mounting under flutter_test and the render loop hangs
  // forever (the same trap cat_run_render_test.dart documents).
  for (final (name, screen) in _screens) {
    testWithFlameGame('the size ladder: $name', (game) async {
      final size = Vector2(screen.width, screen.height);
      final pad = LaunchPad(countdown: Countdown(), size: size)
        ..bottomInset = BlastOffScreen.controlsReserve(screen.width);
      await game.ensureAdd(pad);

      // One rocket per rung, settled at the size that rung asks for.
      final rockets = <Rocket>[];
      for (final length in CountdownLength.values) {
        final rocket = Rocket(
          countdown: Countdown(length: length),
          position: Vector2.zero(),
        )..fitTo(skyScale: pad.maxSceneScale);
        await game.ensureAdd(rocket);
        rockets.add(rocket);
      }
      // Two seconds, so the spring has arrived and stopped.
      for (var i = 0; i < 120; i++) {
        game.update(1 / 60);
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      pad.render(canvas);

      // The whole ladder in one still, standing on the real ground line: five
      // seconds on the left, ten minutes on the right.
      final step = screen.width / (rockets.length + 1);
      for (var i = 0; i < rockets.length; i++) {
        final rocket = rockets[i];
        final scale = rocket.scale.x;
        canvas.save();
        canvas.translate(
          step * (i + 1) - rocket.size.x * scale / 2,
          pad.padTop - rocket.size.y * scale,
        );
        canvas.scale(scale);
        rocket.render(canvas);
        canvas.restore();
      }

      if (_outDir.isEmpty) return;
      final image = await recorder.endRecording().toImage(
        screen.width.toInt(),
        screen.height.toInt(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_outDir/rocket-ladder-$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }
}
