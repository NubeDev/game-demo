import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/games/blast_off/blast_off_screen.dart';
import 'package:little_games/games/blast_off/components/launch_pad.dart';
import 'package:little_games/games/blast_off/components/rocket.dart';
import 'package:little_games/games/blast_off/countdown.dart';

/// The rocket grows with the countdown the child sets: a longer wait is a
/// bigger rocket. It is how the game says "this one is longer" to a player who
/// cannot read the clock, and it has to stay honest on every screen we ship
/// to — a rocket that grows off the top, or shrinks under the 80px touch
/// floor, would trade one kid rule for another (CLAUDE.md §3).
const _sizes = <(String, Size)>[
  ('pixel landscape', Size(892, 412)),
  ('iphone se landscape', Size(667, 375)),
  ('tablet landscape', Size(1280, 800)),
  ('short dev window', Size(1068, 348)),
];

/// The rocket's drawn width and height, after the spring has settled.
///
/// Driven the way the game drives it — fit to the pad, then ticked — so what
/// this measures is what a child would actually see, not the target it was
/// aiming at.
({double width, double height}) _settled(Size screen, CountdownLength length) {
  final countdown = Countdown(length: length);
  final pad = LaunchPad(
    countdown: countdown,
    size: Vector2(screen.width, screen.height),
  )..bottomInset = BlastOffScreen.controlsReserve(screen.width);

  final rocket = Rocket(
    countdown: countdown,
    position: Vector2(screen.width / 2, pad.padTop),
  )..fitTo(skyScale: pad.maxSceneScale);

  // Two seconds of frames: long enough for the spring to arrive and stop.
  for (var i = 0; i < 120; i++) {
    rocket.update(1 / 60);
  }
  return (
    width: rocket.size.x * rocket.scale.x,
    height: rocket.size.y * rocket.scale.y,
  );
}

void main() {
  group('the rocket grows with the countdown', () {
    for (final (name, screen) in _sizes) {
      test('$name — a longer wait is never a smaller rocket', () {
        var last = 0.0;
        for (final length in CountdownLength.values) {
          final width = _settled(screen, length).width;
          expect(
            width,
            greaterThanOrEqualTo(last),
            reason: 'pressing "more" must never shrink the rocket',
          );
          last = width;
        }
      });

      test('$name — every length stays tappable and on screen', () {
        final pad = LaunchPad(
          countdown: Countdown(),
          size: Vector2(screen.width, screen.height),
        )..bottomInset = BlastOffScreen.controlsReserve(screen.width);

        for (final length in CountdownLength.values) {
          final drawn = _settled(screen, length);

          // The rocket honks when poked, so it is a touch target at every
          // length — including the shortest, which is the small end.
          expect(
            drawn.width,
            greaterThanOrEqualTo(80),
            reason: '${length.name}: the rocket is a touch target',
          );

          // And the biggest one still stands in the sky rather than through
          // the top of the screen.
          expect(
            pad.padTop - drawn.height,
            greaterThanOrEqualTo(0),
            reason: '${length.name}: the rocket has grown off the top',
          );
        }
      });
    }

    test('a tablet shows a real difference between short and long', () {
      // On a screen with sky to spare the difference has to be *obvious* —
      // this is the whole point of the feature, not a subtle touch. A short
      // screen is allowed to flatten it (there is nowhere to grow), which is
      // why this is asserted on the tablet only.
      const tablet = Size(1280, 800);
      final shortest = _settled(tablet, CountdownLength.five).width;
      final longest = _settled(tablet, CountdownLength.tenMinutes).width;

      expect(longest / shortest, greaterThan(1.4));
    });

    test('the size ladder climbs with the time ladder', () {
      // The model half of the same promise, with no screen involved: every
      // rung sits above the one below it, and the ends are the ends.
      expect(CountdownLength.values.first.sizeStep, 0);
      expect(CountdownLength.values.last.sizeStep, 1);

      var last = -1.0;
      for (final length in CountdownLength.values) {
        expect(length.sizeStep, greaterThan(last));
        last = length.sizeStep;
      }
    });
  });
}
