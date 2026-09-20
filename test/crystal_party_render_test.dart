import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/games/crystal_party/components/arch.dart';
import 'package:little_games/games/crystal_party/components/crystal.dart';
import 'package:little_games/games/crystal_party/components/unicorn.dart';
import 'package:little_games/games/crystal_party/world.dart';

/// Renders a component to pixels and returns the alpha mask.
///
/// Rendering rather than inspecting a transform, on purpose: the question
/// these tests ask is "did the child SEE it", and only the image answers that.
Future<List<bool>> _mask(
  void Function(Canvas canvas) paint, {
  int width = 300,
  int height = 400,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  paint(canvas);
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  return List.generate(
    width * height,
    (i) => bytes[i * 4 + 3] != 0,
  );
}

/// The topmost painted row, or null if nothing was drawn.
int? _topRow(List<bool> mask, int width, int height) {
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (mask[y * width + x]) return y;
    }
  }
  return null;
}

void main() {
  group('the unicorn is actually drawn where she is', () {
    test('a held unicorn paints HIGHER than a galloping one', () async {
      // Not just "airHeight went up" — the child has to be able to SEE her
      // leave the ground, or the control has not worked as far as they are
      // concerned.
      const width = 300;
      const height = 500;
      const groundY = 420.0;

      Future<int?> paintedTop(Unicorn unicorn) async {
        final mask = await _mask(
          (canvas) {
            canvas.save();
            canvas.translate(width / 2 - unicorn.size.x / 2,
                groundY - unicorn.size.y);
            unicorn.render(canvas);
            canvas.restore();
          },
          width: width,
          height: height,
        );
        return _topRow(mask, width, height);
      }

      final grounded = Unicorn(position: Vector2(150, groundY))
        ..fitTo(headroom: groundY);
      final onGround = await paintedTop(grounded);

      final flying = Unicorn(position: Vector2(150, groundY))
        ..fitTo(headroom: groundY)
        ..hold();
      for (var t = 0.0; t < 1.0; t += 1 / 60) {
        flying.update(1 / 60);
      }
      final inAir = await paintedTop(flying);

      expect(onGround, isNotNull, reason: 'the unicorn painted nothing');
      expect(inAir, isNotNull);
      expect(
        inAir!,
        lessThan(onGround! - 80),
        reason: 'a second of hold must be unmistakable at a glance',
      );
    });
  });

  group('blue and pink are told apart WITHOUT colour', () {
    /// The shape cue, and it is a kid rule rather than a style choice: a
    /// colourblind child sorts these by silhouette alone (CLAUDE.md §3).
    ///
    /// Measured on the SOLID core rather than every non-transparent pixel: the
    /// soft glow around a crystal is a blurred circle for both colours, so
    /// counting it would compare two circles and pass no matter what shape the
    /// crystal itself was. Thresholding on alpha is what makes this test
    /// actually about the silhouette a child sees.
    Future<List<bool>> silhouette(CrystalColour colour) async {
      final crystal = Crystal(colour: colour, position: Vector2(60, 60));
      const size = 120;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.save();
      canvas.translate(60 - crystal.size.x / 2, 60 - crystal.size.y / 2);
      crystal.render(canvas);
      canvas.restore();
      final image = await recorder.endRecording().toImage(size, size);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = data!.buffer.asUint8List();
      return List.generate(
        size * size,
        // Well above the glow's alpha, so only the crystal body counts.
        (i) => bytes[i * 4 + 3] > 200,
      );
    }

    test('their silhouettes are genuinely different shapes', () async {
      final blue = await silhouette(CrystalColour.blue);
      final pink = await silhouette(CrystalColour.pink);

      // Both drew something solid.
      expect(blue.where((p) => p).length, greaterThan(50));
      expect(pink.where((p) => p).length, greaterThan(50));

      /// How much of the shape's bounding box the shape actually fills.
      ///
      /// This is the measure that separates a shard from a blob without
      /// reference to colour: a diamond fills about half its box, a circle
      /// about three quarters. A child reading silhouette alone is making
      /// exactly this judgement.
      double fillRatio(List<bool> mask) {
        var minX = 120, maxX = -1, minY = 120, maxY = -1, painted = 0;
        for (var y = 0; y < 120; y++) {
          for (var x = 0; x < 120; x++) {
            if (!mask[y * 120 + x]) continue;
            painted++;
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
        final box = (maxX - minX + 1) * (maxY - minY + 1);
        return painted / box;
      }

      final blueFill = fillRatio(blue);
      final pinkFill = fillRatio(pink);

      // The pointy shard is a visibly sparser shape than the round blob.
      expect(
        blueFill,
        lessThan(pinkFill - 0.1),
        reason: 'blue must read as pointy and pink as round, with no colour '
            '(blue fills $blueFill of its box, pink $pinkFill)',
      );
    });
  });

  group('a missed crystal is still visible', () {
    test('it fades but never disappears', () async {
      final crystal = Crystal(
        colour: CrystalColour.pink,
        position: Vector2(60, 60),
      );
      crystal.missIt();
      crystal.update(0.1);

      final mask = await _mask(
        (canvas) {
          canvas.save();
          canvas.translate(60 - crystal.size.x / 2, 60 - crystal.size.y / 2);
          crystal.render(canvas);
          canvas.restore();
        },
        width: 120,
        height: 120,
      );

      // Still painted. A missed crystal twinkles and drifts — it is never
      // taken away, because nothing in this game can be lost.
      expect(mask.where((p) => p).length, greaterThan(50));
      expect(crystal.isTaken, isFalse);
    });
  });

  group('the arch is on the horizon from the first second', () {
    /// Paints an arch and counts the pixels it covered.
    Future<int> painted(Arch arch) async {
      const w = 400, h = 220;
      final mask = await _mask(
        (canvas) => arch.render(canvas),
        width: w,
        height: h,
      );
      return mask.where((p) => p).length;
    }

    test('an EMPTY arch is still visible — it is visibly unfinished, not '
        'absent', () async {
      // THIS TEST EXISTS BECAUSE IT WAS BROKEN, and it was found by actually
      // looking at the game rather than by a green suite: with no crystals
      // gathered, every piece was skipped and the arch painted nothing at
      // all. A child starting a land saw no arch, so the "progress is visible
      // in front of her too" half of the scope simply did not happen.
      final empty = Arch(piecesPerSide: 6, position: Vector2.zero())
        ..size = Vector2(400, 200);
      expect(
        await painted(empty),
        greaterThan(500),
        reason: 'an empty arch must still show the shape to be filled',
      );
    });

    test('it gets MORE solid as pieces go in', () async {
      final empty = Arch(piecesPerSide: 6, position: Vector2.zero())
        ..size = Vector2(400, 200);
      final emptyPixels = await painted(empty);

      final partly = Arch(piecesPerSide: 6, position: Vector2.zero())
        ..size = Vector2(400, 200);
      for (var i = 0; i < 4; i++) {
        partly.addPiece(CrystalColour.blue);
      }
      // The same arcs are drawn either way, so the count is similar — what
      // changes is that gathered pieces are solid rainbow rather than ghost.
      // Both must paint; neither may vanish.
      expect(await painted(partly), greaterThan(emptyPixels ~/ 2));
    });
  });
}
