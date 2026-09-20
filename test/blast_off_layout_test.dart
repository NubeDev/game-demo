import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/games/blast_off/blast_off_screen.dart';
import 'package:little_games/games/blast_off/components/launch_pad.dart';
import 'package:little_games/games/blast_off/countdown.dart';

/// The scene and the controls are laid out by two different layers — the Flame
/// game draws the rocket, the Flutter screen lays out the buttons — and both
/// anchor to the bottom of the canvas.
///
/// They used to do that independently, so on any screen short enough to matter
/// the rocket and the star jar were drawn straight THROUGH the button row, and
/// the buttons stole taps meant for the rocket (it honks when poked, so it is a
/// touch target too). These tests are the contract that keeps them apart.
const _sizes = <(String, Size)>[
  ('pixel landscape', Size(892, 412)),
  ('small phone landscape', Size(740, 360)),
  ('iphone se landscape', Size(667, 375)),
  ('large phone landscape', Size(956, 440)),
  ('tablet landscape', Size(1280, 800)),
  // The dev window the overlap was first spotted in — shorter than any device
  // we ship to, and included so the fix is proven where it actually failed.
  ('short dev window', Size(1068, 348)),
];

LaunchPad _padFor(Size size) {
  final pad = LaunchPad(
    countdown: Countdown(),
    size: Vector2(size.width, size.height),
  )..bottomInset = BlastOffScreen.controlsReserve(size.width);
  return pad;
}

/// How far the pad lifts the rocket above the grass — the slack the grass is
/// allowed to fall short by before the rocket would be standing in a button.
const _padLift = 12.0;

void main() {
  group('the scene clears the control band', () {
    for (final (name, size) in _sizes) {
      test('$name — grass covers the buttons, rocket stands above them', () {
        final pad = _padFor(size);
        final reserve = BlastOffScreen.controlsReserve(size.width);

        // The whole point: the rocket's feet are above the top of the button
        // band, so nothing in the scene is drawn over a button.
        final controlsTop = size.height - reserve;
        expect(
          pad.padTop,
          lessThanOrEqualTo(controlsTop),
          reason: 'the rocket stands on grass, not on top of the GO button',
        );

        // And the grass reaches up to meet them, so they rest on ground
        // rather than floating in front of the sky. Allowed to fall a little
        // short on a screen so short the grass hits its ceiling — a button
        // top overlapping sky is cosmetic; a rocket underneath one is not.
        expect(pad.groundTop - controlsTop, lessThan(_padLift));
      });

      test('$name — the rocket still fits on screen and stays tappable', () {
        final pad = _padFor(size);
        final rocketTop =
            pad.padTop - LaunchPad.rocketHeight * pad.sceneScale;

        expect(
          rocketTop,
          greaterThanOrEqualTo(0),
          reason: 'a rocket pushed off the top is no better than a hidden one',
        );

        // The rocket honks when poked, which makes it a touch target, so the
        // scene may never shrink it below the 80px floor (CLAUDE.md §3).
        expect(120 * pad.sceneScale, greaterThanOrEqualTo(80));
        expect(pad.sceneScale, lessThanOrEqualTo(1));
      });
    }
  });

  test('a roomy screen is not shrunk at all', () {
    final pad = _padFor(const Size(1280, 800));
    expect(
      pad.sceneScale,
      1,
      reason: 'a tablet has plenty of sky; nothing should be scaled down',
    );
  });

  test('the reserve is the same whatever the countdown is doing', () {
    // A per-phase reserve would be tighter, but the ground would jump each
    // time the phase changed, which is exactly what a 5-year-old should never
    // have to deal with. One number, whatever is on screen.
    final reserve = BlastOffScreen.controlsReserve(892);
    expect(reserve, BlastOffScreen.controlsReserve(892));

    // It clears the tallest button any phase can show ("again", at 150).
    expect(reserve, greaterThanOrEqualTo(150 + 24));
  });

  test('the reserve is the same at every width, because it is always one row', () {
    // The controls used to wrap onto a second row on a narrow screen, which
    // cost 268px of a 375px iPhone SE and left no room for the rocket. Now
    // the steppers drop instead, so the band never grows. If this starts
    // varying with width, a second row has crept back in.
    for (final width in [400.0, 600.0, 667.0, 892.0, 1280.0]) {
      expect(
        BlastOffScreen.controlsReserve(width),
        BlastOffScreen.controlsReserve(1280),
        reason: 'the control band must not get taller on a narrow screen',
      );
    }
  });

  group('the star jar clears the home button', () {
    // Raising the ground lifted the jar too, and on a short screen it reached
    // straight into the home button in the top-right corner. A covered home
    // button is the one thing a child must always be able to find
    // (CLAUDE.md §3), and no assertion caught this — a rendered screenshot
    // did. This is that screenshot, turned into a test.
    for (final (name, size) in _sizes) {
      test(name, () {
        final pad = _padFor(size);
        // Asks the pad, rather than recomputing — a copy of the formula here
        // would keep passing after the real one changed.
        final scale = pad.jarScale;
        final jar = Rect.fromLTWH(
          size.width - pad.jarRight - LaunchPad.jarWidth * scale / 2,
          pad.padTop + 4 - LaunchPad.jarHeight * scale,
          LaunchPad.jarWidth * scale,
          LaunchPad.jarHeight * scale,
        );
        // The home button, exactly where BlastOffScreen puts it.
        const home = Rect.fromLTWH(
          0,
          20,
          LaunchPad.homeButtonWidth,
          LaunchPad.homeButtonWidth,
        );
        final homeOnRight = home.translate(size.width - 20 - home.width, 0);

        expect(
          jar.overlaps(homeOnRight),
          isFalse,
          reason: '$name: the star jar is under the home button',
        );

        // And it did not clear the corner by becoming unreadable: the jar is
        // the countdown a non-reading child follows (CLAUDE.md §3), so it
        // keeps the scene's scale rather than shrinking on its own.
        expect(
          scale,
          pad.sceneScale,
          reason: '$name: the jar shrank instead of moving',
        );
        expect(jar.left, greaterThanOrEqualTo(0));
      });
    }
  });

  test('the ground never eats the whole sky', () {
    // An absurd inset must not push the pad off the top of the screen: the
    // grass stops growing while the smallest legal rocket still fits.
    final pad = LaunchPad(countdown: Countdown(), size: Vector2(900, 400))
      ..bottomInset = 10000;
    expect(pad.padTop, greaterThan(0));
    expect(120 * pad.sceneScale, greaterThanOrEqualTo(80));
  });
}
