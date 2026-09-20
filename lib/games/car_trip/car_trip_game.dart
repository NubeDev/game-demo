import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../shared/celebration.dart';
import '../../shared/kid_haptics.dart';
import '../../shared/kid_sounds.dart';
import 'components/car.dart';
import 'components/progress_dots.dart';
import 'components/road_view.dart';
import 'components/traffic.dart';
import 'road.dart';
import 'world.dart';

/// Car Trip.
///
/// A car drives itself down a road forever. The child puts a thumb on the
/// screen and the car follows it. Animals waiting at the kerb hop in as the car
/// pulls alongside; a full car means the road has arrived somewhere, and a new
/// road starts.
///
/// ## The one hard problem in this game
///
/// **Steering is the first thing in this app a child can genuinely be bad at**,
/// and CLAUDE.md §3 forbids failure outright. It is resolved by making the road
/// wide, the verges drivable ([driveableLateral]) and the things on it sparse:
/// *a child who holds their thumb still in the middle of the screen drives the
/// whole road safely, forever*, and the worst that can happen to them is the
/// occasional comedy boing off a cone.
///
/// Picking a passenger up is the one thing that does ask for a steer, and it
/// asks for as little as possible: the animal walks down to the kerb itself
/// (see [_moveCreatures]), so the child only has to lean a fraction of the
/// road's width toward it. A test pins exactly how little that is, because it
/// is the difference between a game that teaches steering and one that demands
/// it.
///
/// The rest of the resolution is the same trick Cat Run plays with its fences —
/// keep the obstacle, delete the loss. Clipping a cone is a wobble and a boing,
/// the trip carries on, and nothing is counted.
///
/// ## Everything that keeps it fair
///
///  * **One speed forever** ([CarTripWorld.speed]). Nothing here reads elapsed
///    time or distance to decide how hard to be. There is no difficulty ramp.
///  * **A floor on the gap between things** ([CarTripWorld.minGap]), and only
///    ever one thing at a distance, so the road is never a wall.
///  * **Nothing alive can be hit** ([_stepAside]). The ducks move first.
///  * **A passenger driven past comes back** ([CarTripWorld.missed]).
///  * **Lift the thumb and the world stops** ([_updateSpeed]), so the child can
///    look at the cows.
class CarTripGame extends FlameGame {
  CarTripGame({required this.sounds, Random? random})
    : _world = CarTripWorld(random: random),
      _random = random ?? Random();

  final KidSounds sounds;
  final CarTripWorld _world;
  final Random _random;

  /// How many passengers make a trip. Six is about forty seconds of driving —
  /// long enough that arriving means something, short enough that a child who
  /// wanders off mid-trip has still seen one.
  static const int passengersPerTrip = 6;

  /// How long after the thumb lifts before the car starts slowing. A brief
  /// re-grip must not stutter the world.
  static const double liftGrace = 0.35;

  /// How long the car takes to coast to a stop, and to get going again.
  static const double _coastSeconds = 1.6;
  static const double _pullAwaySeconds = 0.7;

  /// How much slower the grass is than the tarmac. Small on purpose: the verge
  /// is texture, not a penalty (CLAUDE.md §3 — nothing punishes).
  static const double vergeSpeedFactor = 0.86;

  /// How close, in depth, something has to be for the car to interact with it.
  ///
  /// This is the window at a healthy frame rate. It is NOT the whole story:
  /// see [_interact], which widens it by however far the car moved this frame.
  static const double _reachDepth = 55;

  /// How far ahead something alive notices the car and starts moving aside.
  /// At [CarTripWorld.speed] this is about two seconds of warning.
  static const double stepAsideDepth = 420;

  /// How fast something alive gets out of the way. Faster than the car can
  /// steer ([Car.maxLateralSpeed]), so it can always get clear — a child who
  /// chases a duck watches it wander off into the field, and never catches it.
  static const double _stepAsideSpeed = 3.2;

  // NOT `late final`: these are built in the async onLoad(), and the steering
  // pad and the horn are live from the moment the screen paints. A thumb that
  // arrives in that gap would hit a LateInitializationError, which in a release
  // build is swallowed inside the gesture callback — so the controls would do
  // nothing at all, silently, and the game would look broken. Nullable plus a
  // guard in every control is the honest version. (The same trap as Cat Run's.)
  RoadView? _road;
  Traffic? _traffic;
  Car? _car;
  ProgressDots? _dots;
  Celebration? _celebration;

  /// How far the trip has come, in world pixels.
  double _scrolled = 0;

  /// 0..1 — how much of full speed the road is moving at. Only ever driven by
  /// the thumb and the verge; never by difficulty.
  double _speedFactor = 0;
  double _vergeFactor = 1;

  /// Whether a thumb is on the steering area right now, and for how long it
  /// has not been.
  bool _thumbDown = false;
  double _sinceLift = 0;

  /// How many times the horn has been pressed, so the cue alternates.
  int _hornPresses = 0;

  /// How many places the trip has arrived at. Only used to pick the next one.
  int _arrivals = 0;

  /// Paused only while the confetti plays.
  bool _placing = true;

  @override
  Color backgroundColor() => Destination.farm.skyBottom;

  /// The projection this screen is using. The game logic never needs it — every
  /// rule is in road units — but the steering has to turn a thumb position in
  /// pixels into one.
  Perspective get view => Perspective(width: size.x, height: size.y);

  @override
  Future<void> onLoad() async {
    final road = RoadView(random: _random);
    _road = road;
    add(road);

    final traffic = Traffic();
    _traffic = traffic;
    add(traffic);

    final car = Car(random: _random);
    _car = car;
    add(car);

    final dots = ProgressDots(
      total: passengersPerTrip,
      // Top-left, clear of the home button (top-right) and of the whole lower
      // half, which is the steering area.
      position: Vector2(24, 24),
    );
    _dots = dots;
    add(dots);

    final celebration = Celebration();
    _celebration = celebration;
    add(celebration);

    // NO Rive character yet. A shape-drawn car does everything this game needs;
    // `lib/shared/rive_character.dart` is ready if real art arrives, and the
    // scope's open question about a face in the window is still open.
  }

  @override
  void update(double dt) {
    super.update(dt);

    final car = _car;
    final road = _road;
    final traffic = _traffic;
    if (car == null || road == null || traffic == null) return;

    _updateSpeed(dt, car);

    final distance = CarTripWorld.speed * _speedFactor * _vergeFactor * dt;
    _scrolled += distance;
    road.advance(distance);
    traffic.scrolled = _scrolled;

    if (_placing) _placeThings(traffic);
    _moveCreatures(traffic, car, dt);
    _interact(traffic, car, distance);
    _cull(traffic);
  }

  /// The thumb is the throttle as well as the wheel: lift it and the car coasts
  /// to a stop where it is, and the world stops with it.
  ///
  /// This is what gives the child back the control a scrolling world takes away
  /// (CLAUDE.md §3). It is not a pause screen, there is nothing to dismiss, and
  /// the car never moves anywhere the child did not put it — it simply stops.
  void _updateSpeed(double dt, Car car) {
    if (_thumbDown) {
      _sinceLift = 0;
      _speedFactor = min(1, _speedFactor + dt / _pullAwaySeconds);
    } else {
      _sinceLift += dt;
      if (_sinceLift > liftGrace) {
        _speedFactor = max(0, _speedFactor - dt / _coastSeconds);
      }
    }

    // The grass is slower, eased in so crossing the kerb is a change of feel
    // rather than a jolt.
    final target = car.onVerge ? vergeSpeedFactor : 1.0;
    _vergeFactor += (target - _vergeFactor).clamp(-dt * 2, dt * 2);
  }

  void _placeThings(Traffic traffic) {
    // Place everything that has come due this frame, not just one thing: three
    // streams share the road (things, passengers, field scenery) and one per
    // frame would let them fall behind each other at speed.
    for (var i = 0; i < 4; i++) {
      final placed = _world.next(_scrolled);
      if (placed == null) return;
      traffic.things.add(
        RoadThing(
          kind: placed.kind,
          distance: placed.distance,
          lateral: placed.lateral,
        ),
      );
    }
  }

  /// Everything alive moves itself. The car never has to.
  ///
  /// Two behaviours, and both of them exist so that the child's aim matters as
  /// little as possible:
  ///
  ///  * **Nothing alive is ever hit.** The ducks and the hedgehog notice the
  ///    car [stepAsideDepth] ahead and waddle clear — away from wherever the
  ///    car actually is, faster than the car can steer ([_stepAsideSpeed]), and
  ///    out into the field if they are chased. There is deliberately no branch
  ///    anywhere in this file that lets a living thing be collided with:
  ///    driving into an animal is funny in a game and appalling in life, and a
  ///    five-year-old does not hold those apart (the scope's *Kid-rules
  ///    impact*).
  ///  * **A waiting passenger comes to meet the car.** It sees the car coming
  ///    and steps down to the edge of the tarmac ([_kerbLateral]), which turns
  ///    "pull up alongside" from a piece of aim into a nudge of the thumb
  ///    toward the animal. It never steps INTO the road: the child still has to
  ///    lean that way, or the steering would mean nothing at all.
  void _moveCreatures(Traffic traffic, Car car, double dt) {
    for (final thing in traffic.things) {
      final depth = thing.depthAt(_scrolled);

      if (thing.kind.stepsAsideFromCar) {
        if (depth > stepAsideDepth || depth < -120) continue;
        // Away from the car, and out into the field if need be.
        final side = thing.lateral >= car.lateral ? 1.0 : -1.0;
        final want = (car.lateral + side * 1.1).clamp(-2.4, 2.4);
        _walk(thing, want, _stepAsideSpeed * dt);
        thing.react();
        continue;
      }

      if (thing.kind.action == RoadAction.pickUp && !thing.spent) {
        if (depth > _noticeDepth || depth < -40) continue;
        final side = thing.lateral >= 0 ? 1.0 : -1.0;
        _walk(thing, side * _kerbLateral, _stepAsideSpeed * 0.4 * dt);
      }
    }
  }

  /// Move a creature toward [want] at no more than [step], so everything alive
  /// walks rather than teleports.
  void _walk(RoadThing thing, double want, double step) =>
      thing.lateral += (want - thing.lateral).clamp(-step, step);

  /// How far ahead a waiting passenger notices the car and steps down to the
  /// kerb.
  static const double _noticeDepth = 620;

  /// Where a waiting passenger ends up: on the edge of the tarmac, not in the
  /// road. With [Car.halfWidth] and the passengers' generous reach, this means
  /// a child only has to steer a little way off the centre line to collect one
  /// — see the test that pins exactly how little.
  static const double _kerbLateral = 0.95;

  /// [travelled] is how far the car moved this frame. The window has to be at
  /// least that wide, or a thing can pass clean through it between two frames
  /// and never be noticed.
  ///
  /// This is not a theoretical worry: on a slow tablet — the hand-me-down
  /// hardware a five-year-old actually gets — a 550ms frame moves the car
  /// further than the whole fixed window, and a passenger the child steered to
  /// correctly is silently missed. Missing a passenger you aimed at reads as
  /// "the game ignored me", which is the failure CLAUDE.md §3 rules out.
  /// The child's aim must decide what happens, never the frame rate.
  void _interact(Traffic traffic, Car car, double travelled) {
    // Half the sweep each side, plus the static window.
    final reach = _reachDepth + travelled / 2;

    for (final thing in traffic.things) {
      if (thing.spent) continue;
      final kind = thing.kind;
      if (kind.action == RoadAction.waver || kind.stepsAsideFromCar) continue;

      final depth = thing.depthAt(_scrolled);
      if (depth > reach || depth < -reach) continue;
      if ((thing.lateral - car.lateral).abs() > kind.reach + Car.halfWidth) {
        continue;
      }

      switch (kind.action) {
        case RoadAction.driveThrough:
          _onDriveThrough(thing, car);
        case RoadAction.nudge:
          _onNudge(thing, car);
        case RoadAction.pickUp:
          _onPickUp(thing, car);
        case RoadAction.stepsAside:
        case RoadAction.waver:
          break; // unreachable — both are filtered out above
      }
    }
  }

  void _onDriveThrough(RoadThing thing, Car car) {
    thing.spent = true;
    thing.react();

    switch (thing.kind.effect) {
      case ThroughEffect.splash:
      case ThroughEffect.scatter:
        car.splash();
        sounds.pop(progress: 0.15);
        KidHaptics.pop();
      case ThroughEffect.muddy:
        car.muddy = 1;
        car.splash();
        // No sound for getting muddy beyond the splash: being filthy is not an
        // event, it is a look.
        sounds.pop(progress: 0.1);
      case ThroughEffect.repaint:
        car.repaint();
        sounds.pop(progress: 0.8);
        KidHaptics.pop();
      case ThroughEffect.wash:
        car.sparkle();
        sounds.pop(progress: 0.8);
        KidHaptics.pop();
      case null:
        break;
    }
  }

  /// Clipped a cone. The whole of what happens: a wobble, a boing, and it
  /// tumbles off into the grass.
  ///
  /// Note what is NOT here — no damage, no spin-out, no stop, no progress
  /// removed, no sad noise, and **no haptic**: a physical jolt after a mistake
  /// is punishment, however small (see KidHaptics).
  void _onNudge(RoadThing thing, Car car) {
    thing.spent = true;
    thing.react(away: thing.lateral >= car.lateral ? 1 : -1);
    car.bump();
    sounds.wobble();
    _celebration?.puff(
      Vector2(view.xAt(thing.lateral, 0), view.carY - 20),
      pieces: 5,
    );
  }

  void _onPickUp(RoadThing thing, Car car) {
    thing.spent = true;
    thing.react();
    car.pickUp(thing.kind);
    _dots?.filled = car.aboard.length;

    // The rising chime — one note higher per passenger, so the sound itself
    // says "nearly there" to a child who cannot read the dots.
    sounds.pop(progress: car.aboard.length / passengersPerTrip);
    KidHaptics.pop();

    if (car.aboard.length >= passengersPerTrip) _arrive();
  }

  void _cull(Traffic traffic) {
    traffic.things.removeWhere((thing) {
      if (thing.depthAt(_scrolled) > -260) return false;
      // A passenger who was driven past is owed: the same animal will be
      // waiting further up the road, so nothing is ever missed for good.
      if (!thing.spent) _world.missed(thing.kind);
      return true;
    });
  }

  /// Arrived somewhere. Everyone piles out, the place changes, and the road
  /// carries on — there is no last trip.
  void _arrive() {
    final car = _car;
    final road = _road;
    if (car == null || road == null) return;

    sounds.celebrate();
    KidHaptics.celebrate();
    _celebration?.burst(size);
    _arrivals++;

    car.dropOff();
    // Empties in the same frame the confetti arrives, so the row is never seen
    // draining away (the same rule as every other progress row here).
    _dots?.filled = 0;
    road.changeTo(road.place.next);

    // Hold off placing new things briefly, so the confetti is the thing on
    // screen. The car keeps driving: stopping to acknowledge success breaks the
    // rhythm, and there is no "well done" screen to dismiss.
    _placing = false;
    add(
      TimerComponent(
        period: 1.8,
        removeOnFinish: true,
        onTick: () => _placing = true,
      ),
    );
  }

  // --- the controls -------------------------------------------------------

  /// A thumb went down, or moved, at [screenX] pixels across the screen.
  ///
  /// The car goes where the thumb is, directly: no wheel, no buttons, no
  /// relative dragging. Direct is the largest possible target and needs no
  /// discovery — the child's own hand is the control (the scope's *What*).
  ///
  /// Safe before the game has finished loading; see the note on [_car].
  void steerToScreenX(double screenX) {
    _thumbDown = true;
    final car = _car;
    if (car == null || size.x <= 0) return;
    car.steerTo((screenX - size.x / 2) / view.roadHalfWidth);
  }

  /// The thumb came off. The car coasts to a stop; nothing else changes.
  void thumbUp() => _thumbDown = false;

  /// The horn. It does nothing to the game on purpose: it is a toy, not a
  /// control, and it is probably the most-pressed thing in the app.
  void horn() {
    sounds.horn(press: _hornPresses++);
    KidHaptics.tap();

    // Everything out in the fields waves back. This is the entire payoff, and
    // it is why the wavers exist at all.
    final traffic = _traffic;
    if (traffic == null) return;
    for (final thing in traffic.things) {
      if (thing.kind.action != RoadAction.waver) continue;
      final depth = thing.depthAt(_scrolled);
      if (depth < -120 || depth > Perspective.viewDepth) continue;
      thing.wave();
    }
  }

  // --- for the tests ------------------------------------------------------

  /// Only valid after [onLoad]; every test that uses these awaits it.
  @visibleForTesting
  Car get car => _car!;

  @visibleForTesting
  Traffic get traffic => _traffic!;

  @visibleForTesting
  RoadView get road => _road!;

  @visibleForTesting
  ProgressDots get dots => _dots!;

  /// The spawner. NOT named `world`: FlameGame has its own `world` (the
  /// component tree's root), and shadowing it compiles right up until something
  /// in Flame reaches for the real one.
  @visibleForTesting
  CarTripWorld get spawner => _world;

  @visibleForTesting
  double get scrolled => _scrolled;

  @visibleForTesting
  double get speedFactor => _speedFactor;

  @visibleForTesting
  int get arrivals => _arrivals;

  @visibleForTesting
  int get hornPresses => _hornPresses;
}
