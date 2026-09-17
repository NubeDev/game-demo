import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/games/balloon_pop/components/balloon.dart';
import 'package:little_games/shared/celebration.dart';
import 'package:little_games/games/balloon_pop/components/progress_stars.dart';

void main() {
  group('Balloon', () {
    testWithFlameGame('floats upward', (game) async {
      final balloon = Balloon(
        color: Colors.red,
        riseSpeed: 50,
        radius: 40,
        position: Vector2(100, 400),
        onPopped: (_) {},
      );
      await game.ensureAdd(balloon);

      game.update(1.0);
      // One second at 50px/s: y decreases (up is negative in Flame).
      expect(balloon.position.y, closeTo(350, 1));
    });

    testWithFlameGame('reports a pop exactly once, even when mashed', (
      game,
    ) async {
      var pops = 0;
      final balloon = Balloon(
        color: Colors.red,
        riseSpeed: 50,
        radius: 40,
        position: Vector2(100, 400),
        onPopped: (_) => pops++,
      );
      await game.ensureAdd(balloon);

      balloon.pop();
      balloon.pop();
      balloon.pop();

      // A child mashing the same balloon must not count it three times.
      expect(pops, 1);
    });

    testWithFlameGame('has a touch target larger than the drawn balloon', (
      game,
    ) async {
      const radius = 46.0;
      final balloon = Balloon(
        color: Colors.red,
        riseSpeed: 50,
        radius: radius,
        position: Vector2(100, 400),
        onPopped: (_) {},
      );
      await game.ensureAdd(balloon);

      // Forgiving aim: the tappable area exceeds the visible balloon, and
      // comfortably clears the 80x80 minimum (CLAUDE.md §3).
      expect(balloon.size.x, greaterThan(radius * 2));
      expect(balloon.size.x, greaterThanOrEqualTo(80));
      expect(balloon.size.y, greaterThanOrEqualTo(80));
    });
  });

  group('ProgressStars', () {
    test('never goes below zero or above the total', () {
      final stars = ProgressStars(total: 10);

      // There is no way to lose progress: even an explicit negative clamps to
      // empty rather than wrapping or throwing (CLAUDE.md §3).
      stars.filled = -5;
      expect(stars.filled, 0);

      stars.filled = 99;
      expect(stars.filled, 10);

      stars.filled = 4;
      expect(stars.filled, 4);
    });
  });

  group('Celebration', () {
    testWithFlameGame('burst adds confetti, and it clears itself up', (
      game,
    ) async {
      final celebration = Celebration(pieceCount: 20);
      await game.ensureAdd(celebration);

      celebration.burst(Vector2(800, 600));
      await game.ready();
      expect(celebration.children.length, 20);

      // Pieces fade out and remove themselves, so repeated celebrations can
      // never accumulate and slow the game down.
      for (var i = 0; i < 400; i++) {
        game.update(0.016);
      }
      await game.ready();
      expect(celebration.children.length, 0);
    });
  });
}
