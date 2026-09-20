import 'dart:math';

import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/car_trip/car_trip_game.dart';
import 'package:little_games/games/car_trip/components/car.dart';
import 'package:little_games/games/car_trip/components/traffic.dart';
import 'package:little_games/games/car_trip/road.dart';
import 'package:little_games/games/car_trip/world.dart';
import 'package:little_games/shared/kid_sounds.dart';

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

/// A test with a loaded, mounted, seeded Car Trip.
///
/// `testWithGame` is flame_test's own initialiser — it resizes, loads, mounts
/// and primes the game. Doing that by hand is where the first version of this
/// file went wrong: a root FlameGame's `updateTree` deliberately skips its own
/// `update`, so a hand-rolled harness ran the components and never the game.
void gameTest(
  String name,
  Future<void> Function(CarTripGame game) body, {
  int seed = 7,
}) => testWithGame<CarTripGame>(
  name,
  () => CarTripGame(sounds: _noSounds(), random: Random(seed)),
  body,
);

/// Drives [seconds] of game time in real frame-sized steps. One big update()
/// would skip straight over things on the road and prove nothing.
void _drive(
  CarTripGame game,
  double seconds, {
  double? steerTo,
  bool thumbDown = true,
  double step = 1 / 60,
}) {
  for (var t = 0.0; t < seconds; t += step) {
    if (thumbDown) {
      // Steer by road position rather than by pixels, so the tests say what
      // they mean ("hold the middle", "pull over to the right").
      game.steerToScreenX(
        game.size.x / 2 + (steerTo ?? 0) * game.view.roadHalfWidth,
      );
    } else {
      game.thumbUp();
    }
    // `update`, not `updateTree`: for a root game the former drives the tree
    // and the latter skips the game's own update entirely.
    game.update(step);
  }
}

/// Drives the way a child does once they have understood the game: aim at
/// whichever animal is waiting next, and hold the middle when there is nobody.
///
/// Stops the instant [until] is true, so a test can look at the exact frame
/// something happened rather than several seconds after it.
void _driveChasingPassengers(
  CarTripGame game,
  double seconds, {
  bool Function()? until,
}) {
  const step = 1 / 60;
  for (var t = 0.0; t < seconds; t += step) {
    if (until != null && until()) return;

    RoadThing? target;
    for (final thing in game.traffic.things) {
      if (thing.kind.action != RoadAction.pickUp || thing.spent) continue;
      final depth = thing.depthAt(game.scrolled);
      if (depth < 0 || depth > 900) continue;
      if (target == null || depth < target.depthAt(game.scrolled)) {
        target = thing;
      }
    }

    final steer = target?.lateral ?? 0;
    game.steerToScreenX(game.size.x / 2 + steer * game.view.roadHalfWidth);
    game.update(step);
  }
}

void main() {
  group('the road can always be got past', () {
    test('nothing on the tarmac can block the way through', () {
      // The widest thing that can be hit, plus the car, against the road it has
      // to be got past. If a new thing is ever added that breaks this, THIS
      // TEST is the warning — not a child meeting a wall (CLAUDE.md §3).
      final blocked = RoadThingKind.widestNudge / 2 + Car.halfWidth;
      final driveable = driveableLateral * 2;

      expect(
        driveable - blocked * 2,
        greaterThan(Car.drawWidth * 3),
        reason: 'there must be room for several car widths past anything',
      );
    });

    test('a thing to steer around is smaller to hit than it looks, and a '
        'passenger is bigger', () {
      // Generosity, pointing the same way in both cases: a near miss reads as a
      // miss, a near pickup reads as a pickup. What matters is the distance at
      // which something happens, against the distance at which the child SEES
      // the two shapes touch — comparing the reach to the art alone says
      // nothing, because the car has a width too.
      double drawnTouch(RoadThingKind kind) =>
          kind.drawWidth / 2 + Car.drawWidth / 2;
      double hitAt(RoadThingKind kind) => kind.reach + Car.halfWidth;

      for (final kind in RoadThingKind.withAction(RoadAction.nudge)) {
        expect(
          hitAt(kind),
          lessThan(drawnTouch(kind) * 0.9),
          reason: '${kind.id} bonks before it looks like it touched the car',
        );
      }
      for (final kind in RoadThingKind.withAction(RoadAction.pickUp)) {
        expect(
          hitAt(kind),
          greaterThan(drawnTouch(kind) * 1.5),
          reason: '${kind.id} has to be aimed at rather than pulled up beside',
        );
      }
    });
  });

  group('nothing ever fills the screen', () {
    test('the widest thing sweeping past still leaves the road visible', () {
      // Found by looking at it on a 2.22:1 device, not by assertion: the
      // rainbow arch grew as it passed until it covered the sky, the horizon
      // and the road — a wall of pink for a moment. CLAUDE.md §3 asks for
      // "bright, friendly, calm ... nothing scary", and a child cannot steer
      // on a road they cannot see.
      //
      // The perspective clamp is also the cap on how big anything is drawn,
      // so this is the test that keeps that cap honest.
      // The arch and the car wash are 2.0 units WIDE ON PURPOSE — they span
      // the road so they cannot be missed, and being driven under is the whole
      // point of them. So the rule is not "nothing is big"; it is that the sky
      // and the verges stay visible past the edges, and in particular that
      // perspective growth never turns a gateway into a blindfold.
      final widest = RoadThingKind.all.map((k) => k.drawWidth).reduce(max);

      for (final (w, h) in const [
        (1200.0, 540.0), // 2.22:1, the emulator this was found on
        (956.0, 440.0),
        (667.0, 375.0),
        (1280.0, 800.0),
      ]) {
        final view = Perspective(width: w, height: h);
        final drawn = view.widthAt(widest, -1e6);

        expect(
          drawn,
          lessThan(w),
          reason: 'at ${w}x$h the widest thing on the road is wider than the '
              'screen as it goes by — the child is briefly driving blind',
        );
      }

      // And the growth itself stays modest. This is the number that was wrong
      // (2.2x, so a 2.0-unit arch drew wider than any screen); the cap on it
      // is what the fix actually is.
      final view = Perspective(width: 1200, height: 540);
      expect(
        view.scaleAt(-1e6) / view.scaleAt(0),
        lessThan(1.3),
        reason: 'things swell too much as they sweep past the car',
      );
    });
  });

  group('the spawner', () {
    test('never puts two things closer than the floor', () {
      final world = CarTripWorld(random: Random(3));
      final byKind = <RoadAction, List<double>>{};

      var scrolled = 0.0;
      while (byKind.values.fold(0, (n, l) => n + l.length) < 400) {
        final placed = world.next(scrolled);
        if (placed == null) {
          scrolled += 50;
          continue;
        }
        byKind.putIfAbsent(placed.kind.action, () => []).add(placed.distance);
      }

      // The floor that matters is between things ON the road: the field
      // scenery is never touched, so it may be as dense as it likes.
      final onRoad =
          <double>[
            ...?byKind[RoadAction.driveThrough],
            ...?byKind[RoadAction.nudge],
            ...?byKind[RoadAction.stepsAside],
          ]..sort();

      for (var i = 1; i < onRoad.length; i++) {
        expect(
          onRoad[i] - onRoad[i - 1],
          greaterThanOrEqualTo(CarTripWorld.minGap - 0.001),
          reason: 'the road became a slalom at ${onRoad[i]}',
        );
      }
    });

    test('never gets denser the longer the child plays', () {
      // No difficulty ramp, ever: a child still learning to hold a line must
      // not be punished for staying (CLAUDE.md §3, and the scope's *Not this*).
      final world = CarTripWorld(random: Random(11));
      final gaps = <double>[];
      var last = 0.0;
      var scrolled = 0.0;

      while (gaps.length < 300) {
        final placed = world.next(scrolled);
        if (placed == null) {
          scrolled += 50;
          continue;
        }
        if (placed.kind.action == RoadAction.pickUp) continue;
        if (last > 0) gaps.add(placed.distance - last);
        last = placed.distance;
      }

      double mean(Iterable<double> xs) =>
          xs.fold(0.0, (a, b) => a + b) / xs.length;
      final early = mean(gaps.take(60));
      final late = mean(gaps.skip(gaps.length - 60));

      expect(
        late,
        greaterThan(early * 0.85),
        reason: 'the road crowded up over time: $early then $late',
      );
    });

    test('a passenger driven past comes back', () {
      // Nothing in this game can be missed for good, so the trip cannot be made
      // longer or shorter by being good at it (the scope's *What*).
      final world = CarTripWorld(random: Random(5));
      world.missed(RoadThingKind.bear);
      expect(world.owed, 1);

      PlacedThing? next;
      var scrolled = 0.0;
      while (next == null) {
        final placed = world.next(scrolled);
        if (placed == null) {
          scrolled += 50;
          continue;
        }
        if (placed.kind.action == RoadAction.pickUp) next = placed;
      }
      expect(next.kind.id, 'bear');
      expect(world.owed, 0);
    });

    test('passengers alternate sides of the road', () {
      // So a child is never asked for the same side twice running, and every
      // trip practises both directions.
      final world = CarTripWorld(random: Random(9));
      final sides = <double>[];
      var scrolled = 0.0;
      while (sides.length < 6) {
        final placed = world.next(scrolled);
        if (placed == null) {
          scrolled += 50;
          continue;
        }
        if (placed.kind.action == RoadAction.pickUp) {
          sides.add(placed.lateral.sign);
        }
      }
      for (var i = 1; i < sides.length; i++) {
        expect(sides[i], isNot(sides[i - 1]));
      }
    });
  });

  group('nothing alive can be hit', () {
    gameTest('a duck crossing the road always gets clear, even when chased', (game) async {
      // THE RULE THIS GAME IS MOST ABOUT. Driving into an animal is funny in a
      // game and appalling in life, and a five-year-old does not hold those
      // apart (the scope's *Kid-rules impact*).
      final duck = RoadThing(
        kind: RoadThingKind.crossingDucks,
        distance: game.scrolled + 600,
        lateral: 0,
      );
      game.traffic.things.add(duck);

      var closest = double.infinity;
      for (var t = 0.0; t < 6; t += 1 / 60) {
        // Chase it: steer straight at wherever the duck currently is.
        game.steerToScreenX(
          game.size.x / 2 + duck.lateral * game.view.roadHalfWidth,
        );
        game.update(1 / 60);
        if (!game.traffic.things.contains(duck)) break;
        // Only while it is actually alongside: being in the same line as
        // something 600px up the road is not a near miss.
        if (duck.depthAt(game.scrolled).abs() < 150) {
          closest = min(closest, (duck.lateral - game.car.lateral).abs());
        }
      }

      expect(duck.spent, isFalse, reason: 'the duck was run over');
      expect(
        closest,
        greaterThan(0.6),
        reason: 'the car got closer to the duck than it should ever get',
      );
    });
  });

  group('picking someone up', () {
    gameTest('needs only a small lean of the thumb', (game) async {
      // How much steering the game actually demands. If this number ever grows,
      // the game has quietly started asking for aim a five-year-old does not
      // have (CLAUDE.md §3).
      final dog = RoadThing(
        kind: RoadThingKind.dog,
        distance: game.scrolled + 700,
        lateral: 1.12,
      );
      game.traffic.things.add(dog);

      // A quarter of the way over from the centre line — a lean, not a swerve.
      _drive(game, 6, steerTo: 0.25);

      expect(dog.spent, isTrue, reason: 'a lean of the thumb was not enough');
      expect(game.car.aboard.single.id, 'dog');
      expect(game.dots.filled, 1);
    });

    gameTest('still works on a tablet that cannot hold 60fps', (game) async {
      // Found by running it: a software-rendered device drew at ~2fps, and
      // passengers the car drove straight past were never picked up. The hit
      // test only looked at where the car IS, so anything that passed clean
      // through the window between two frames was never noticed.
      //
      // A five-year-old's device is a hand-me-down. If a frame spike eats the
      // passenger they correctly steered to, the game has ignored them —
      // exactly the failure CLAUDE.md §3 rules out. Their aim decides what
      // happens here, never the frame rate.
      final dog = RoadThing(
        kind: RoadThingKind.dog,
        distance: game.scrolled + 700,
        lateral: 1.12,
      );
      game.traffic.things.add(dog);

      // 2fps — worse than the emulator that found this.
      _drive(game, 6, steerTo: 0.25, step: 1 / 2);

      expect(
        dog.spent,
        isTrue,
        reason: 'a passenger was missed because the device was slow',
      );
      expect(game.dots.filled, 1);
    });

    gameTest('fills the dots and never empties them', (game) async {
      _drive(game, 30, steerTo: 0.6);
      final filled = game.dots.filled;
      expect(filled, greaterThan(0), reason: 'nobody got in over 30 seconds');

      // Drive on down the middle, picking nobody up: the row must not drain.
      _drive(game, 6, steerTo: 0);
      expect(game.dots.filled, greaterThanOrEqualTo(filled));
    });
  });

  group('arriving', () {
    gameTest('a full car arrives somewhere, empties, and drives on', (game) async {
      final car = game.car;

      // Play a whole trip properly: the game spawns its own passengers and the
      // driver aims at each one, exactly as a child would. Stops on the frame
      // the trip arrives.
      _driveChasingPassengers(game, 120, until: () => game.arrivals > 0);

      expect(game.arrivals, 1, reason: 'a full car never arrived anywhere');
      expect(car.aboard, isEmpty, reason: 'nobody got out');
      expect(game.dots.filled, 0);

      // And it keeps going: no "well done" screen, nothing to dismiss.
      final before = game.scrolled;
      _drive(game, 3);
      expect(game.scrolled, greaterThan(before));

      // The new place arrives as a cross-fade rather than a cut — a hard
      // change of scene is the startling kind CLAUDE.md §3 rules out — so it
      // is only fully in place a couple of seconds later.
      expect(
        game.road.place,
        isNot(Destination.farm),
        reason: 'the place never changed',
      );
    });
  });

  group('there is nothing to lose', () {
    gameTest('clipping a cone costs nothing at all', (game) async {
      _drive(game, 4, steerTo: 0.3); // get up to speed
      final dots = game.dots.filled;
      final aboard = game.car.aboard.length;
      final speed = game.speedFactor;

      final cone = RoadThing(
        kind: RoadThingKind.cone,
        distance: game.scrolled + 300,
        lateral: 0,
      );
      game.traffic.things.add(cone);
      _drive(game, 3, steerTo: 0);

      expect(cone.spent, isTrue, reason: 'the cone was never hit');
      // Nothing was taken away, nothing stopped, nothing ended.
      expect(game.dots.filled, greaterThanOrEqualTo(dots));
      expect(game.car.aboard.length, greaterThanOrEqualTo(aboard));
      expect(game.speedFactor, closeTo(speed, 0.01));
      expect(game.arrivals, 0);
    });

    gameTest('the grass is slower, but it never stops the car', (game) async {
      _drive(game, 3, steerTo: 0); // tarmac
      final onRoad = game.scrolled;
      _drive(game, 3, steerTo: 0);
      final tarmacDistance = game.scrolled - onRoad;

      final before = game.scrolled;
      _drive(game, 3, steerTo: driveableLateral); // right out on the verge
      final vergeDistance = game.scrolled - before;

      expect(game.car.onVerge, isTrue);
      expect(vergeDistance, lessThan(tarmacDistance));
      expect(
        vergeDistance,
        greaterThan(tarmacDistance * 0.6),
        reason: 'the verge must be a texture, not a punishment',
      );
    });

    gameTest('steering off the screen still leaves the car on the road', (game) async {
      _drive(game, 3, steerTo: 12); // a thumb way off the edge
      expect(game.car.lateral, lessThanOrEqualTo(driveableLateral + 0.001));
      expect(game.car.lateral, greaterThan(0));
    });
  });

  group('the thumb is the whole control', () {
    gameTest('lifting it stops the world, putting it back starts it again', (game) async {
      _drive(game, 3, steerTo: 0);
      expect(game.speedFactor, closeTo(1, 0.01));

      _drive(game, 4, thumbDown: false);
      expect(game.speedFactor, 0, reason: 'the car never stopped');

      final stopped = game.scrolled;
      _drive(game, 1, thumbDown: false);
      expect(game.scrolled, stopped, reason: 'the world moved with no thumb');

      _drive(game, 2, steerTo: 0);
      expect(game.scrolled, greaterThan(stopped));
    });

    gameTest('the car never moves sideways on its own', (game) async {
      // The scope's finish line: no moment at which the car does anything the
      // child did not ask it to.
      _drive(game, 2, steerTo: 0.8);
      final parked = game.car.lateral;

      _drive(game, 4, thumbDown: false);
      expect(game.car.lateral, closeTo(parked, 0.001));
    });
  });

  group('the horn', () {
    gameTest('does nothing to the trip, and makes the fields wave', (game) async {
      _drive(game, 6, steerTo: 0);
      final dots = game.dots.filled;
      final aboard = game.car.aboard.length;

      final wavers = game.traffic.things
          .where((t) => t.kind.action == RoadAction.waver)
          .toList();
      expect(wavers, isNotEmpty, reason: 'nothing in the fields to beep at');
      for (final waver in wavers) {
        waver.reactedAt = null;
      }

      for (var i = 0; i < 5; i++) {
        game.horn();
      }

      expect(game.hornPresses, 5);
      expect(
        wavers.where((w) => w.reactedAt != null),
        isNotEmpty,
        reason: 'nothing waved back',
      );
      // The trip is untouched: the horn is a toy, not a control.
      expect(game.dots.filled, dots);
      expect(game.car.aboard.length, aboard);
      expect(game.arrivals, 0);
    });
  });

  group('the projection', () {
    test('things get smaller and higher the further away they are', () {
      const view = Perspective(width: 1280, height: 800);
      expect(view.scaleAt(0), 1);
      expect(view.scaleAt(500), lessThan(view.scaleAt(100)));
      expect(view.yAt(500), lessThan(view.yAt(100)));
      expect(view.yAt(Perspective.viewDepth), greaterThan(view.horizonY));
      expect(view.yAt(0), view.carY);
    });

    test('the road stays crossable on a big screen', () {
      // A tablet must not get a motorway: crossing the road has to stay about a
      // second of steering, or holding a line stops meaning anything.
      const wide = Perspective(width: 2400, height: 1200);
      final crossingSeconds =
          driveableLateral * 2 / Car.maxLateralSpeed;
      expect(wide.roadHalfWidth, lessThanOrEqualTo(300));
      expect(crossingSeconds, lessThan(1.5));
    });
  });
}
