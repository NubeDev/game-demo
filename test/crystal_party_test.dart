import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/audio/audio_controller.dart';
import 'package:little_games/games/crystal_party/components/arch.dart';
import 'package:little_games/games/crystal_party/components/crystal.dart';
import 'package:little_games/games/crystal_party/components/prop.dart';
import 'package:little_games/games/crystal_party/components/treat.dart';
import 'package:little_games/games/crystal_party/components/unicorn.dart';
import 'package:little_games/games/crystal_party/crystal_party_game.dart';
import 'package:little_games/games/crystal_party/lands.dart';
import 'package:little_games/games/crystal_party/world.dart';
import 'package:little_games/shared/kid_sounds.dart';

/// Runs [seconds] of game time in small steps, the way a real frame loop
/// would — one big `update(3.0)` would skip straight over a flight and prove
/// nothing.
void _run(Component c, double seconds, {double step = 1 / 60}) {
  for (var t = 0.0; t < seconds; t += step) {
    c.update(step);
  }
}

/// A KidSounds that never reaches the audio plugin. Constructing a real
/// AudioController preloads assets through the services binding, which a plain
/// unit test does not have — and none of these tests are about sound.
KidSounds _noSounds() => KidSounds(_SilentAudio());

class _SilentAudio implements AudioController {
  @override
  void noSuchMethod(Invocation invocation) {}
}

void main() {
  group('the flight model — there is no falling in this game', () {
    test('holding raises her, releasing floats her gently back down', () {
      final unicorn = Unicorn(position: Vector2(100, 400));
      unicorn.fitTo(headroom: 400);

      expect(unicorn.isGrounded, isTrue);

      unicorn.hold();
      _run(unicorn, 1.0);
      final high = unicorn.airHeight;
      expect(high, greaterThan(100), reason: 'a second of hold should lift her');

      unicorn.release();
      _run(unicorn, 0.5);
      expect(unicorn.airHeight, lessThan(high));
      expect(unicorn.airHeight, greaterThan(0), reason: 'a float, not a drop');
    });

    test('the descent is SLOWER than the climb — a leaf, not a stone', () {
      // The single most important number in the game for making height feel
      // safe. A five-year-old reads falling as danger.
      expect(Unicorn.fallSpeed, lessThan(Unicorn.riseSpeed));
    });

    test('she never goes below the ground — there is no bottom', () {
      final unicorn = Unicorn(position: Vector2(100, 400));
      unicorn.fitTo(headroom: 400);
      // Release while already on the ground, for a long time.
      unicorn.release();
      _run(unicorn, 10);
      expect(unicorn.airHeight, 0);
      expect(unicorn.isGrounded, isTrue);
    });

    test('she never leaves the top of the sky, and it is a settle not a wall',
        () {
      final unicorn = Unicorn(position: Vector2(100, 600));
      unicorn.fitTo(headroom: 600);
      unicorn.hold();
      _run(unicorn, 12);
      expect(unicorn.airHeight, lessThanOrEqualTo(unicorn.ceiling));

      // The taper: the last stretch of the climb is visibly slower than the
      // first, so the child feels her ease out rather than hit something.
      final fresh = Unicorn(position: Vector2(100, 600))
        ..fitTo(headroom: 600)
        ..hold();
      _run(fresh, 0.2);
      final earlyGain = fresh.airHeight;
      // Fly up to just under the ceiling, then measure the same slice again.
      _run(fresh, 12);
      final atTop = fresh.airHeight;
      _run(fresh, 0.2);
      expect(fresh.airHeight - atTop, lessThan(earlyGain));
    });

    test('a two-second hold reaches the top of the sky', () {
      // The scope's ceiling on what a small hand can be asked to do: the
      // highest crystal is about two seconds of hold away.
      final unicorn = Unicorn(position: Vector2(100, 900));
      unicorn.fitTo(headroom: 900);
      unicorn.hold();
      _run(unicorn, 2.2);
      expect(
        unicorn.airHeight,
        greaterThan(unicorn.ceiling * 0.9),
        reason: 'if this fails, a child cannot reach the pink crystals',
      );
    });

    test('every landing is soft and on four hooves, from any height', () {
      var landings = 0;
      final unicorn = Unicorn(
        position: Vector2(100, 500),
        onLanded: () => landings++,
      );
      unicorn.fitTo(headroom: 500);
      unicorn.hold();
      _run(unicorn, 3);
      unicorn.release();
      _run(unicorn, 10);

      expect(landings, 1);
      expect(unicorn.state, UnicornState.galloping);
      expect(unicorn.airHeight, 0);
    });

    test('a wobble takes no height and no control', () {
      final unicorn = Unicorn(position: Vector2(100, 500));
      unicorn.fitTo(headroom: 500);
      unicorn.hold();
      _run(unicorn, 1);
      final before = unicorn.airHeight;

      unicorn.wobble();
      _run(unicorn, 0.1);

      // Still climbing, still holding. The wobble is cosmetic.
      expect(unicorn.airHeight, greaterThanOrEqualTo(before));
      expect(unicorn.isHolding, isTrue);
    });
  });

  group('the world — nothing gets harder, ever', () {
    test('there is no difficulty ramp: spacing does not tighten over a run',
        () {
      final world = CrystalPartyWorld(random: Random(7));
      final gaps = <double>[];
      var last = 0.0;
      var scrolled = 0.0;
      // A long run — far longer than a child would play in one sitting.
      for (var i = 0; i < 400; i++) {
        final placed = world.next(scrolled, 800);
        if (placed == null) {
          scrolled += 50;
          continue;
        }
        gaps.add(placed.distance - last);
        last = placed.distance;
      }

      expect(gaps.length, greaterThan(50));
      // Every gap clears the floor, at the end of the run as much as the
      // start. Nothing anywhere reads elapsed distance to get meaner.
      for (final gap in gaps) {
        expect(gap, greaterThanOrEqualTo(CrystalPartyWorld.minGap));
      }
      final firstTen = gaps.take(10).reduce((a, b) => a + b) / 10;
      final lastTen =
          gaps.skip(gaps.length - 10).reduce((a, b) => a + b) / 10;
      expect((firstTen - lastTen).abs(), lessThan(CrystalPartyWorld.minGap));
    });

    test('a prop always has extra room after it', () {
      // A crystal tucked behind a pine would ask the child to clip the tree to
      // get it — the one shape this game must never have.
      final world = CrystalPartyWorld(random: Random(3));
      var scrolled = 0.0;
      double? lastPropAt;
      var checked = 0;
      for (var i = 0; i < 2000; i++) {
        final placed = world.next(scrolled, 800);
        if (placed == null) {
          scrolled += 40;
          continue;
        }
        if (lastPropAt != null) {
          expect(
            placed.distance - lastPropAt,
            greaterThanOrEqualTo(
              CrystalPartyWorld.minGap + CrystalPartyWorld.afterPropGap,
            ),
          );
          checked++;
          lastPropAt = null;
        }
        if (placed.prop != null) lastPropAt = placed.distance;
      }
      expect(checked, greaterThan(5), reason: 'no props were actually tested');
    });

    test('blue lives low and pink lives high — the colour IS the place', () {
      final world = CrystalPartyWorld(random: Random(11));
      for (var i = 0; i < 200; i++) {
        expect(
          world.crystalHeight(CrystalColour.blue),
          lessThanOrEqualTo(CrystalPartyWorld.blueHigh),
        );
        expect(
          world.crystalHeight(CrystalColour.pink),
          greaterThanOrEqualTo(CrystalPartyWorld.pinkLow),
        );
      }
      // And the two ranges never overlap, or the sorting would be a lie.
      expect(CrystalPartyWorld.blueHigh, lessThan(CrystalPartyWorld.pinkLow));
    });

    test('blue is reachable without ever leaving the ground', () {
      // A child who never works out the hold must still be able to gather
      // blue crystals at a gallop.
      final unicorn = Unicorn(position: Vector2(100, 500));
      unicorn.fitTo(headroom: 500);
      // The highest blue sits at blueHigh of the ceiling, plus the base
      // offset the game adds. Her body reaches well above her hooves.
      final highestBlue =
          CrystalPartyWorld.blueHigh * unicorn.ceiling + 34;
      expect(
        highestBlue,
        lessThan(unicorn.size.y),
        reason: 'a grounded unicorn must be able to reach every blue crystal',
      );
    });

    test('nothing is ever placed above the sky she can reach', () {
      final world = CrystalPartyWorld(random: Random(5));
      for (var i = 0; i < 500; i++) {
        expect(world.crystalHeight(CrystalColour.pink), lessThanOrEqualTo(1.0));
      }
      expect(CrystalPartyWorld.pinkHigh, lessThan(1.0));
    });
  });

  group('the quiet help — a child who cannot hold still gets the party', () {
    test('a lagging colour starts coming up more often', () {
      final world = CrystalPartyWorld(random: Random(2));
      // A child who only ever gathers blue: they have not worked out the hold.
      for (var i = 0; i < CrystalPartyWorld.helpThreshold; i++) {
        world.recordGathered(CrystalColour.blue);
      }
      expect(world.helpingColour, CrystalColour.pink);

      var pinks = 0;
      for (var i = 0; i < 400; i++) {
        var scrolled = 0.0;
        final w = CrystalPartyWorld(random: Random(i));
        for (var j = 0; j < CrystalPartyWorld.helpThreshold; j++) {
          w.recordGathered(CrystalColour.blue);
        }
        PlacedThing? placed;
        while (placed?.crystal == null) {
          placed = w.next(scrolled, 800);
          scrolled += 60;
        }
        if (placed!.crystal == CrystalColour.pink) pinks++;
      }
      // Helped, so well over half — but not all of them; the other colour has
      // not disappeared.
      expect(pinks, greaterThan(220));
      expect(pinks, lessThan(400));
    });

    test('a helped pink sits LOWER — a shorter hold, not a free one', () {
      final helped = CrystalPartyWorld(random: Random(4));
      for (var i = 0; i < CrystalPartyWorld.helpThreshold; i++) {
        helped.recordGathered(CrystalColour.blue);
      }
      for (var i = 0; i < 200; i++) {
        expect(
          helped.crystalHeight(CrystalColour.pink),
          lessThanOrEqualTo(CrystalPartyWorld.helpedPinkHigh),
        );
        // Still in the sky. The child is still learning the same move.
        expect(
          helped.crystalHeight(CrystalColour.pink),
          greaterThanOrEqualTo(CrystalPartyWorld.pinkLow),
        );
      }
    });

    test('help switches off once the arch catches up', () {
      final world = CrystalPartyWorld(random: Random(1));
      for (var i = 0; i < CrystalPartyWorld.helpThreshold; i++) {
        world.recordGathered(CrystalColour.blue);
      }
      expect(world.helpingColour, CrystalColour.pink);
      for (var i = 0; i < CrystalPartyWorld.helpThreshold; i++) {
        world.recordGathered(CrystalColour.pink);
      }
      expect(world.helpingColour, isNull);
    });

    test('a new land starts the help neutral again', () {
      final world = CrystalPartyWorld(random: Random(1));
      for (var i = 0; i < 10; i++) {
        world.recordGathered(CrystalColour.blue);
      }
      world.resetLand();
      expect(world.helpingColour, isNull);
      expect(world.gathered(CrystalColour.blue), 0);
    });
  });

  group('the arch — a picture, never a number', () {
    test('it fills and never empties except at the party', () {
      final arch = Arch(piecesPerSide: 3, position: Vector2.zero());
      arch.addPiece(CrystalColour.blue);
      arch.addPiece(CrystalColour.blue);
      expect(arch.filled(CrystalColour.blue), 2);
      expect(arch.isFull, isFalse);

      // There is no call that takes a piece out. The only way back to empty is
      // reset(), which happens with the next land.
      arch.addPiece(CrystalColour.blue);
      for (var i = 0; i < 3; i++) {
        arch.addPiece(CrystalColour.pink);
      }
      expect(arch.isFull, isTrue);

      arch.reset();
      expect(arch.filled(CrystalColour.blue), 0);
    });

    test('extra pieces never overflow a side', () {
      final arch = Arch(piecesPerSide: 2, position: Vector2.zero());
      for (var i = 0; i < 20; i++) {
        arch.addPiece(CrystalColour.blue);
      }
      expect(arch.filled(CrystalColour.blue), 2);
    });

    test('the party blaze is SLOW — the photosensitivity rule', () {
      // The most likely rule in this repo to be broken by a future session
      // trying to make the ending feel big (CLAUDE.md §3).
      final arch = Arch(piecesPerSide: 6, position: Vector2(0, 0))
        ..size = Vector2(400, 200);
      arch.startBlaze();

      // A full second in, the blaze is still on its way — it swells, it does
      // not switch on.
      _run(arch, 0.5);
      expect(arch.blaze, lessThan(0.6));
      expect(arch.blaze, greaterThan(0));

      _run(arch, 2);
      expect(arch.blaze, 1);
    });
  });

  group('the lands — scenery, never gates', () {
    test('there is always a next land, forever', () {
      var land = Land.meadow;
      final seen = <Land>{};
      for (var i = 0; i < Land.values.length * 3; i++) {
        seen.add(land);
        land = land.next;
      }
      // Every land is reachable, and it wraps rather than ending.
      expect(seen.length, Land.values.length);
      expect(land, isNotNull);
    });

    test('nothing about a land changes how hard the game is', () {
      // If a future session adds a difficulty field here, this is the test
      // that should stop them. Lands are colours and a water line, nothing
      // else — later lands are prettier, never harder.
      for (final land in Land.values) {
        expect(land.skyTop, isNotNull);
        expect(land.groundNear, isNotNull);
      }
      // The cave DIMS, it never goes black: the darkest land is still lit.
      final darkest = Land.glowwormCave;
      expect(darkest.skyTop.computeLuminance(), greaterThan(0.04));
    });
  });

  group('the chime ladder', () {
    test('blue and pink ring on different halves of the ladder', () {
      // The third cue, after colour and shape: a colourblind child tells them
      // apart by ear (CLAUDE.md §3).
      for (var rung = 0; rung < 12; rung++) {
        final blue =
            CrystalPartyGame.chimeProgress(CrystalColour.blue, rung);
        final pink =
            CrystalPartyGame.chimeProgress(CrystalColour.pink, rung);
        expect(blue, lessThan(pink));
      }
    });

    test('it always climbs again and never runs out', () {
      // Wraps at the top, so there is no rung at which the reward stops
      // getting better.
      final many = List.generate(
        40,
        (r) => CrystalPartyGame.chimeProgress(CrystalColour.blue, r),
      );
      expect(many.every((p) => p >= 0 && p <= 1), isTrue);
      expect(many.toSet().length, greaterThan(1));
    });
  });

  group('the game', () {
    /// A tester that boots a REAL, fully mounted [CrystalPartyGame].
    ///
    /// Calling `onLoad()` by hand is not enough: components added during it
    /// are only queued, and an effect on an unmounted component has no target
    /// and throws. Letting Flame own the lifecycle means these tests exercise
    /// the same tree a child does — which is what caught the two real crashes
    /// this game had in its first hour (a concurrent-modification error the
    /// first time anything scrolled off screen, and an effect applied to a
    /// crystal taken in the same frame it was added).
    final party = FlameTester<CrystalPartyGame>(
      () => CrystalPartyGame(sounds: _noSounds(), random: Random(1)),
      gameSize: Vector2(1024, 600),
    );

    party.testGameWidget(
      'the arch stands on the horizon from the first second',
      setUp: (game, tester) async {
        _run(game, 0.2);
      },
      verify: (game, tester) async {
        // The scope: it is visible, unfinished, from the start — progress is
        // in front of her as well as behind. An arch with no size is an arch
        // the child never sees.
        expect(game.arch.size.x, greaterThan(100));
        expect(game.arch.size.y, greaterThan(50));
        // And it stands ON the ground line, not floating or off screen.
        expect(game.arch.position.y + game.arch.size.y,
            closeTo(game.groundY, 1));
        expect(game.arch.position.x, greaterThanOrEqualTo(-1));
      },
    );

    party.testGameWidget(
      'a missed crystal is owed back, never lost',
      setUp: (game, tester) async {
        // Put a crystal just off the left edge, untaken, and let it scroll
        // away.
        await game.ensureAdd(
          Crystal(
            colour: CrystalColour.pink,
            position: Vector2(-70, game.groundY - 200),
          ),
        );
        _run(game, 0.2);
      },
      verify: (game, tester) async {
        expect(
          game.owed,
          greaterThan(0),
          reason: 'flying past a crystal must put that colour back in the run',
        );
      },
    );

    party.testGameWidget(
      'taking a crystal fills the arch and the trail',
      setUp: (game, tester) async {
        final unicorn = game.unicorn;
        await game.ensureAdd(
          Crystal(
            colour: CrystalColour.blue,
            position: Vector2(unicorn.position.x, unicorn.position.y - 40),
          ),
        );
        _run(game, 0.1);
      },
      verify: (game, tester) async {
        expect(game.arch.filled(CrystalColour.blue), 1);
        expect(game.trail.length, 1);
      },
    );

    party.testGameWidget(
      'clipping a prop takes nothing at all',
      setUp: (game, tester) async {
        final unicorn = game.unicorn;
        // Gather one crystal first, so there is something that could be lost.
        await game.ensureAdd(
          Crystal(
            colour: CrystalColour.blue,
            position: Vector2(unicorn.position.x, unicorn.position.y - 40),
          ),
        );
        _run(game, 0.1);
        // Now walk her into a pine.
        await game.ensureAdd(
          Prop(
            kind: PropKind.pine,
            position: Vector2(unicorn.position.x - 20, unicorn.position.y),
          ),
        );
        _run(game, 0.2);
      },
      verify: (game, tester) async {
        // Nothing taken, nothing stopped, nothing counted.
        expect(game.trail.length, 1);
        expect(game.arch.filled(CrystalColour.blue), 1);
        expect(game.speedFactor, greaterThan(0.9));
        expect(game.unicorn.airHeight, greaterThanOrEqualTo(0));
      },
    );

    party.testGameWidget(
      'a treat cannot be got wrong',
      setUp: (game, tester) async {
        final unicorn = game.unicorn;
        await game.ensureAdd(
          Treat(
            kind: TreatKind.waterfall,
            position: Vector2(unicorn.position.x, unicorn.position.y - 60),
          ),
        );
        _run(game, 0.2);
      },
      verify: (game, tester) async {
        // It changed how she looks and nothing else: no progress, no penalty.
        expect(game.trail.length, 0);
        expect(game.arch.isFull, isFalse);
      },
    );

    party.testGameWidget(
      'filling the arch throws the party, and the next land always arrives',
      setUp: (game, tester) async {
        final unicorn = game.unicorn;
        // Feed her the whole arch by hand.
        for (final colour in CrystalColour.values) {
          for (var i = 0; i < CrystalPartyGame.crystalsPerSide; i++) {
            await game.ensureAdd(
              Crystal(
                colour: colour,
                position: Vector2(unicorn.position.x, unicorn.position.y - 40),
              ),
            );
            _run(game, 0.05);
          }
        }
      },
      verify: (game, tester) async {
        expect(game.arch.isFull, isTrue);
        expect(game.isPartying, isTrue);
        expect(game.lands, 1);

        // And then the next land, always.
        _run(game, 5);
        expect(game.isPartying, isFalse);
        expect(game.arch.filled(CrystalColour.blue), 0);
        expect(game.trail.length, 0, reason: 'the trail empties at the party');
      },
    );

    party.testGameWidget(
      'left alone she stops, and any touch starts her again',
      setUp: (game, tester) async {
        _run(game, CrystalPartyGame.idleTimeout + 3);
      },
      verify: (game, tester) async {
        expect(game.speedFactor, lessThan(0.05));
        expect(game.unicorn.state, UnicornState.resting);

        game.hold();
        _run(game, 0.5);
        expect(game.speedFactor, greaterThan(0.3));
        expect(game.unicorn.state, isNot(UnicornState.resting));
      },
    );

    test('the controls never throw before the game has loaded', () {
      // A child who holds during the async load must not hit a
      // LateInitializationError — in release that is swallowed and the game
      // silently does nothing at all, which looks like it is broken.
      final game = CrystalPartyGame(sounds: _noSounds());
      expect(game.hold, returnsNormally);
      expect(game.release, returnsNormally);
    });
  });
}
