import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/games/balloon_pop/components/balloon.dart';
import 'package:little_games/games/balloon_pop/components/pop_burst.dart';
import 'package:little_games/shared/kid_sounds.dart';
import 'package:little_games/shared/celebration.dart';
import 'package:little_games/games/balloon_pop/components/progress_stars.dart';
import 'package:little_games/games/balloon_pop/balloon_pop_game.dart';

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

    test('even the smallest balloon the game spawns clears 80x80', () {
      // Balloons come in three sizes. The variety is for the child's benefit —
      // a big slow one is an easy target — but it must never shrink the touch
      // target below the floor (CLAUDE.md §3).
      expect(BalloonPopGame.smallestTouchTarget, greaterThanOrEqualTo(80));
    });

    testWithFlameGame('a popped balloon leaves a burst that cleans itself up', (
      game,
    ) async {
      final balloon = Balloon(
        color: Colors.red,
        riseSpeed: 50,
        radius: 46,
        position: Vector2(100, 400),
        onPopped: (_) {},
      );
      await game.ensureAdd(balloon);

      balloon.pop();
      await game.ready();
      expect(game.children.query<PopBurst>(), hasLength(1));

      // The burst is what answers the child's tap on screen, but a child pops
      // many balloons a minute — none of it may accumulate.
      for (var i = 0; i < 120; i++) {
        game.update(0.016);
      }
      await game.ready();
      expect(game.children.query<PopBurst>(), isEmpty);
      expect(game.children.query<Balloon>(), isEmpty);
    });

    testWithFlameGame('drifting away is silent, repeatable and final', (
      game,
    ) async {
      var pops = 0;
      final balloon = Balloon(
        color: Colors.red,
        riseSpeed: 50,
        radius: 46,
        position: Vector2(100, 400),
        onPopped: (_) => pops++,
      );
      await game.ensureAdd(balloon);

      // The game's per-frame sweep calls this on every balloon that is off the
      // top, so it has to be idempotent.
      balloon.driftAway();
      balloon.driftAway();
      balloon.driftAway();

      expect(balloon.isSpent, isTrue);
      // A balloon reaching the top is NOT a miss: nothing is reported, so
      // nothing can be counted, scored or subtracted (CLAUDE.md §3).
      expect(pops, 0);

      // It fades out and removes itself rather than lingering forever.
      for (var i = 0; i < 90; i++) {
        game.update(0.016);
      }
      await game.ready();
      expect(game.children.query<Balloon>(), isEmpty);
    });

    testWithFlameGame('a balloon that already left cannot be popped', (
      game,
    ) async {
      var pops = 0;
      final balloon = Balloon(
        color: Colors.red,
        riseSpeed: 50,
        radius: 46,
        position: Vector2(100, 400),
        onPopped: (_) => pops++,
      );
      await game.ensureAdd(balloon);

      balloon.driftAway();
      balloon.pop();

      // A swipe catching a balloon mid-fade must not count it.
      expect(pops, 0);
    });
  });

  group('swipe to pop', () {
    Balloon balloonAt(double x, double y) => Balloon(
      color: Colors.red,
      riseSpeed: 50,
      radius: 46,
      position: Vector2(x, y),
      onPopped: (_) {},
    );

    test('a finger passing near a balloon still pops it', () {
      final balloon = balloonAt(100, 400);
      final edge = balloon.size.x / 2;

      // Dead on.
      expect(
        BalloonPopGame.isWithinDragReach(balloon, Vector2(100, 400)),
        isTrue,
      );
      // Just outside the touch target: a swipe samples only a few points a
      // second, so this has to count or a fast sweep appears to pass straight
      // through the balloon.
      expect(
        BalloonPopGame.isWithinDragReach(
          balloon,
          Vector2(100 + edge + BalloonPopGame.dragReach - 1, 400),
        ),
        isTrue,
      );
    });

    test('a finger nowhere near a balloon does not pop it', () {
      final balloon = balloonAt(100, 400);
      // Otherwise a single swipe would clear the whole screen, and popping
      // would stop meaning anything.
      expect(
        BalloonPopGame.isWithinDragReach(balloon, Vector2(400, 400)),
        isFalse,
      );
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

    test('a reset row is empty, not mid-animation', () {
      final stars = ProgressStars(total: 10);

      stars.filled = 10;
      stars.filled = 0;

      // After a celebration the next round starts from a clean empty row. The
      // child never watches progress drain away (CLAUDE.md §3).
      expect(stars.filled, 0);
    });

    test('the row reports its own width, so nothing has to guess', () {
      // The game places the row clear of the home button; if this were wrong
      // the two could overlap and the way out of the game would be blocked.
      expect(ProgressStars.widthFor(10), greaterThan(0));
      expect(
        ProgressStars.widthFor(10),
        greaterThan(ProgressStars.widthFor(5)),
      );
    });
  });

  group('the pop ladder', () {
    test('climbs as the round fills, and never descends', () {
      // The cue rising as the stars fill is how a child who cannot read a
      // progress bar hears "nearly there".
      var previous = -1;
      for (var i = 0; i <= 10; i++) {
        final rung = KidSounds.popRung(i / 10);
        expect(rung, greaterThanOrEqualTo(previous));
        previous = rung;
      }
      expect(KidSounds.popRung(0), 0);
      expect(KidSounds.popRung(1), greaterThan(0));
    });

    test('out-of-range progress still picks a real rung', () {
      // Defensive: a future game with a different set size must not be able to
      // index off the end of the sample list and silence the pop.
      expect(KidSounds.popRung(-1), 0);
      expect(KidSounds.popRung(5), KidSounds.popRung(1));
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

  group('empty-sky taps', () {
    // BalloonPopGame.onLoad loads the Rive character, which needs
    // RiveNative.init() and so cannot run under `flutter test`. The empty-sky
    // cue is tested on its own logic instead, with the game's real interval.
    testWithFlameGame('rapid taps collapse into a single gentle cue', (
      game,
    ) async {
      final probe = _MissCueProbe();
      await game.ensureAdd(probe);

      // Drumming fingers must not produce a stutter of overlapping sounds.
      for (var i = 0; i < 10; i++) {
        probe.onTapDown(
          createTapDownEvents(game: game, globalPosition: Offset.zero),
        );
      }
      expect(probe.cues, 1, reason: 'rapid taps should collapse into one cue');

      // Once the interval passes the child gets an answer again — the game
      // must never go permanently silent under their finger.
      probe.update(1.0);
      probe.onTapDown(
        createTapDownEvents(game: game, globalPosition: Offset.zero),
      );
      expect(probe.cues, 2);
    });

    testWithFlameGame('a tap on a balloon is consumed by the balloon', (
      game,
    ) async {
      // A success and a "not that one" sound together would be incoherent.
      // Flame stops delivery at the first TapCallbacks component and Balloon
      // does not opt into continuePropagation, so the game never sees it.
      final balloon = Balloon(
        color: Colors.red,
        riseSpeed: 50,
        radius: 46,
        position: Vector2(100, 400),
        onPopped: (_) {},
      );
      await game.ensureAdd(balloon);

      final event = createTapDownEvents(game: game, globalPosition: Offset.zero);
      balloon.onTapDown(event);
      expect(
        event.continuePropagation,
        isFalse,
        reason: 'a popped balloon must not also trigger the empty-sky cue',
      );
    });
  });
}

/// Mirrors the empty-sky cue logic and interval from [BalloonPopGame], which
/// cannot itself be loaded in a test (see the group comment).
class _MissCueProbe extends Component with TapCallbacks {
  int cues = 0;

  /// Starts ready, exactly as the game does: the first tap must be answered.
  double _since = BalloonPopGame.missCueInterval;

  @override
  void update(double dt) => _since += dt;

  @override
  void onTapDown(TapDownEvent event) {
    if (_since < BalloonPopGame.missCueInterval) return;
    _since = 0;
    cues++;
  }
}
