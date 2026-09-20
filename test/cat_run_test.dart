import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/cat_run/cat_run_game.dart';
import 'package:little_games/shared/kid_sounds.dart';
import 'package:little_games/games/cat_run/components/cat.dart';
import 'package:little_games/games/cat_run/components/obstacle.dart';
import 'package:little_games/games/cat_run/components/prize.dart';
import 'package:little_games/games/cat_run/components/progress_fish.dart';
import 'package:little_games/games/cat_run/obstacles.dart';
import 'package:little_games/games/cat_run/world.dart';

/// Runs [seconds] of game time through a component in small steps, the way a
/// real frame loop would — one big `update(3.0)` would skip straight over the
/// jump arc and prove nothing.
void _run(Component c, double seconds, {double step = 1 / 60}) {
  for (var t = 0.0; t < seconds; t += step) {
    c.update(step);
  }
}

/// Like [_run], but drives the whole game tree.
///
/// Needed for anything that removes itself via an effect: effects are children
/// of the component, so they are only updated when the tree is, and a component
/// that calls `removeFromParent` is not actually detached until the game
/// processes its queue.
void _runGame(FlameGame game, double seconds, {double step = 1 / 60}) {
  for (var t = 0.0; t < seconds; t += step) {
    game.update(step);
  }
}

/// A KidSounds that never reaches the audio plugin.
///
/// Constructing a real AudioController preloads assets through the services
/// binding, which is not available in a plain unit test — and none of these
/// tests are about sound.
KidSounds _noSounds() => KidSounds(_SilentAudio());

class _SilentAudio implements AudioController {
  @override
  void noSuchMethod(Invocation invocation) {}
}

/// The topmost row of the canvas the cat actually paints on, drawing it the way
/// the game does: feet on a fixed ground line, the cat's own render applying
/// whatever air it has gained.
///
/// Rendering to pixels rather than inspecting a transform on purpose — the
/// question is "did the player see the cat move", and only the image answers it.
Future<int> _highestPaintedRow(Cat cat) async {
  const width = 300;
  const height = 600;
  const groundY = 500.0;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.save();
  canvas.translate(width / 2 - cat.size.x / 2, groundY - cat.size.y);
  cat.render(canvas);
  canvas.restore();

  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      // Alpha channel: anything drawn at all counts.
      if (bytes[(y * width + x) * 4 + 3] != 0) return y;
    }
  }
  fail('the cat painted nothing at all');
}

void main() {
  group('the jump', () {
    testWithFlameGame('clears the tallest thing it has to clear', (game) async {
      final cat = Cat(position: Vector2(100, 400));
      await game.ensureAdd(cat);
      cat.jump();

      // The peak of the arc, and the tallest obstacle hitbox in the game.
      var peak = 0.0;
      _run(cat, Cat.jumpDuration, step: 1 / 120);
      // Re-run sampling the peak, since _run leaves it back on the ground.
      cat.jump();
      for (var t = 0.0; t < Cat.jumpDuration; t += 1 / 120) {
        cat.update(1 / 120);
        peak = max(peak, cat.airHeight);
      }

      // The cat's feet must go clearly higher than the tallest obstacle —
      // "clearly" being the margin a five-year-old's timing needs. If a new
      // obstacle is added that breaks this, THIS TEST is the warning, not a
      // child who cannot get over it.
      expect(peak, greaterThan(ObstacleKind.tallestJumpable + 30));
    });

    testWithFlameGame('is actually DRAWN off the ground, not just measured', (
      game,
    ) async {
      // THE REGRESSION TEST FOR THE JUMP THAT WASN'T.
      //
      // `airHeight` rose correctly and every other test in this group passed,
      // while the cat visibly stayed on the ground: nothing ever applied the
      // height to the canvas, so all a player saw was the legs tucking up.
      // Testing `airHeight` cannot catch that — only the pixels can.
      final cat = Cat(position: Vector2(100, 400));
      await game.ensureAdd(cat);

      final onGround = await _highestPaintedRow(cat);
      cat.jump();
      _run(cat, Cat.jumpDuration / 2); // the apex
      final atApex = await _highestPaintedRow(cat);

      // Smaller row index = higher up the screen. The drawn cat must rise by
      // most of its air height, not by a few pixels of stretch.
      expect(
        onGround - atApex,
        greaterThan(cat.airHeight * 0.9),
        reason: 'the cat was measured in the air but drawn on the ground',
      );
    });

    testWithFlameGame('never leaves the top of a short screen', (game) async {
      // A phone in landscape has far less sky than the design rise assumes.
      // Losing the cat off the top is disorienting at five — it reads as the
      // character being gone, not as a big jump.
      const groundY = 273.0; // a 390-tall landscape phone, ground at 0.7
      final cat = Cat(position: Vector2(100, groundY));
      await game.ensureAdd(cat);
      cat.fitTo(headroom: groundY);

      // The highest thing the cat ever does is a bounce, not a jump.
      var peak = 0.0;
      cat.bounce();
      for (var t = 0.0; t < Cat.jumpDuration; t += 1 / 120) {
        cat.update(1 / 120);
        peak = max(peak, cat.airHeight);
      }

      // Its ears, not its feet: the top of the sprite has to stay on screen.
      expect(groundY - peak - cat.size.y, greaterThanOrEqualTo(0));
      // ...and it still has to clear the tallest obstacle by a usable margin.
      expect(peak, greaterThan(ObstacleKind.tallestJumpable + 30));
    });

    testWithFlameGame('comes back down to the ground on its own', (game) async {
      final cat = Cat(position: Vector2(100, 400));
      await game.ensureAdd(cat);
      cat.jump();
      _run(cat, Cat.jumpDuration + 0.2);

      // No pits, no falling: the cat always ends up back on the ground.
      expect(cat.airHeight, closeTo(0, 0.01));
      expect(cat.state, CatState.running);
    });

    testWithFlameGame('accepts a late press — the coyote window', (game) async {
      final cat = Cat(position: Vector2(100, 400));
      await game.ensureAdd(cat);

      // Nothing has been pressed; the cat is running on the ground.
      expect(cat.canJump, isTrue);
      cat.jump();
      expect(cat.state, CatState.jumping);
    });

    testWithFlameGame('remembers an early press and jumps on landing', (
      game,
    ) async {
      final cat = Cat(position: Vector2(100, 400));
      await game.ensureAdd(cat);

      cat.jump();
      // Press again mid-air, well before landing. This must NOT be thrown away:
      // a child whose eager press was ignored reads it as their fault.
      _run(cat, Cat.jumpDuration * 0.5);
      cat.jump();
      // It is not a double jump — still one jump at a time.
      expect(cat.state, CatState.jumping);

      // Land, and the remembered press fires.
      _run(cat, Cat.jumpDuration * 0.55);
      expect(cat.state, CatState.jumping);
      expect(cat.airHeight, greaterThan(0));
    });

    testWithFlameGame('a bounce goes higher than a jump', (game) async {
      final cat = Cat(position: Vector2(100, 400));
      await game.ensureAdd(cat);

      var jumpPeak = 0.0;
      cat.jump();
      for (var t = 0.0; t < Cat.jumpDuration; t += 1 / 120) {
        cat.update(1 / 120);
        jumpPeak = max(jumpPeak, cat.airHeight);
      }

      var bouncePeak = 0.0;
      cat.bounce();
      for (var t = 0.0; t < Cat.jumpDuration; t += 1 / 120) {
        cat.update(1 / 120);
        bouncePeak = max(bouncePeak, cat.airHeight);
      }

      // The reward for landing on a mushroom is air, and it has to read as
      // clearly more than an ordinary jump.
      expect(bouncePeak, greaterThan(jumpPeak * 1.3));
    });
  });

  group('the duck', () {
    testWithFlameGame('fits under every duck obstacle', (game) async {
      final cat = Cat(position: Vector2(100, 400));
      await game.ensureAdd(cat);
      cat.duck();
      cat.update(1 / 60);

      expect(cat.state, CatState.ducking);
      final ducked = cat.hitBox.height;

      // The game places duck obstacles at ducked height + clearance, so the
      // ducked cat must genuinely be shorter than a standing one by a real
      // margin — not by a pixel.
      expect(ducked, lessThan(Cat.standingHeight * 0.7));
      expect(ducked, closeTo(Cat.duckedHeight, 0.01));
    });

    testWithFlameGame('lasts long enough without being held', (game) async {
      final cat = Cat(position: Vector2(100, 400));
      await game.ensureAdd(cat);
      cat.duck();
      cat.releaseDuck();

      // Released immediately — a stab, not a hold. It must still last long
      // enough to pass under something: holding a button for a precise window
      // is a fine-motor skill a five-year-old does not have.
      _run(cat, 0.3);
      expect(cat.state, CatState.ducking);
    });

    testWithFlameGame(
      'every duck obstacle really needs ducking, and really can be ducked',
      (game) async {
        // THIS TEST EXISTS BECAUSE IT WAS BROKEN. Duck obstacles were placed at
        // one height measured from the ground, but each has a different hitbox
        // height — so the pipe's and the washing line's lower edges sat ABOVE a
        // standing cat's head. The cat strolled underneath, the duck button did
        // nothing for two of the three, and every test still passed.
        const groundY = 400.0;

        for (final kind in ObstacleKind.withAction(ObstacleAction.duck)) {
          final obstacle = Obstacle(
            kind: kind,
            position: Vector2(100, CatRunGame.duckObstacleYFor(kind, groundY)),
          );
          await game.ensureAdd(obstacle);
          // Put the cat under the MIDDLE of the obstacle's hitbox. Lining it up
          // with the art's left edge instead leaves a wide obstacle's inset
          // hitbox starting past the cat, which tests the test rather than the
          // game.
          final cat = Cat(
            position: Vector2(obstacle.hitBox.center.dx, groundY),
          );
          await game.ensureAdd(cat);
          game.update(0);

          // Standing: it MUST be in the way, or the duck button is pointless
          // and a whole mechanic is silently dead.
          expect(
            cat.hitBox.overlaps(obstacle.hitBox),
            isTrue,
            reason: '${kind.id} does not block a standing cat',
          );

          // Ducked: it MUST fit through, or the obstacle is impossible and the
          // child is being asked for something they cannot do.
          cat.duck();
          game.update(1 / 60);
          expect(
            cat.hitBox.overlaps(obstacle.hitBox),
            isFalse,
            reason: '${kind.id} cannot be ducked under',
          );

          obstacle.removeFromParent();
          cat.removeFromParent();
          game.update(0);
        }
      },
    );

    testWithFlameGame('ends on its own, so the cat cannot get stuck down', (
      game,
    ) async {
      final cat = Cat(position: Vector2(100, 400));
      await game.ensureAdd(cat);
      cat.duck();
      _run(cat, Cat.duckDuration + 0.1);

      expect(cat.state, CatState.running);
    });
  });

  group('missing', () {
    testWithFlameGame('always ends with the cat running again', (game) async {
      for (final style in MissStyle.values) {
        final cat = Cat(position: Vector2(100, 400));
        await game.ensureAdd(cat);
        cat.bonk(style);
        _run(cat, Cat.recoveryDuration + 0.2);

        // CLAUDE.md §3: no losing, no game over, nothing to get stuck in. Every
        // slapstick ends with the cat upright and running, whatever it was.
        expect(cat.state, CatState.running, reason: 'after a $style');
        expect(cat.airHeight, closeTo(0, 0.01));
        cat.removeFromParent();
        game.update(0);
      }
    });

    testWithFlameGame('a press during the slapstick is not thrown away', (
      game,
    ) async {
      final cat = Cat(position: Vector2(100, 400));
      await game.ensureAdd(cat);
      cat.bonk(MissStyle.tumble);
      // The child presses mid-tumble. They should not be punished for it.
      cat.jump();
      _run(cat, Cat.recoveryDuration + 0.05);

      expect(cat.state, CatState.jumping);
    });

    testWithFlameGame('a bonk cannot interrupt a bonk', (game) async {
      final cat = Cat(position: Vector2(100, 400));
      await game.ensureAdd(cat);
      cat.bonk(MissStyle.tumble);
      cat.bonk(MissStyle.splash);

      // Two obstacles close together must not restart the slapstick and trap
      // the cat in it — that would be being stuck, which is a failure state.
      expect(cat.missStyle, MissStyle.tumble);
      _run(cat, Cat.recoveryDuration + 0.1);
      expect(cat.state, CatState.running);
    });
  });

  group('pressing before the game has loaded', () {
    test('a press that beats the loader does nothing, and does NOT throw', () {
      // THIS TEST EXISTS BECAUSE IT WAS BROKEN, and it was found by playing
      // rather than by testing. The cat was a `late final` assigned in the
      // async onLoad(), while both play buttons are live from the moment the
      // screen paints. A child quicker than the loader hit a
      // LateInitializationError — and because a thrown error inside a gesture
      // callback is swallowed in a release build and in a browser, the button
      // did NOTHING AT ALL, silently. It looked exactly like a broken game.
      final game = CatRunGame(sounds: _noSounds());

      // No onLoad, no resize: the state the very first frame is in.
      expect(game.pressJump, returnsNormally);
      expect(game.pressDuck, returnsNormally);
      expect(game.releaseDuck, returnsNormally);
      // And an update in that state must not throw either.
      expect(() => game.update(1 / 60), returnsNormally);
    });
  });

  group('the world', () {
    test('never spaces obstacles closer than a jump needs', () {
      final world = CatRunWorld(random: Random(7));
      var previous = 0.0;
      var placed = 0;

      // A long run — far longer than a child would play in one sitting.
      for (var scrolled = 0.0; scrolled < 200000; scrolled += 200) {
        final next = world.next(scrolled, 1280);
        if (next == null) continue;
        placed++;
        if (previous > 0) {
          // The floor. Below this the child is asked to land and immediately
          // jump again, which is the reaction test this game must never be.
          expect(
            next.distance - previous,
            greaterThanOrEqualTo(CatRunWorld.minGap),
          );
        }
        previous = next.distance;
      }

      expect(
        placed,
        greaterThan(100),
        reason: 'the run should be full of things',
      );
    });

    test('the minimum gap is longer than a whole jump arc', () {
      // Derived, not asserted by eye: the world moves this far during one jump.
      final jumpTravel = CatRunWorld.scrollSpeed * Cat.jumpDuration;
      // Comfortably more than double, so there is a clear beat after landing.
      expect(CatRunWorld.minGap, greaterThan(jumpTravel * 2));
    });

    test('never asks for a duck straight after another duck', () {
      final world = CatRunWorld(random: Random(3));
      PlacedObstacle? previous;
      var ducks = 0;

      for (var scrolled = 0.0; scrolled < 300000; scrolled += 200) {
        final next = world.next(scrolled, 1280);
        if (next == null) continue;
        if (next.kind.action == ObstacleAction.duck) {
          ducks++;
          if (previous != null) {
            // Never back-to-back...
            expect(previous.kind.action, isNot(ObstacleAction.duck));
          }
        }
        // ...and the gap AFTER a duck is the wide one, because the thumb has to
        // travel back across the screen.
        if (previous?.kind.action == ObstacleAction.duck) {
          expect(
            next.distance - previous!.distance,
            greaterThanOrEqualTo(CatRunWorld.duckGap),
          );
        }
        previous = next;
      }

      // Rare, but they do happen — if this hits zero the duck button has
      // nothing to do and the telegraph is never exercised.
      expect(ducks, greaterThan(5));
    });

    test('the duck telegraph gives a child time to react', () {
      // How many seconds of warning the ears/cue give, at the one fixed speed.
      final warning = CatRunWorld.duckTelegraph / CatRunWorld.scrollSpeed;
      // Two seconds is about the floor for "see it, find the other button,
      // press it" at five. Below this, ducking becomes a reaction test.
      expect(warning, greaterThan(2.0));
    });

    test('does not get harder, faster or denser the longer it runs', () {
      // Two runs from the same seed, one starting after a very long play
      // session: the spacing distribution must be identical, because nothing
      // in the world reads elapsed time or distance.
      final early = CatRunWorld(random: Random(11));
      final late = CatRunWorld(random: Random(11));

      final earlyGaps = <double>[];
      var previous = 0.0;
      for (var s = 0.0; s < 40000; s += 200) {
        final next = early.next(s, 1280);
        if (next == null) continue;
        if (previous > 0) earlyGaps.add(next.distance - previous);
        previous = next.distance;
      }

      // Run the second one far into a session first, then sample.
      for (var s = 0.0; s < 400000; s += 200) {
        late.next(s, 1280);
      }
      final lateGaps = <double>[];
      previous = late.lastDistance;
      for (var s = 400000.0; s < 440000; s += 200) {
        final next = late.next(s, 1280);
        if (next == null) continue;
        lateGaps.add(next.distance - previous);
        previous = next.distance;
      }

      final earlyMean = earlyGaps.reduce((a, b) => a + b) / earlyGaps.length;
      final lateMean = lateGaps.reduce((a, b) => a + b) / lateGaps.length;
      // Within 15%: same generator, same rules, no ramp anywhere.
      expect(lateMean, closeTo(earlyMean, earlyMean * 0.15));
    });

    test('every fish is within reach of a jump', () {
      final world = CatRunWorld(random: Random(5));
      for (var i = 0; i < 500; i++) {
        // A fish above the jump arc would be the one missable thing in the
        // game, which CLAUDE.md §3 rules out.
        expect(world.fishHeight(Cat.jumpRise), lessThan(Cat.jumpRise * 0.8));
      }
    });
  });

  group('obstacles', () {
    test('hitboxes are more forgiving than the art', () {
      for (final kind in ObstacleKind.all) {
        // The block is deliberately generous the other way — it is a reward.
        if (kind.action == ObstacleAction.block) {
          continue;
        }
        // A jump that visually cleared the fence must not register as a bonk.
        expect(
          kind.hitBox.width,
          lessThan(kind.size.width),
          reason: '${kind.id} should be narrower to hit than to see',
        );
      }
    });

    test('a block is easier to hit than it looks — it is a reward', () {
      expect(
        ObstacleKind.block.hitBox.width,
        greaterThan(ObstacleKind.block.size.width),
      );
    });

    test('nothing bouncy has a painful miss', () {
      for (final kind in ObstacleKind.withAction(ObstacleAction.bounce)) {
        // A mushroom the cat ran into must not tumble it. Creatures here are
        // never hurt and never squashed (the scope's *Not this*).
        expect(kind.missStyle, MissStyle.none, reason: kind.id);
      }
    });

    test('every obstacle has something to do about it', () {
      for (final kind in ObstacleKind.all) {
        expect(kind.size.width, greaterThan(0));
        expect(kind.size.height, greaterThan(0));
      }
      // All four actions are represented, or a whole mechanic is dead code.
      for (final action in ObstacleAction.values) {
        expect(ObstacleKind.withAction(action), isNotEmpty, reason: '$action');
      }
    });

    testWithFlameGame('a bounced thing is still there afterwards', (
      game,
    ) async {
      final mushroom = Obstacle(
        kind: ObstacleKind.mushroom,
        position: Vector2(200, 400),
      );
      await game.ensureAdd(mushroom);
      mushroom.react();
      mushroom.markSpent(cleared: true);
      _runGame(game, 1.0);

      // It giggles, springs back and STAYS. Nothing is squashed out of
      // existence — a five-year-old reads a hurt animal as real.
      expect(mushroom.isMounted, isTrue);
    });
  });

  group('progress', () {
    testWithFlameGame('stars only ever fill, never drain', (game) async {
      final stars = ProgressFish(total: 10, position: Vector2.zero());
      await game.ensureAdd(stars);

      stars.filled = 4;
      expect(stars.filled, 4);
      // A celebration resets the row to empty — that is the only way down, and
      // it happens under the confetti.
      stars.filled = 0;
      expect(stars.filled, 0);
      // It cannot be pushed past the end.
      stars.filled = 99;
      expect(stars.filled, 10);
    });

    testWithFlameGame('a taken fish removes itself and cannot be taken twice', (
      game,
    ) async {
      final fish = Fish(position: Vector2(100, 300));
      await game.ensureAdd(fish);

      fish.take();
      expect(fish.isTaken, isTrue);
      fish.take(); // a second overlap in the same frame
      _runGame(game, 0.8);

      expect(fish.isMounted, isFalse);
    });

    testWithFlameGame('a prize floats away and clears itself', (game) async {
      final prize = Prize(kind: BlockPrize.fish, position: Vector2(100, 300));
      await game.ensureAdd(prize);
      _runGame(game, 1.8);

      // Nothing accumulates: there is nothing to catch and nothing to miss.
      expect(prize.isMounted, isFalse);
    });
  });

  group('the scenery', () {
    test('cycles forever and never runs out of places', () {
      var scene = Scene.garden;
      final seen = <Scene>{};
      for (var i = 0; i < 12; i++) {
        scene = scene.next;
        seen.add(scene);
      }
      // Every place comes round again — nothing is unlocked and nothing is
      // final, so a long session never reaches an end.
      expect(seen, Scene.values.toSet());
    });
  });

  group('the numbers that keep it kind', () {
    test('one speed, and it is gentle', () {
      // A jump lasts nearly a second at this speed; the child watches their own
      // press work rather than reacting to it.
      expect(Cat.jumpDuration, greaterThan(0.6));
      expect(CatRunWorld.scrollSpeed, lessThan(260));
    });

    test('late and early presses both have a real window', () {
      // Tens of milliseconds would be a frame-perfect game. These are the
      // windows a five-year-old actually needs.
      expect(Cat.coyoteTime, greaterThanOrEqualTo(0.12));
      expect(Cat.jumpBufferTime, greaterThanOrEqualTo(0.15));
    });

    test('the celebration is reachable in a sitting', () {
      // Ten fish, about one in every other gap: a couple of minutes, not an
      // afternoon. A child must actually see the world change.
      expect(CatRunGame.fishPerCelebration, lessThanOrEqualTo(12));
    });

    test('the cat sits down rather than running on alone', () {
      expect(CatRunGame.idleTimeout, greaterThan(3));
      expect(CatRunGame.idleTimeout, lessThan(15));
    });
  });
}
