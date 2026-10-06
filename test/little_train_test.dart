import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/sounds.dart';
import 'package:little_games/games/little_train/assets.dart';
import 'package:little_games/games/little_train/lands.dart';
import 'package:little_games/games/little_train/ride.dart';
import 'package:little_games/shared/kid_sounds.dart';

const _dt = 1 / 60;

/// Runs the ride for [seconds], collecting every event.
List<RideEvent> _run(Ride ride, double seconds, {void Function()? each}) {
  final events = <RideEvent>[];
  for (var t = 0.0; t < seconds; t += _dt) {
    each?.call();
    ride.update(_dt);
    events.addAll(ride.drainEvents().map((e) => e.$1));
  }
  return events;
}

/// Runs until [done] is true, or fails after [limit] seconds.
void _until(Ride ride, bool Function() done, {double limit = 120}) {
  for (var t = 0.0; t < limit; t += _dt) {
    if (done()) return;
    ride.update(_dt);
  }
  fail('never happened within ${limit}s');
}

void main() {
  group('the one thing not to break: every passenger gets on', () {
    test('a child who never taps still fills every wagon and reaches the '
        'station', () {
      final ride = Ride();
      final events = _run(ride, 60);

      expect(
        events.where((e) => e == RideEvent.boarded).length,
        greaterThanOrEqualTo(3),
      );
      expect(events, contains(RideEvent.arrived));
      // And the journey goes on to the next land.
      expect(events, contains(RideEvent.landChanged));
      expect(ride.landIndex, greaterThanOrEqualTo(1));
    });

    test('a passenger the train sails past chases it and catches it', () {
      final ride = Ride();
      final first = ride.passengers.first;
      _until(ride, () => first.state == PassengerState.chasing);
      _until(ride, () => first.state == PassengerState.riding, limit: 5);
    });

    test('a chaser is always faster than the train', () {
      // The no-fail promise as a single number. If this ever goes to zero, a
      // passenger can be left behind forever.
      expect(Ride.chaseExtra, greaterThan(0));
    });

    for (final (name, rate, landsAtLeast) in [
      // About one tap every three seconds: a child playing.
      ('playing', 0.005, 2),
      // More than one tap a second, forever: a child hammering the screen.
      // Every tap toggles stop/go, so the train crawls — under the child's
      // control — but it still gets somewhere.
      ('hammering', 0.02, 1),
    ]) {
      test('the train never stands still for good: $name', () {
        final ride = Ride();
        final random = Random(7);
        var stillFor = 0.0;
        var longestStill = 0.0;
        _run(ride, 180, each: () {
          if (random.nextDouble() < rate) ride.tap();
          stillFor = ride.speed == 0 ? stillFor + _dt : 0;
          longestStill = max(longestStill, stillFor);
        });
        expect(ride.landIndex, greaterThanOrEqualTo(landsAtLeast));
        // The station party is the longest stand (by design); nothing else
        // may keep the train standing longer than that.
        expect(longestStill, lessThan(Ride.departAt + 1));
      });
    }

    test('every passenger in every land gets on, even with wild tapping', () {
      final ride = Ride();
      final random = Random(11);
      var boarded = 0;
      for (var t = 0.0; t < 240; t += _dt) {
        if (random.nextDouble() < 0.05) ride.tap();
        ride.update(_dt);
        boarded += ride
            .drainEvents()
            .where((e) => e.$1 == RideEvent.boarded)
            .length;
      }
      // Every land completed has had all three of its passengers board.
      expect(boarded, greaterThanOrEqualTo(ride.landIndex * passengersPerLand));
    });
  });

  group('the verb: stop at the right place', () {
    test('a stop beside a passenger is a perfect stop', () {
      final ride = Ride();
      final first = ride.passengers.first;
      // Tap so the train comes to rest with the front wagon level with them.
      _until(
        ride,
        () => ride.doorX(0) + Ride.brakeDistance >= first.stopX,
      );
      ride.tap();
      ride.drainEvents();
      final events = _run(ride, 3);
      expect(events, contains(RideEvent.perfectStop));
      expect(first.perfect, isTrue);
      expect(first.state, PassengerState.riding);
    });

    test('a stop short of a passenger and they trot over', () {
      final ride = Ride();
      final first = ride.passengers.first;
      _until(
        ride,
        () => ride.doorX(0) + Ride.brakeDistance >= first.stopX - 0.8,
      );
      ride.tap();
      final events = _run(ride, 6);
      expect(events, contains(RideEvent.hurry));
      expect(events, isNot(contains(RideEvent.perfectStop)));
      expect(first.state, PassengerState.riding);
    });

    test('after someone gets on, the train sets off by itself', () {
      final ride = Ride();
      final first = ride.passengers.first;
      _until(ride, () => ride.doorX(0) + Ride.brakeDistance >= first.stopX);
      ride.tap();
      final events = _run(ride, 4);
      expect(events, contains(RideEvent.depart));
      expect(ride.speed, greaterThan(0));
    });

    test('a stop for nobody toots, then goes on its own', () {
      final ride = Ride();
      _run(ride, 0.5);
      ride.tap(); // far from the first passenger
      final events = _run(ride, 4);
      expect(events, contains(RideEvent.stoppedAlone));
      expect(events, contains(RideEvent.depart));
    });

    test('no tap is ever a dead tap', () {
      // CLAUDE.md §3: an ignored tap reads to a five-year-old as the game
      // being broken. Moving it brakes, standing it goes, at the station it
      // toots.
      final ride = Ride();
      _run(ride, 1);
      ride.tap();
      expect(ride.phase, TrainPhase.braking);
      _until(ride, () => ride.phase == TrainPhase.stopped);
      ride.drainEvents();
      ride.tap();
      expect(ride.drainEvents().map((e) => e.$1), contains(RideEvent.depart));

      _until(ride, () => ride.phase == TrainPhase.arrived, limit: 60);
      ride.drainEvents();
      ride.tap();
      expect(ride.drainEvents().map((e) => e.$1), contains(RideEvent.toot));
    });

    test('one gentle speed: nothing speeds the train up over time', () {
      final ride = Ride();
      var fastest = 0.0;
      _run(ride, 120, each: () => fastest = max(fastest, ride.speed));
      expect(fastest, lessThanOrEqualTo(Ride.cruiseSpeed));
    });
  });

  group('the station and the next land', () {
    test('the veil fades — it never jumps (no flashing)', () {
      final ride = Ride();
      var last = ride.veil;
      var biggestStep = 0.0;
      _run(ride, 60, each: () {
        biggestStep = max(biggestStep, (ride.veil - last).abs());
        last = ride.veil;
      });
      // Over at least a third of a second either way.
      expect(biggestStep, lessThan(_dt / 0.3 + 1e-9));
    });

    test('the lands go round: meadow, forest, seaside, snow, meadow', () {
      final ride = Ride();
      final seen = <String>[ride.land.name];
      for (var i = 0; i < 4; i++) {
        _until(ride, () => ride.drainEvents().any(
              (e) => e.$1 == RideEvent.landChanged,
            ));
        seen.add(ride.land.name);
      }
      expect(seen, ['meadow', 'forest', 'seaside', 'snow', 'meadow']);
    });
  });

  group('content', () {
    test('every land has one passenger per wagon', () {
      for (final land in lands) {
        expect(land.passengers, hasLength(passengersPerLand));
      }
    });

    test('every picture the game loads is on disk', () {
      final paths = [
        LittleTrainAssets.engine,
        LittleTrainAssets.wagon,
        LittleTrainAssets.stopPost,
        for (final land in lands) ...land.allPaths,
      ];
      for (final path in paths) {
        expect(File('assets/images/$path').existsSync(), isTrue, reason: path);
      }
    });

    test('every spoken line has a file, in the same order', () {
      final files = soundTypeToFilename(SfxType.kidTrainVoice);
      expect(files, hasLength(TrainLine.values.length));
      for (final file in files) {
        expect(File('assets/sfx/$file').existsSync(), isTrue, reason: file);
      }
      // Spot-check the order, since the index IS the variant.
      expect(files[TrainLine.allAboard.index], 'train_all_aboard.mp3');
      expect(files[TrainLine.byeBye.index], 'train_bye_bye.mp3');
    });

    test('the music is there', () {
      expect(File('assets/music/little_train.mp3').existsSync(), isTrue);
    });
  });
}
