import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/sounds.dart';
import 'package:little_games/games/blast_off/countdown.dart';
import 'package:little_games/shared/kid_sounds.dart';

/// Blast Off is the only game in the app with a clock in it, and CLAUDE.md §3
/// bans "any timer that can cause failure". These tests are how that stays
/// true: the kid rules here are all rules about time, which is exactly what
/// cannot be checked by looking at a screen.
void main() {
  group('countdown', () {
    test('counts down and reaches zero exactly once', () {
      final countdown = Countdown()..start();
      final said = <int>[];

      // 12 seconds of ticks over a 10 second countdown: it must not keep
      // counting past zero, and must not announce zero twice.
      for (var i = 0; i < 12 * 60; i++) {
        final reached = countdown.tick(1 / 60);
        if (reached != null) said.add(reached);
      }

      expect(said.where((n) => n == 0), hasLength(1));
      expect(
        said.takeWhile((n) => n != 0),
        [9, 8, 7, 6, 5, 4, 3, 2, 1],
        reason: 'every number said once, in order, and never a 10 twice',
      );
      expect(countdown.phase, CountdownPhase.launched);
    });

    test('never goes below zero or backwards', () {
      final countdown = Countdown()..start();
      var last = countdown.secondsLeft;
      for (var i = 0; i < 20 * 60; i++) {
        countdown.tick(1 / 60);
        expect(countdown.secondsLeft, lessThanOrEqualTo(last));
        expect(countdown.secondsLeft, greaterThanOrEqualTo(0));
        last = countdown.secondsLeft;
      }
    });

    test('stopping costs nothing and can be done at any moment', () {
      final countdown = Countdown()..start();
      for (var i = 0; i < 200; i++) {
        countdown.tick(1 / 60);
      }

      countdown.stop();

      // The whole point: stopping returns to the same state as never having
      // started. Nothing is recorded, nothing is half-done, nothing is lost.
      expect(countdown.phase, CountdownPhase.waiting);
      expect(countdown.starsLeft, Countdown.jarStars);

      // And it can start again immediately, from full.
      countdown.start();
      expect(countdown.secondsLeft, CountdownLength.ten.seconds);
    });

    test('a long countdown still climbs the ten-rung sound ladder', () {
      final countdown = Countdown(length: CountdownLength.fiveMinutes)..start();
      final rungs = <int>{};

      for (var i = 0; i < CountdownLength.fiveMinutes.seconds * 60 + 60; i++) {
        final reached = countdown.tick(1 / 60);
        if (reached != null && reached > 0) {
          rungs.add(
            KidSounds.countRung(countdown.soundRungsLeft, Countdown.soundRungs),
          );
        }
      }

      // Five minutes resolves into the launch as the same musical phrase as
      // ten seconds does — the sound says "nearly there" either way.
      expect(rungs.length, Countdown.soundRungs);
      expect(rungs.reduce((a, b) => a > b ? a : b), Countdown.soundRungs - 1);
    });

    test('the jar empties in step with the clock, whatever the length', () {
      for (final length in CountdownLength.values) {
        if (length.seconds < Countdown.jarStars) continue;
        final countdown = Countdown(length: length)..start();
        expect(countdown.starsLeft, Countdown.jarStars);

        // Half way through, half the stars are gone.
        countdown.tick(length.seconds / 2);
        expect(countdown.starsLeft, Countdown.jarStars ~/ 2, reason: '$length');
      }
    });

    test('the final stretch is the last three numbers only', () {
      final countdown = Countdown()..start();
      expect(countdown.isFinalStretch, isFalse);

      countdown.tick(7.5);
      expect(countdown.secondsLeft, 3);
      expect(countdown.isFinalStretch, isTrue);

      // And it is never "final stretch" when nothing is running — the
      // build-up must not leak into the waiting screen.
      countdown.stop();
      expect(countdown.isFinalStretch, isFalse);
    });
  });

  group('setting the time', () {
    test('more and less step one rung at a time and stop at the ends', () {
      final countdown = Countdown(length: CountdownLength.values.first);

      // At the bottom: less does nothing, and SAYS it did nothing.
      expect(countdown.canShorten, isFalse);
      expect(countdown.shorter(), isFalse);
      expect(countdown.length, CountdownLength.values.first);

      // Walk all the way up.
      var steps = 0;
      while (countdown.longer()) {
        steps++;
      }
      expect(countdown.length, CountdownLength.values.last);
      expect(steps, CountdownLength.values.length - 1);
      expect(countdown.canLengthen, isFalse);
    });

    test('every reachable length is a sensible one', () {
      // There is no number pad, so there is no countdown of 47 seconds: the
      // only reachable values are the rungs, and they only go up.
      final seconds = CountdownLength.values.map((l) => l.seconds).toList();
      expect(seconds, orderedEquals([...seconds]..sort()));
      expect(seconds.toSet(), hasLength(seconds.length));
      expect(seconds.first, greaterThan(0));
    });

    test('the presets are far apart, and all of them real rungs', () {
      final presets = CountdownLength.presets;
      expect(presets, hasLength(3));
      for (final preset in presets) {
        expect(CountdownLength.values, contains(preset));
      }
      // A quick one, a middling one, a long one — a child picking by picture
      // should get a genuinely different wait each time.
      expect(presets[1].seconds, greaterThan(presets[0].seconds * 2));
      expect(presets[2].seconds, greaterThan(presets[1].seconds * 2));
    });

    test('the length cannot be changed while it is counting', () {
      final countdown = Countdown(length: CountdownLength.ten)..start();
      countdown.tick(3);

      // Adding seconds back on mid-count would read as a punishment, and
      // cutting them off would read as the clock being taken away.
      expect(countdown.longer(), isFalse);
      expect(countdown.shorter(), isFalse);
      countdown.choose(length: CountdownLength.fiveMinutes);
      expect(countdown.length, CountdownLength.ten);
      expect(countdown.secondsLeft, 7);
    });
  });

  group('pausing', () {
    test('holds the clock exactly where it was, and takes nothing away', () {
      final countdown = Countdown(length: CountdownLength.thirty)..start();
      countdown.tick(8);
      final atPause = countdown.secondsLeft;
      final starsAtPause = countdown.starsLeft;

      countdown.pause();
      expect(countdown.phase, CountdownPhase.paused);

      // Ten seconds of ticks while held must change nothing at all. A clock
      // that drained while paused would be a penalty for pausing.
      for (var i = 0; i < 10 * 60; i++) {
        expect(countdown.tick(1 / 60), isNull);
      }
      expect(countdown.secondsLeft, atPause);
      expect(countdown.starsLeft, starsAtPause);

      // And it carries on from exactly there, rather than restarting.
      countdown.resume();
      expect(countdown.phase, CountdownPhase.counting);
      countdown.tick(1);
      expect(countdown.secondsLeft, atPause - 1);
    });

    test('pause and resume do nothing from the wrong state', () {
      final countdown = Countdown();

      // Nothing to hold before it starts.
      countdown.pause();
      expect(countdown.phase, CountdownPhase.waiting);
      countdown.resume();
      expect(countdown.phase, CountdownPhase.waiting);

      // And a launch cannot be paused back into existence.
      countdown.start();
      countdown.tick(CountdownLength.ten.seconds + 1);
      expect(countdown.phase, CountdownPhase.launched);
      countdown.pause();
      expect(countdown.phase, CountdownPhase.launched);
    });

    test('a paused countdown is still underway, not back at the start', () {
      final countdown = Countdown()..start();
      countdown.tick(4);
      countdown.pause();

      expect(countdown.isUnderway, isTrue);
      // The jar must hold, not refill — refilling would say the wait had
      // been given back.
      expect(countdown.starsLeft, lessThan(Countdown.jarStars));
      // And nothing leans in while it is held.
      expect(countdown.isFinalStretch, isFalse);
    });
  });

  group('the clock readout', () {
    test('reads as an adult expects, in every phase', () {
      final countdown = Countdown(length: CountdownLength.twoMinutes);

      // Waiting shows what has been SET, so more/less can be read.
      expect(countdown.clock, '2:00');
      countdown.choose(length: CountdownLength.fiveMinutes);
      expect(countdown.clock, '5:00');
      countdown.choose(length: CountdownLength.thirty);
      expect(countdown.clock, '0:30');

      // Counting shows what is LEFT.
      countdown.choose(length: CountdownLength.twoMinutes);
      countdown.start();
      countdown.tick(35);
      expect(countdown.clock, '1:25');

      // Held, it holds.
      countdown.pause();
      countdown.tick(10);
      expect(countdown.clock, '1:25');
    });

    test('is a second readout, never the only one', () {
      // The dots and the jar say the same thing without reading. If the
      // digits were the only readout, a child could not set or follow a
      // countdown at all (CLAUDE.md §3).
      final countdown = Countdown(length: CountdownLength.five);
      expect(countdown.starsLeft, Countdown.jarStars);
      expect(CountdownLength.five.index, isNonNegative);

      countdown.start();
      countdown.tick(2.5);
      expect(countdown.starsLeft, lessThan(Countdown.jarStars));
    });
  });

  group('the sound of a countdown', () {
    test('the ladder resolves upward into the launch', () {
      // Rung 0 is furthest away, the top rung is "one". A countdown that fell
      // in pitch would sound like something running out (CLAUDE.md §3).
      final ten = KidSounds.countRung(10, 10);
      final one = KidSounds.countRung(1, 10);
      expect(ten, 0);
      expect(one, soundTypeToFilename(SfxType.kidCount).length - 1);
      expect(one, greaterThan(ten));
    });

    test('zero is never quieter than the count it resolves', () {
      // The reward must be the biggest thing the child hears.
      expect(
        soundTypeToVolume(SfxType.kidLaunch),
        greaterThan(soundTypeToVolume(SfxType.kidCount)),
      );
      // And nothing about a countdown may be louder than the celebration.
      expect(
        soundTypeToVolume(SfxType.kidCount),
        lessThan(soundTypeToVolume(SfxType.kidCelebrate)),
      );
    });

    test('there is no buzzer anywhere in the set', () {
      // A countdown that ends in an alarm is the one sound this app must
      // never make. Every cue is a named kid cue; nothing reaches for the
      // template's arcade damage/hit sounds.
      for (final type in [SfxType.kidCount, SfxType.kidLaunch]) {
        for (final file in soundTypeToFilename(type)) {
          expect(file, startsWith('kid_'));
        }
      }
    });
  });
}
