import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_games/games/neil_the_seal/components/neil_painter.dart';
import 'package:little_games/games/neil_the_seal/town.dart';
import 'package:little_games/games/neil_the_seal/world.dart';

const _view = TownView(width: 800, height: 400);

/// The rows of the canvas that Neil actually paints on, drawn the way the game
/// draws him.
///
/// Rendering to pixels rather than reading back a number the code just wrote.
/// Cat Run's jump was green on eleven tests and invisible on screen for exactly
/// that reason: `airHeight` fed the hitbox and never the canvas. A test that
/// asserts on the model proves nothing about what the child sees.
Future<(int top, int bottom, int painted)> _neilRows(NeilWorld world) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  NeilPainter.paint(canvas, _view, world);
  final image = await recorder
      .endRecording()
      .toImage(_view.width.toInt(), _view.height.toInt());
  final data = await image.toByteData();
  final pixels = data!.buffer.asUint8List();

  var top = -1;
  var bottom = -1;
  var painted = 0;
  for (var y = 0; y < _view.height.toInt(); y++) {
    for (var x = 0; x < _view.width.toInt(); x++) {
      // Anything more than faintly drawn. The shadow is very translucent, so
      // this deliberately ignores it and finds his body.
      if (pixels[(y * _view.width.toInt() + x) * 4 + 3] > 90) {
        painted++;
        if (top < 0) top = y;
        bottom = y;
      }
    }
  }
  return (top, bottom, painted);
}

/// Drives [seconds] of game time in real frame-sized steps.
///
/// One big `update()` would step straight over a landing and prove nothing —
/// the same trap Car Trip's tests document.
void _run(NeilWorld world, double seconds, {double step = 1 / 60}) {
  for (var t = 0.0; t < seconds; t += step) {
    world.update(step);
  }
}

/// A spot in [world] that is outside every prop's tap reach — genuinely bare
/// ground.
///
/// Worked out rather than written down, because the reaches are deliberately
/// generous: a spot that looks empty on the layout is very often inside
/// something's reach, which is the whole point of them.
TownSpot _bareGround(NeilWorld world) {
  for (var y = maxY; y >= minY; y -= 0.02) {
    for (var x = minX; x <= maxX; x += 0.02) {
      final where = TownSpot(x, y);
      final clear = world.props.every(
        (p) =>
            !p.kind.isFloppable ||
            townDistance(p.spot, where) > p.kind.tapReach,
      );
      if (clear) return where;
    }
  }
  throw StateError('no bare ground anywhere in this location');
}

/// Sends Neil somewhere and runs until he gets there, giving up after
/// [limit] seconds so a broken arrival fails as a test rather than as a hang.
double _goTo(NeilWorld world, TownSpot where, {double limit = 12}) {
  world.tapAt(where);
  var elapsed = 0.0;
  const step = 1 / 60;
  while (world.state == NeilState.galumphing && elapsed < limit) {
    world.update(step);
    elapsed += step;
  }
  return elapsed;
}

void main() {
  group('the town is a fair place to tap', () {
    test('nothing worth sitting on is crowded up against anything else', () {
      // "Every floppable prop is furniture-sized and well clear of the next
      // one" (the scope). If a location is ever laid out with two things on top
      // of each other, THIS TEST is the warning — not a child who aimed at the
      // car and got the cone (CLAUDE.md §3).
      for (final place in TownPlace.values) {
        final things = place.floppables.toList();
        for (var i = 0; i < things.length; i++) {
          for (var j = i + 1; j < things.length; j++) {
            expect(
              townDistance(things[i].spot, things[j].spot),
              greaterThan(0.15),
              reason: '${place.name}: ${things[i].kind.id} and '
                  '${things[j].kind.id} are too close together',
            );
          }
        }
      }
    });

    test('every prop is a target far past 80x80, even at the back', () {
      // The tap target is the reach, not the art: a cone is small to look at
      // and enormous to aim at. Measured in pixels on the smallest landscape
      // phone this app is tested at, and at the BACK of the town, where the
      // perspective makes everything smallest.
      const view = TownView(width: 667, height: 375);

      for (final kind in PropKind.floppables) {
        // The snap region is an ellipse: town distance weights depth by
        // depthToWidth, and a unit of depth is a different number of pixels
        // from a unit across.
        final across = kind.tapReach * view.width * view.scaleAt(0);
        final deep = kind.tapReach / depthToWidth * view.groundHeight;

        expect(
          across * 2,
          greaterThan(80),
          reason: '${kind.id} is too narrow to aim at',
        );
        expect(
          deep * 2,
          greaterThan(80),
          reason: '${kind.id} is too shallow to aim at',
        );
      }
    });

    test('Neil is a hand-sized target for rubbing', () {
      const view = TownView(width: 667, height: 375);
      final across = NeilPainter.rubReach * view.width * view.scaleAt(0);
      final deep = NeilPainter.rubReach / depthToWidth * view.groundHeight;
      expect(across * 2, greaterThan(80));
      expect(deep * 2, greaterThan(80));
    });

    test('a tap that picked a thing always lands on it', () {
      // Snapping sends him to the prop's own spot, so the reach has to contain
      // zero — but the relationship that matters is that the aim is far more
      // generous than the landing, in that direction and not the other.
      for (final kind in PropKind.floppables) {
        expect(
          kind.tapReach,
          greaterThan(kind.reach),
          reason: '${kind.id} is harder to aim at than to land on',
        );
      }
    });

    test('every location has more to sit on than a nap needs', () {
      // Two things at once: a nap is always reachable from any location, and
      // there is always something left un-sat-on — this game has no set to
      // complete and never says "you found them all" (the scope's *Not this*).
      for (final place in TownPlace.values) {
        expect(
          place.floppables.length,
          greaterThan(NeilWorld.dotsPerNap),
          reason: '${place.name} cannot reach a nap, or has nothing spare',
        );
      }
    });

    test('later locations are prettier, never busier', () {
      // "No difficulty. Later locations are prettier and have more to sit on,
      // never harder, faster or denser." Nothing in this game reads the
      // location to decide how to behave; this pins that the layouts do not
      // quietly ramp either.
      final counts =
          TownPlace.values.map((p) => p.floppables.length).toList();
      expect(counts.reduce(max) - counts.reduce(min), lessThanOrEqualTo(2));
    });

    test('he never wakes up sitting on something', () {
      for (final place in TownPlace.values) {
        for (final placement in place.floppables) {
          expect(
            townDistance(placement.spot, place.start),
            greaterThan(placement.kind.reach),
            reason: '${place.name} opens with him on the '
                '${placement.kind.id}',
          );
        }
      }
    });

    test('he does not wake up lying across the furniture', () {
      // Only *most* of the footprint: he is as long as a car and these towns
      // are busy, so a little overlap with something behind him reads as depth.
      // Lying across the boat does not.
      for (final place in TownPlace.values) {
        for (final placement in place.floppables) {
          final touching =
              (placement.kind.width + NeilPainter.bodyWidth) / 2 * 0.7;
          expect(
            townDistance(placement.spot, place.start),
            greaterThan(touching),
            reason: '${place.name} opens with him draped over the '
                '${placement.kind.id}',
          );
        }
      }
    });

    test('a new location does not open with the town scattering', () {
      // Everything alive keeps clear of Neil from NeilWorld.clearRadius out. If
      // one of them starts inside that, the first thing a child sees in a new
      // place is the whole town running away from him — and "they are all
      // delighted he is here" is the one thing this game may not get wrong.
      for (final place in TownPlace.values) {
        for (final placement in place.layout) {
          if (placement.kind.nature != PropNature.alive) continue;
          expect(
            townDistance(placement.spot, place.start),
            greaterThanOrEqualTo(NeilWorld.clearRadius),
            reason: '${place.name}: the ${placement.kind.id} is standing where '
                'he wakes up',
          );
        }
      }
    });

    test('nothing alive is ever laid out as something to sit on', () {
      for (final place in TownPlace.values) {
        for (final placement in place.layout) {
          if (placement.kind.nature == PropNature.alive) {
            expect(placement.kind.reaction, isNull);
            expect(placement.kind.isFloppable, isFalse);
          }
        }
      }
    });
  });

  group('what the child actually sees', () {
    test('Neil is drawn, where he is', () async {
      final world = NeilWorld(place: TownPlace.beach, random: Random(30));
      final (top, bottom, painted) = await _neilRows(world);

      expect(painted, greaterThan(500), reason: 'he was barely drawn at all');

      // His feet are on the ground at his own spot, and his back is above it.
      final ground = _view.yAt(world.neil).round();
      expect(bottom, greaterThanOrEqualTo(ground - 4));
      expect(top, lessThan(ground));
    });

    test('the heave is drawn, not just calculated', () async {
      // The whole game is a rhythm. If the lurch only ever existed in the
      // model, the child would watch a grey pill slide across the screen.
      final world = NeilWorld(place: TownPlace.beach, random: Random(31));
      world.tapAt(const TownSpot(0.9, 0.5));

      final tops = <int>{};
      for (var i = 0; i < 40; i++) {
        world.update(1 / 60);
        final (top, _, _) = await _neilRows(world);
        tops.add(top);
      }
      // He rises and falls through the heave rather than holding one height.
      expect(
        tops.reduce(max) - tops.reduce(min),
        greaterThan(3),
        reason: 'he never left the ground; the heave is invisible',
      );
    });

    test('the landing wobble is drawn', () async {
      final world = NeilWorld(place: TownPlace.beach, random: Random(32));
      _goTo(world, _bareGround(world));

      final heights = <int>[];
      for (var i = 0; i < 30; i++) {
        final (top, bottom, _) = await _neilRows(world);
        heights.add(bottom - top);
        world.update(1 / 60);
      }
      // He squashes on impact and springs back out — the beat every single tap
      // in this game ends on.
      expect(
        heights.reduce(max) - heights.reduce(min),
        greaterThan(3),
        reason: 'the flop is invisible',
      );
    });

    test('a squashed prop is drawn shorter, and a springing one taller', () {
      // The squash reaches the canvas through heightFactor. Nothing else scales
      // a prop, so this is the number the painter uses.
      final world = NeilWorld(place: TownPlace.mainStreet, random: Random(33));
      final cone = world.props.firstWhere((p) => p.kind.id == 'cone');
      expect(cone.heightFactor, 1);

      _goTo(world, cone.spot);
      _run(world, 0.4);
      expect(cone.heightFactor, lessThan(0.3), reason: 'it did not go flat');

      world.tapAt(_bareGround(world));
      var tallest = 0.0;
      for (var t = 0.0; t < NeilWorld.springSettle; t += 1 / 60) {
        world.update(1 / 60);
        tallest = max(tallest, cone.heightFactor);
      }
      expect(tallest, greaterThan(1.0), reason: 'it did not boing back');
    });
  });

  group('how Neil moves', () {
    test('the heave averages out to the speed it says it does', () {
      // `surgeMean` is worked out analytically so that `galumphSpeed` means the
      // speed he really averages. If the rhythm is ever reshaped and the mean
      // is not updated with it, he silently gets faster or slower — which is
      // the one thing in this game a child would notice first.
      var sum = 0.0;
      const steps = 20000;
      for (var i = 0; i < steps; i++) {
        sum += NeilWorld.surgeAt((i + 0.5) / steps);
      }
      expect(sum / steps, closeTo(NeilWorld.surgeMean, 0.001));
    });

    test('he crosses the screen in about four seconds', () {
      // The scope's starting point, and an open question only a child can
      // settle. Pinned so that changing it is a deliberate act rather than a
      // drift — and loosely, because the exact number is not the point.
      //
      // Measured as a speed and converted to a full screen width, because he
      // cannot actually walk to either edge (see minX/maxX). The band is wide
      // at the quick end on purpose: every trip restarts the rhythm on a heave
      // so that a tap produces movement immediately, which makes a short trip
      // average a little faster than a long one. That is the right trade — a
      // seal who began each trip coasting would read as not having heard.
      final world = NeilWorld(random: Random(1));
      world.tapAt(const TownSpot(minX, 0.5));
      _run(world, 6);

      final start = world.neil;
      final seconds = _goTo(world, const TownSpot(maxX, 0.5));
      final travelled = townDistance(start, world.neil);
      expect(travelled, greaterThan(0.2), reason: 'he barely moved');

      final crossing = 1.0 / (travelled / seconds);
      expect(crossing, greaterThan(3.2), reason: 'too quick to be enormous');
      expect(crossing, lessThan(4.8), reason: 'too slow to stay with');
    });

    test('all of him stays on screen, wherever he is sent', () {
      // Half his own length, against the walkable box. If he can reach the edge
      // the screen cuts him in half, and the thing the child is watching is the
      // thing that got clipped.
      expect(minX, greaterThan(NeilPainter.bodyWidth / 2));
      expect(1 - maxX, greaterThan(NeilPainter.bodyWidth / 2));
    });

    test('a tap on a thing at the very edge still lands on it', () {
      // Props sit further out than Neil can walk. He gets as close as the town
      // lets him — which has to still be inside the thing's reach, or a child
      // taps the bin at the end of the street and watches him stop short of it.
      for (final place in TownPlace.values) {
        for (final placement in place.floppables) {
          final reachable = placement.spot.clamped;
          expect(
            townDistance(reachable, placement.spot),
            lessThan(placement.kind.reach),
            reason: '${place.name}: he cannot get onto the '
                '${placement.kind.id} at the edge',
          );
        }
      }
    });

    test('he can never leave the town', () {
      final world = NeilWorld(random: Random(2));
      // Tapped well outside it, repeatedly and from every direction.
      for (final corner in const [
        TownSpot(-5, -5),
        TownSpot(5, -5),
        TownSpot(-5, 5),
        TownSpot(5, 5),
      ]) {
        world.tapAt(corner);
        _run(world, 6);
        expect(world.neil.x, inInclusiveRange(minX, maxX));
        expect(world.neil.y, inInclusiveRange(minY, maxY));
      }
    });

    test('a tap while he is walking replaces the old one in the same frame',
        () {
      final world = NeilWorld(random: Random(3));
      world.tapAt(const TownSpot(0.9, 0.85));
      _run(world, 0.5);
      final wasHeading = world.target;

      world.tapAt(const TownSpot(0.1, 0.2));
      expect(world.target, isNot(equals(wasHeading)));
      expect(world.state, NeilState.galumphing);
      // And he actually gets there, rather than finishing the old trip first.
      _run(world, 8);
      expect(world.state, NeilState.flopped);
      expect(townDistance(world.neil, const TownSpot(0.1, 0.2).clamped),
          lessThan(0.2));
    });
  });

  group('there is no dead tap', () {
    test('a tap on bare ground is still a flop, a flump and a landing', () {
      final world = NeilWorld(place: TownPlace.beach, random: Random(4));
      Prop? landedOn;
      var flops = 0;
      world.onFlop = (onto) {
        flops++;
        landedOn = onto;
      };

      _goTo(world, _bareGround(world));

      expect(flops, 1, reason: 'an empty patch must still be arrived at');
      expect(landedOn, isNull);
      expect(world.state, NeilState.flopped);
      // And the landing is animated, which is what the child actually sees.
      expect(world.flopT, lessThan(NeilWorld.flopSeconds));
    });

    test('every tap anywhere on the map sends him somewhere', () {
      // A sweep of the whole town, including the parts behind the horizon and
      // off the edges. Not one of them may be ignored — and the sweep runs long
      // enough to fill the shells several times over, so it covers the nap as
      // well, which is the one moment he cannot be sent anywhere.
      final world = NeilWorld(random: Random(5));
      var answers = 0;
      world.onAnswer = (_) => answers++;

      for (var x = -0.2; x <= 1.2; x += 0.1) {
        for (var y = -0.2; y <= 1.2; y += 0.1) {
          final napping = world.state == NeilState.napping;
          final before = answers;
          world.tapAt(TownSpot(x, y));

          if (napping) {
            // Asleep under the confetti: the town he has gathered round him
            // answers instead. Still not nothing.
            expect(
              answers,
              greaterThan(before),
              reason: 'a tap at (\$x, \$y) during the nap did nothing',
            );
          } else {
            expect(
              world.state,
              NeilState.galumphing,
              reason: 'a tap at (\$x, \$y) did nothing',
            );
          }
          _run(world, 0.1);
        }
      }
    });

    test('a near-miss tap on anything is never a miss', () {
      // The reaches are generous in one direction on purpose: a five-year-old
      // who aimed at the cone and landed a finger's width off has to get the
      // cone. Every floppable thing in every location, nudged in four
      // directions, has to end with him sitting on something.
      for (final place in TownPlace.values) {
        for (final placement in place.floppables) {
          for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
            final world = NeilWorld(place: place, random: Random(26));
            final nudge = placement.kind.tapReach * 0.4;
            _goTo(
              world,
              TownSpot(
                placement.x + dx * nudge,
                placement.y + dy * nudge / depthToWidth,
              ),
            );
            expect(
              world.sittingOn,
              isNotNull,
              reason: '\${place.name}: a near miss on \${placement.kind.id} '
                  'landed on nothing',
            );
          }
        }
      }
    });

    test('tapping a car sends him to that car, with no aim needed', () {
      final world = NeilWorld(place: TownPlace.mainStreet, random: Random(6));
      final car = world.props.firstWhere((p) => p.kind.id == 'car');

      // A sloppy aim, well off the car's own middle — which is where a
      // five-year-old's finger actually lands.
      final sloppy = TownSpot(
        car.spot.x + car.kind.tapReach * 0.5,
        car.spot.y,
      );
      _goTo(world, sloppy);

      expect(world.sittingOn, same(car));
      expect(car.occupied, isTrue);
    });
  });

  group('nothing is ever damaged', () {
    test('a prop springs back past its resting height and settles exactly', () {
      final world = NeilWorld(place: TownPlace.mainStreet, random: Random(7));
      final cone = world.props.firstWhere((p) => p.kind.id == 'cone');

      _goTo(world, cone.spot);
      _run(world, 0.5);
      expect(cone.squash, greaterThan(0.8), reason: 'he did not squash it');

      // He moves off. The springback is what says "nothing is broken" — and it
      // has to overshoot, because a thing that eases back to exactly its old
      // shape reads as being repaired, not as being bouncy.
      world.tapAt(_bareGround(world));
      var overshot = false;
      for (var t = 0.0; t < NeilWorld.springSettle; t += 1 / 60) {
        world.update(1 / 60);
        if (cone.squash < -0.05) overshot = true;
      }
      expect(overshot, isTrue, reason: 'the springback did not bounce');

      _run(world, 0.5);
      expect(cone.squash, 0, reason: 'nothing may be left squashed, ever');
      expect(cone.heightFactor, 1);
    });

    test('a whole town walked over is left exactly as it was found', () {
      final world = NeilWorld(place: TownPlace.caravanPark, random: Random(8));
      for (final prop in [...world.props.where((p) => p.kind.isFloppable)]) {
        _goTo(world, prop.spot);
        _run(world, 0.4);
        if (world.state == NeilState.napping) break;
      }
      // Off everything, and left alone long enough for every spring to settle.
      world.tapAt(_bareGround(world));
      _run(world, 4);

      for (final prop in world.props) {
        expect(prop.squash, 0, reason: '${prop.kind.id} was left squashed');
        expect(prop.occupied, isFalse);
      }
    });
  });

  group('nothing alive is ever squashed', () {
    test('however he is driven, he never lands on anything alive', () {
      // The rule this game shares with Car Trip: driving into an animal is
      // funny in a game and appalling in life, and a five-year-old does not
      // hold those apart. So the game never offers the choice — the wallaby is
      // always somewhere else by the time a child has decided to aim at it.
      //
      // Driven the worst possible way: aimed at a living thing, over and over,
      // for a minute in every location, which is exactly what a determined
      // five-year-old does. Checked against the props the world actually holds
      // on each frame, so a nap swapping the town out mid-chase is covered too.
      const floor = NeilPainter.bodyWidth / 2;

      for (final place in TownPlace.values) {
        final world = NeilWorld(place: place, random: Random(9));
        final aim = Random(place.index + 1);

        for (var frame = 0; frame < 4000; frame++) {
          if (frame % 12 == 0) {
            final alive = world.props
                .where((p) => p.kind.nature == PropNature.alive)
                .toList();
            world.tapAt(alive[aim.nextInt(alive.length)].spot);
          }
          world.update(1 / 60);

          for (final prop in world.props) {
            if (prop.kind.nature != PropNature.alive) continue;
            final away = townDistance(world.neil, prop.spot);
            // Checked by hand rather than through expect(): this runs a
            // quarter of a million times and expect() is far too slow for it.
            if (away <= floor) {
              fail('${place.name}: Neil reached the ${prop.kind.id} '
                  '(${away.toStringAsFixed(3)} away, floor $floor)');
            }
          }
        }
      }
    });

    test('something alive can always outrun him', () {
      // The guarantee behind the test above, stated as a number: whatever the
      // rhythm does, the top of his heave is slower than a creature getting
      // clear.
      expect(NeilWorld.clearSpeed, greaterThan(NeilWorld.maxSpeed));
    });

    test('creatures start moving before he even sets off', () {
      // They watch his destination, not just him, so they are already out of
      // the way rather than scrambling at the last moment.
      final world = NeilWorld(place: TownPlace.footyOval, random: Random(10));
      final creature =
          world.props.firstWhere((p) => p.kind.nature == PropNature.alive);
      final was = creature.spot;

      world.tapAt(creature.spot);
      world.update(1 / 60);
      expect(townDistance(creature.spot, was), greaterThan(0));
    });
  });

  group('the shells', () {
    test('a new thing fills one, and the same thing again does not', () {
      final world = NeilWorld(place: TownPlace.beach, random: Random(11));
      final boat = world.props.firstWhere((p) => p.kind.id == 'boat');

      _goTo(world, boat.spot);
      expect(world.dotsFilled, 1);

      // Away to bare ground, and back to the same boat. Just as much fun, and
      // no shell — and nothing anywhere tells the child it was "already done".
      _goTo(world, _bareGround(world));
      _goTo(world, boat.spot);
      expect(world.dotsFilled, 1);
      expect(boat.occupied, isTrue);
    });

    test('the count never goes down while he is playing', () {
      final world = NeilWorld(place: TownPlace.boatRamp, random: Random(12));
      var lowest = 0;
      for (final prop in [...world.props.where((p) => p.kind.isFloppable)]) {
        _goTo(world, prop.spot);
        expect(world.dotsFilled, greaterThanOrEqualTo(lowest));
        lowest = world.dotsFilled;
        if (world.state == NeilState.napping) break;
      }
    });
  });

  group('the nap', () {
    test('fills, plays its beats in order, and wakes up somewhere new', () {
      final world = NeilWorld(place: TownPlace.beach, random: Random(13));
      final beats = <String>[];
      // Block bodies, not arrows: inside a cascade an arrow body swallows the
      // cascades that follow it.
      world
        ..onNapBegin = () {
          beats.add('yawn');
        }
        ..onSnore = () {
          beats.add('snore');
        }
        ..onCelebrate = () {
          beats.add('celebrate');
        }
        ..onWakeElsewhere = (p) {
          beats.add('wake ${p.name}');
        };

      for (final prop in [...world.props.where((p) => p.kind.isFloppable)]) {
        _goTo(world, prop.spot);
        if (world.state == NeilState.napping) break;
      }

      expect(world.dotsFilled, NeilWorld.dotsPerNap);
      expect(world.state, NeilState.napping);

      _run(world, NeilWorld.napSeconds + 0.5);

      expect(beats, ['yawn', 'snore', 'celebrate', 'wake boatRamp']);
      expect(world.place, TownPlace.boatRamp);
      expect(world.state, NeilState.flopped);
      // Everything fresh, nothing carried over, and no count of anything.
      expect(world.dotsFilled, 0);
      expect(world.props.every((p) => !p.visited), isTrue);
      expect(world.unvisitedFloppables, world.place.floppables.length);
    });

    test('it ends by itself, so there is nothing to dismiss', () {
      final world = NeilWorld(place: TownPlace.footyOval, random: Random(14));
      for (final prop in [...world.props.where((p) => p.kind.isFloppable)]) {
        _goTo(world, prop.spot);
        if (world.state == NeilState.napping) break;
      }
      // Not touched once from here on.
      _run(world, NeilWorld.napSeconds + 1);
      expect(world.state, NeilState.flopped);
    });

    test('a tap during the nap still makes the town answer', () {
      // Even here there is nowhere on screen that does nothing: he is asleep,
      // so the town gathered round him answers instead.
      final world = NeilWorld(place: TownPlace.mainStreet, random: Random(15));
      for (final prop in [...world.props.where((p) => p.kind.isFloppable)]) {
        _goTo(world, prop.spot);
        if (world.state == NeilState.napping) break;
      }

      var answers = 0;
      world.onAnswer = (_) => answers++;
      world.tapAt(const TownSpot(0.5, 0.5));
      expect(answers, 1);
    });

    test('the loop goes round forever with no last location', () {
      var place = TownPlace.values.first;
      for (var i = 0; i < TownPlace.values.length; i++) {
        place = place.next;
      }
      expect(place, TownPlace.values.first);
    });
  });

  group('the bellow', () {
    test('the whole town answers, one voice after another', () {
      final world = NeilWorld(place: TownPlace.caravanPark, random: Random(16));
      final answered = <String>[];
      world.onAnswer = (prop) => answered.add(prop.kind.id);

      world.bellow();
      expect(answered, isEmpty, reason: 'the round must arrive, not land');

      _run(world, 6);
      final voices =
          world.props.where((p) => !p.kind.isFloppable).length;
      expect(answered.length, voices, reason: 'somebody did not answer');
    });

    test('the order is different every time', () {
      final world = NeilWorld(place: TownPlace.footyOval, random: Random(17));
      final rounds = <List<String>>[];
      for (var i = 0; i < 3; i++) {
        final answered = <String>[];
        world.onAnswer = (prop) => answered.add(prop.kind.id);
        world.bellow();
        _run(world, 6);
        rounds.add(answered);
      }
      expect(rounds[0], isNot(equals(rounds[1])));
      expect(rounds[1], isNot(equals(rounds[2])));
    });

    test('it does nothing whatsoever to the game', () {
      // The entire point of it. No dot, no progress, nothing moved, nothing
      // squashed — it is a toy, and pressing it twenty times is a perfectly
      // good way to play.
      final world = NeilWorld(place: TownPlace.beach, random: Random(18));
      final where = world.neil;
      final dots = world.dotsFilled;
      for (var i = 0; i < 20; i++) {
        world.bellow();
        _run(world, 0.3);
      }
      expect(world.neil, isNot(isNull));
      expect(world.neil.x, where.x);
      expect(world.neil.y, where.y);
      expect(world.dotsFilled, dots);
      expect(world.props.every((p) => p.squash == 0), isTrue);
    });

    test('pressing it again restarts the round rather than stacking it up', () {
      final world = NeilWorld(place: TownPlace.beach, random: Random(19));
      var answers = 0;
      world.onAnswer = (_) => answers++;
      final voices = world.props.where((p) => !p.kind.isFloppable).length;

      world.bellow();
      _run(world, 0.5);
      world.bellow();
      _run(world, 6);

      // Some of the first round landed before the second started; the rest of
      // it was replaced, not queued behind it.
      expect(answers, lessThan(voices * 2));
      expect(answers, greaterThanOrEqualTo(voices));
    });
  });

  group('waiting looks like something', () {
    test('left alone he falls asleep by himself', () {
      final world = NeilWorld(random: Random(20));
      var dozed = 0;
      world.onDoze = () => dozed++;

      _run(world, NeilWorld.idleBeforeSleep - 1);
      expect(world.state, NeilState.flopped);

      _run(world, 2);
      expect(world.state, NeilState.dozing);
      expect(dozed, 1);
    });

    test('any tap at all wakes him, and he sets off', () {
      final world = NeilWorld(random: Random(21));
      var woke = 0;
      world.onWake = () => woke++;
      _run(world, NeilWorld.idleBeforeSleep + 1);
      expect(world.state, NeilState.dozing);

      world.tapAt(const TownSpot(0.5, 0.8));
      expect(woke, 1);
      expect(world.state, NeilState.galumphing);
      expect(world.dozeT, isNull);
    });

    test('rubbing him wakes him too, and never fills anything', () {
      final world = NeilWorld(random: Random(22));
      _run(world, NeilWorld.idleBeforeSleep + 1);

      world.rub();
      expect(world.state, NeilState.flopped);
      expect(world.rubbing, greaterThan(0));
      expect(world.dotsFilled, 0);
    });
  });

  group('rubbing him', () {
    test('it delights him, repeatedly, and changes nothing else', () {
      final world = NeilWorld(place: TownPlace.beach, random: Random(23));
      var delights = 0;
      world.onRubDelight = () => delights++;

      final where = world.neil;
      for (var i = 0; i < 180; i++) {
        world.rub();
        world.update(1 / 60);
      }

      expect(delights, greaterThan(2), reason: 'he never enjoyed it');
      expect(delights, lessThan(30), reason: 'it fired every frame');
      expect(world.dotsFilled, 0);
      expect(world.neil.x, where.x);
    });

    test('it does not interrupt a trip he is already on', () {
      // Rubbing him on the way somewhere is a perfectly good thing to want to
      // do, and stopping him for it would feel like the control being taken
      // away.
      final world = NeilWorld(place: TownPlace.beach, random: Random(24));
      world.tapAt(const TownSpot(0.9, 0.3));
      final heading = world.target;
      _run(world, 0.4);

      world.rub();
      expect(world.state, NeilState.galumphing);
      expect(world.target, heading);
    });

    test('the wriggle outlasts the finger, then fades away', () {
      final world = NeilWorld(random: Random(25));
      world.rub();
      expect(world.wriggle, 1);
      _run(world, 0.3);
      expect(world.wriggle, greaterThan(0), reason: 'he snapped back too fast');
      _run(world, 2);
      expect(world.wriggle, 0);
      expect(world.rubbing, 0);
    });
  });
}
