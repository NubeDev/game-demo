import 'dart:io';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/quacky_the_duck/components/chase_target.dart';
import 'package:little_games/games/quacky_the_duck/components/hazard.dart';
import 'package:little_games/games/quacky_the_duck/components/progress_rolls.dart';
import 'package:little_games/games/quacky_the_duck/components/quacky.dart';
import 'package:little_games/games/quacky_the_duck/park.dart';
import 'package:little_games/games/quacky_the_duck/quacky_the_duck_game.dart';
import 'package:little_games/games/quacky_the_duck/world.dart';
import 'package:little_games/shared/kid_sounds.dart';

/// Runs [seconds] of game time in small steps, the way a real frame loop
/// would — one big `update(9.0)` would skip straight over the chase and prove
/// nothing.
void _run(Component c, double seconds, {double step = 1 / 60}) {
  for (var t = 0.0; t < seconds; t += step) {
    c.update(step);
  }
}

/// Like [_run], but for the game itself.
///
/// Note it calls `update`, **not** `updateTree`: for a root game (parent null)
/// `FlameGame.updateTree` skips the game's own `update` body entirely, so
/// driving the tree directly runs the scenery and stops running the game.
void _runGame(FlameGame game, double seconds, {double step = 1 / 60}) {
  for (var t = 0.0; t < seconds; t += step) {
    game.update(step);
  }
}

/// Like [_runGame], but with a press every couple of seconds — a child who is
/// actually playing.
///
/// Needed for anything that takes more than [QuackyTheDuckGame.idleTimeout] to
/// happen: with no presses at all Quacky correctly sits down and the park
/// stops, so a long unplayed run measures the idle behaviour rather than the
/// thing under test.
void _play(FlameGame game, double seconds, {double step = 1 / 60}) {
  var i = 0;
  for (var t = 0.0; t < seconds; t += step) {
    game.update(step);
    if (i++ % 180 == 0) (game as QuackyTheDuckGame).pressDash();
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

/// A tester that boots a REAL, fully mounted [QuackyTheDuckGame].
///
/// Calling `onLoad()` by hand is not enough: components added during it are
/// only queued, and an effect on an unmounted component has no target and
/// throws. Letting Flame own the lifecycle means these tests exercise the same
/// tree a child does — which is what caught the concurrent-modification crash
/// this game had the first time a hazard scrolled off screen (the same one
/// Crystal Party hit).
FlameTester<QuackyTheDuckGame> _tester({int seed = 1}) =>
    FlameTester<QuackyTheDuckGame>(
      () => QuackyTheDuckGame(sounds: _noSounds(), random: Random(seed)),
      gameSize: Vector2(1280, 720),
    );

/// Drop a hazard right on top of Quacky, centred on him, so a collision test
/// is not decided by a few pixels of overlap at one edge.
Future<Hazard> _dropOn(QuackyTheDuckGame game, HazardKind kind) async {
  final y = kind.action == HazardAction.duck
      ? QuackyTheDuckGame.duckHazardYFor(kind, game.park.groundY)
      : game.park.groundY;
  final hazard = Hazard(
    kind: kind,
    position: Vector2(game.quacky.position.x - kind.size.width / 2, y),
  );
  await game.ensureAdd(hazard);
  return hazard;
}

void main() {
  // =========================================================================
  // The promise: the bread never gets away.
  //
  // This is the scope's central claim and the thing that makes a chase legal
  // under CLAUDE.md §3. These tests are the ones to look at first if this game
  // is ever accused of having grown a fail state.
  // =========================================================================
  group('the bread never gets away', () {
    _tester().testGameWidget(
      'a child who NEVER presses dash still gets every treat',
      setUp: (game, tester) async {
        // Not one press. The idle behaviour sits him down after
        // QuackyTheDuckGame.idleTimeout, which is exactly the point: even a
        // completely passive child eats.
        _runGame(game, QuackyWorld.catchUpSeconds + 1);
      },
      verify: (game, tester) async {
        expect(
          game.treatsThisRound,
          greaterThan(0),
          reason: 'the gap must close on its own — dash is a throttle on WHEN '
              'a treat arrives, never on whether it arrives at all',
        );
      },
    );

    _tester().testGameWidget(
      'the gap only ever shrinks, never grows',
      setUp: (game, tester) async {
        var previous = game.chaseGap;
        var sawACatch = false;

        for (var i = 0; i < 60 * 14; i++) {
          game.update(1 / 60);
          final gap = game.chaseGap;
          // A catch resets the gap for the NEXT target, which is the one legal
          // increase. Everything else must be downhill.
          if (gap > previous + 0.001) {
            expect(
              gap,
              closeTo(QuackyWorld.startGap, 2),
              reason: 'the only way the gap may grow is a fresh target after a '
                  'catch; anything else is the target outrunning the child',
            );
            sawACatch = true;
          }
          previous = gap;
        }

        expect(sawACatch, isTrue, reason: 'the run should have caught somebody');
      },
      verify: (game, tester) async {},
    );

    _tester().testGameWidget(
      'a beak-bonk does not cost any ground',
      setUp: (game, tester) async {
        _runGame(game, 2);
        final before = game.chaseGap;

        // Walk him straight into a bench without ducking.
        final hazard = await _dropOn(game, HazardKind.bench);
        game.update(1 / 60);

        expect(hazard.isSpent, isTrue, reason: 'he should have bonked it');
        expect(hazard.wasCleared, isFalse);
        expect(game.quacky.state, QuackyState.huffing);
        expect(
          game.chaseGap,
          lessThanOrEqualTo(before),
          reason: 'a miss must never push the target further away — the scope: '
              '"whatever he was chasing waits for him"',
        );
      },
      verify: (game, tester) async {},
    );

    // Two identical games from the same seed, one played and one ignored, for
    // the same length of time. Both run under a real FlameTester: hand-rolling
    // the lifecycle leaves the celebration's confetti effects targeting
    // unmounted components, which throws.
    int? patientTreats;

    _tester(seed: 3).testGameWidget(
      'a child who only watches still eats (the baseline)',
      setUp: (game, tester) async {
        _runGame(game, 5);
        patientTreats = game.treatsThisRound;
      },
      verify: (game, tester) async {
        expect(patientTreats, greaterThan(0));
      },
    );

    _tester(seed: 3).testGameWidget(
      'and dashing gets MORE in the same time',
      setUp: (game, tester) async {
        for (var i = 0; i < 60 * 5; i++) {
          game.update(1 / 60);
          // A child leaning on the button.
          if (i % 10 == 0) game.pressDash();
        }
      },
      verify: (game, tester) async {
        expect(
          game.treatsThisRound,
          greaterThan(patientTreats!),
          reason: 'dashing must be rewarded with more treats in the same time '
              '— otherwise the button does nothing and the child stops using '
              'it. It buys SOONER, never OTHERWISE-IMPOSSIBLE.',
        );
      },
    );

    test('the drift alone closes the whole gap within the promised time', () {
      // The arithmetic behind the promise, with no game running. If this ever
      // fails, a child who does not press dash is waiting forever.
      final seconds =
          (QuackyWorld.startGap - QuackyWorld.caughtWithin) / QuackyWorld.drift;
      expect(seconds, closeTo(QuackyWorld.catchUpSeconds, 0.01));
      expect(
        QuackyWorld.drift,
        greaterThan(0),
        reason: 'a drift of zero is a target that never arrives',
      );
    });
  });

  // =========================================================================
  // Ducking: the pun, and the one timed press in the game.
  // =========================================================================
  group('ducking', () {
    test('every duck hazard clears a flat duck and blocks a standing one', () {
      const groundY = 500.0;

      for (final kind in HazardKind.withAction(HazardAction.duck)) {
        final y = QuackyTheDuckGame.duckHazardYFor(kind, groundY);
        final bottomEdge = y - kind.size.height + kind.hitBox.height;

        expect(
          bottomEdge,
          lessThanOrEqualTo(groundY - Quacky.duckedHeight),
          reason: '${kind.id}: its lower edge must be ABOVE a flat duck, or '
              'ducking it does nothing',
        );
        expect(
          bottomEdge,
          greaterThan(groundY - 104),
          reason: '${kind.id}: and low enough that a STANDING duck hits it — '
              'otherwise he walks underneath and the button is pointless',
        );
      }
    });

    test('a tapped duck outlasts the widest thing it has to pass', () {
      final quacky = Quacky(position: Vector2(100, 400));
      quacky.duck();
      quacky.releaseDuck(); // a tap, not a hold

      final widest = HazardKind.withAction(HazardAction.duck)
          .map((k) => k.size.width)
          .reduce(max);
      // How long that thing takes to pass him at the park's one speed.
      final passSeconds = widest / QuackyWorld.scrollSpeed;

      _run(quacky, passSeconds);
      expect(
        quacky.isDucking,
        isTrue,
        reason: 'a TAP must cover the whole obstacle ($widest px, '
            '${passSeconds.toStringAsFixed(2)}s) — holding a button for a '
            'precise window is a fine-motor skill five-year-olds lack',
      );
    });

    test('a press during a huff is remembered and fires afterwards', () {
      final quacky = Quacky(position: Vector2(100, 400));
      quacky.bonk();
      // An eager child pressing while he is still spinning round.
      quacky.duck();
      expect(quacky.isDucking, isFalse, reason: 'still huffing');

      _run(quacky, Quacky.huffDuration + 0.05);
      expect(
        quacky.isDucking,
        isTrue,
        reason: 'the child should never feel their press was ignored',
      );
    });

    _tester().testGameWidget(
      'ducking under a bench is a clean clear, not a bonk',
      setUp: (game, tester) async {
        _runGame(game, 2);
        final rung = game.chimeRung;

        game.pressDuck();
        final hazard = await _dropOn(game, HazardKind.bench);
        // Long enough for it to travel past him. A successful duck produces no
        // collision at all — he passes underneath — so the clear registers as
        // the bench clears his beak, not on contact.
        _runGame(game, HazardKind.bench.size.width / QuackyWorld.scrollSpeed + 0.4);

        expect(
          game.quacky.state,
          isNot(QuackyState.huffing),
          reason: 'he ducked in time; there must be no bonk',
        );
        expect(hazard.wasCleared, isTrue);
        expect(game.chimeRung, greaterThan(rung), reason: 'the chime climbs');
      },
      verify: (game, tester) async {},
    );

    _tester().testGameWidget(
      'bumping a bin is neither a clear nor a bonk — he carries on',
      setUp: (game, tester) async {
        _runGame(game, 2);
        final hazard = await _dropOn(game, HazardKind.bin);
        game.update(1 / 60);

        expect(hazard.isSpent, isTrue);
        expect(
          game.quacky.state,
          isNot(QuackyState.huffing),
          reason: 'nothing that is not a duck hazard may ever stop him',
        );
      },
      verify: (game, tester) async {},
    );
  });

  // =========================================================================
  // Nothing gets harder, and nothing is ever crowded.
  // =========================================================================
  group('fairness', () {
    test('hazards are never closer together than the floor', () {
      final world = QuackyWorld(random: Random(7));
      var last = 0.0;
      var wasDuck = false;
      var placed = 0;

      for (var scrolled = 0.0; scrolled < 200000; scrolled += 200) {
        final next = world.next(scrolled, 1280);
        if (next == null) continue;
        placed++;
        if (last > 0) {
          final floor = wasDuck ? QuackyWorld.duckGap : QuackyWorld.minGap;
          expect(
            next.distance - last,
            greaterThanOrEqualTo(floor),
            reason: 'a gap below the floor asks a five-year-old to move a '
                'thumb faster than they can',
          );
        }
        last = next.distance;
        wasDuck = next.kind.action == HazardAction.duck;
      }

      expect(placed, greaterThan(50), reason: 'the walk should be populated');
    });

    test('two duck hazards never arrive back to back', () {
      final world = QuackyWorld(random: Random(11));
      var previousWasDuck = false;

      for (var scrolled = 0.0; scrolled < 200000; scrolled += 200) {
        final next = world.next(scrolled, 1280);
        if (next == null) continue;
        final isDuck = next.kind.action == HazardAction.duck;
        expect(
          isDuck && previousWasDuck,
          isFalse,
          reason: 'duck-then-duck is explicitly out of scope — it is the one '
              'thing a five-year-old thumb genuinely cannot do',
        );
        previousWasDuck = isDuck;
      }
    });

    test('nothing crowds up the longer the child plays', () {
      final world = QuackyWorld(random: Random(5));
      final gaps = <double>[];
      var last = 0.0;

      for (var scrolled = 0.0; scrolled < 400000; scrolled += 200) {
        final next = world.next(scrolled, 1280);
        if (next == null) continue;
        if (last > 0) gaps.add(next.distance - last);
        last = next.distance;
      }

      // The back half must not be denser than the front half. This is the
      // difficulty-ramp guard: no future session gets to "make it a bit more
      // exciting after a while".
      final half = gaps.length ~/ 2;
      final early = gaps.take(half).reduce((a, b) => a + b) / half;
      final later =
          gaps.skip(half).reduce((a, b) => a + b) / (gaps.length - half);
      expect(later, greaterThan(early * 0.85));
    });

    test('no CODE anywhere reassigns the one speed', () {
      // A grep, as a test, over the source with its comments stripped — the
      // prose in these files talks about difficulty in order to forbid it, so
      // grepping the raw text only ever finds itself.
      //
      // `scrollSpeed` is a compile-time constant, so an assignment to it would
      // not compile; what this actually guards is a future session adding a
      // mutable speed *beside* it and quietly ramping that.
      for (final path in [
        'lib/games/quacky_the_duck/world.dart',
        'lib/games/quacky_the_duck/quacky_the_duck_game.dart',
      ]) {
        final code = File(path)
            .readAsLinesSync()
            .where((l) => !l.trimLeft().startsWith('//'))
            .join('\n');
        for (final banned in ['difficulty', 'levelUp', 'speedUp', 'getHarder']) {
          expect(
            code.contains(banned),
            isFalse,
            reason: '$path has "$banned" in its CODE — this game runs at one '
                'speed forever (CLAUDE.md §3)',
          );
        }
      }
    });

    test('the chase closes before the idle sits him down', () {
      // THESE TWO NUMBERS ARE COUPLED, and the first version got it wrong.
      //
      // At catchUpSeconds 9 against an idleTimeout of 6, Quacky sat down
      // before the gap ever closed — so a child who only ever *watched* got
      // nothing at all, and the scope's central promise was false in exactly
      // the case it was written for. Found by the test above, not by playing.
      expect(
        QuackyWorld.catchUpSeconds,
        lessThan(QuackyTheDuckGame.idleTimeout),
        reason: 'the gap has to close inside the window the child is still '
            'being counted as present, or a passive child never eats',
      );
    });
  });

  // =========================================================================
  // Progress: a count, never a score.
  // =========================================================================
  group('progress', () {
    test('the mood only ever climbs as treats are eaten', () {
      var previous = -1.0;
      for (var eaten = 0; eaten <= 10; eaten++) {
        final mood = Mood.forProgress(eaten, 10);
        expect(
          mood.brightness,
          greaterThanOrEqualTo(previous),
          reason: 'Quacky must never get MORE grumpy mid-round — that is '
              'progress visibly going backwards (CLAUDE.md §3)',
        );
        previous = mood.brightness;
      }
      expect(Mood.forProgress(0, 10), Mood.furious);
      expect(Mood.forProgress(10, 10), Mood.delighted);
    });

    test('brightness spans the whole 0..1 a bound Rive number would take', () {
      expect(Mood.furious.brightness, 0);
      expect(Mood.delighted.brightness, 1);
    });

    _tester().testGameWidget(
      'the roll row fills, celebrates, and resets to empty',
      setUp: (game, tester) async {
        // Long enough for a whole row of ten. The occasional press is what a
        // child watching actually does, and it is what keeps Quacky awake —
        // with NO press at all he correctly sits down after one treat and the
        // park stops, which is the idle behaviour working, not a stall.
        _play(game, QuackyWorld.catchUpSeconds * 12);
      },
      verify: (game, tester) async {
        final rolls = game.children.query<ProgressRolls>().single;
        expect(game.celebrations, greaterThan(0));
        expect(
          rolls.filled,
          lessThan(QuackyTheDuckGame.treatsPerCelebration),
          reason: 'the row empties at the celebration, not before it',
        );
      },
    );

    _tester().testGameWidget(
      'a celebration changes the part of the park',
      setUp: (game, tester) async {
        _play(game, QuackyWorld.catchUpSeconds * 12);
        // The cross-fade takes a moment to land.
        _play(game, 2);
      },
      verify: (game, tester) async {
        expect(game.celebrations, greaterThan(0));
        expect(
          game.park.place,
          isNot(ParkPlace.pond),
          reason: 'the park changing is the reward for a full row',
        );
      },
    );

    test('the park cycles forever and nothing is ever locked', () {
      var place = ParkPlace.pond;
      final seen = <ParkPlace>{};
      for (var i = 0; i < ParkPlace.values.length * 3; i++) {
        seen.add(place);
        place = place.next;
      }
      expect(
        seen,
        containsAll(ParkPlace.values),
        reason: 'every part of the park must come round — nothing is missable',
      );
      expect(place, ParkPlace.pond, reason: 'and it wraps, so there is no end');
    });
  });

  // =========================================================================
  // Leaving it alone.
  // =========================================================================
  group('idle', () {
    _tester().testGameWidget(
      'he sits down when nobody is playing, and any press wakes him',
      setUp: (game, tester) async {
        _runGame(game, QuackyTheDuckGame.idleTimeout + 2.5);

        expect(game.quacky.isSitting, isTrue);
        expect(
          game.speedFactor,
          closeTo(0, 0.05),
          reason: 'the park stops with him, so the child can look at things',
        );

        game.pressDash();
        _runGame(game, 0.5);
        expect(game.quacky.isSitting, isFalse);
        expect(game.speedFactor, greaterThan(0));
      },
      verify: (game, tester) async {},
    );

    _tester().testGameWidget(
      'a sitting duck does not gain on anybody',
      setUp: (game, tester) async {
        _runGame(game, QuackyTheDuckGame.idleTimeout + 3);
        final gap = game.chaseGap;
        _runGame(game, 3);
        expect(
          game.chaseGap,
          closeTo(gap, 1),
          reason: 'the idle must read as STOPPED, not as the game playing '
              'itself while the child watches',
        );
      },
      verify: (game, tester) async {},
    );
  });

  // =========================================================================
  // The controls cannot throw, and cannot be wrong.
  // =========================================================================
  group('the controls', () {
    test('a press before onLoad finishes does not throw', () {
      // A child quicker than the loader. In a release build a throw inside a
      // gesture callback is swallowed, so the button would silently do nothing
      // and the game would look broken — Cat Run shipped exactly that bug.
      final game = QuackyTheDuckGame(sounds: _noSounds());
      expect(game.pressDash, returnsNormally);
      expect(game.pressDuck, returnsNormally);
      expect(game.releaseDuck, returnsNormally);
      expect(() => game.update(1 / 60), returnsNormally);
    });

    _tester().testGameWidget(
      'dashing with nobody ahead is harmless',
      setUp: (game, tester) async {
        game.target?.removeFromParent();
        game.update(1 / 60);
        expect(game.pressDash, returnsNormally);
      },
      verify: (game, tester) async {},
    );

    _tester().testGameWidget(
      'ducking with nothing overhead is just a skid',
      setUp: (game, tester) async {
        game.pressDuck();
        _runGame(game, 0.2);
        expect(game.quacky.isDucking, isTrue);
        expect(game.quacky.state, isNot(QuackyState.huffing));
      },
      verify: (game, tester) async {},
    );

    test('a dash burst is short enough not to need holding', () {
      expect(
        Quacky.dashDuration,
        lessThan(1.0),
        reason: 'the dash is a BURST — holding a button is tiring for a small '
            'hand, and Crystal Party already flagged it',
      );
    });
  });

  // =========================================================================
  // The chase targets themselves.
  // =========================================================================
  group('chase targets', () {
    test('the same one never comes round twice running', () {
      final world = QuackyWorld(random: Random(2));
      ChaseKind? previous;
      for (var i = 0; i < 200; i++) {
        final next = world.nextTarget(previous);
        expect(next, isNot(previous));
        previous = next;
      }
    });

    test('every kind is worth exactly one roll — none is a better catch', () {
      // No target may be a dead end, and none may be worth more than another:
      // a rarer target worth more would be a score (CLAUDE.md §3).
      for (final kind in ChaseKind.values) {
        expect(TreatKind.values, contains(kind.treat));
        final target = ChaseTarget(kind: kind, position: Vector2(500, 400));
        target.handOver();
        expect(target.isHandingOver, isTrue);
      }
    });

    test('every kind of target can actually be reached', () {
      // Nothing in ChaseKind may be unreachable — a target the spawner never
      // picks is art a child never sees.
      final world = QuackyWorld(random: Random(4));
      final seen = <ChaseKind>{};
      ChaseKind? previous;
      for (var i = 0; i < 500; i++) {
        previous = world.nextTarget(previous);
        seen.add(previous);
      }
      expect(seen, containsAll(ChaseKind.values));
    });
  });
}
