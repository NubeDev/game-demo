import 'dart:math';

import 'road.dart';

/// One thing the world has decided to put on the road, and where.
class PlacedThing {
  PlacedThing({
    required this.kind,
    required this.distance,
    required this.lateral,
  });

  final RoadThingKind kind;

  /// How far into the trip it sits, in world pixels from the start.
  final double distance;

  /// Where across the road it sits. See `road.dart` for the units.
  final double lateral;
}

/// Decides what is up the road, and where.
///
/// Pulled out of the game and made pure so the **rules that keep this game safe
/// are testable without a running game** — the same shape as
/// `cat_run/world.dart`, for the same reason. Every number here is load-bearing
/// against CLAUDE.md §3:
///
///  * **[speed] never changes.** One gentle speed, forever. Nothing in this
///    class or the game reads elapsed time or distance to decide how hard to
///    be: there is no difficulty ramp, because a child still learning to hold a
///    line must not be punished for staying.
///  * **[minGap] is a floor on the space between things**, so the road is never
///    a slalom. At [speed] it is over a second of clear road each time.
///  * **Only one thing is ever placed at a given distance**, so there is never
///    a wall across the road. A test pins the widest nudge thing against the
///    width of the road as well.
///  * **A passenger that was driven past comes back** ([missed]). Nothing in
///    this game can be missed for good, so the trip cannot be made longer or
///    shorter by being good at it.
class CarTripWorld {
  CarTripWorld({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// How fast the road comes toward the car, in world pixels per second.
  ///
  /// **One gentle speed, forever.** Nothing ever changes it — not time, not
  /// distance, not how well the child is doing. The only thing that scales it
  /// is the child lifting their thumb (the car coasts to a stop) and the grass
  /// verge (a touch slower, because it is bumpy).
  static const double speed = 210;

  /// The floor on the gap between two things on the road.
  ///
  /// Derived, not guessed: at [speed] this is about 1.4 seconds of clear road,
  /// which is comfortably longer than the ~0.9s it takes to steer all the way
  /// across. So a child who has just swerved one way always has time to come
  /// back before the next thing. Pinned by a test.
  static const double minGap = 290;

  /// How much longer a gap can randomly be. All variation is *upward*, so the
  /// floor is a floor.
  static const double gapSpread = 240;

  /// The floor on the gap between passengers. Much bigger: a passenger is the
  /// thing the child is actually steering towards, and they need room to line
  /// up on it rather than meeting the next one immediately.
  static const double passengerGap = 620;
  static const double passengerSpread = 380;

  /// The gap between things out in the fields. They are scenery — never
  /// collided with — so this is about how busy the view looks, nothing else.
  static const double waverGap = 300;
  static const double waverSpread = 260;

  /// Roughly one road thing in this many is something alive crossing (which
  /// always steps aside), and one in this many is something to steer around.
  /// Everything else is something fun to drive through — deliberately the
  /// common case.
  static const int crossingInEvery = 9;
  static const int nudgeInEvery = 3;

  /// Which verge the next passenger waits on. Alternated rather than random, so
  /// a child is never asked for the same side twice running and every trip
  /// teaches both directions.
  bool _passengerOnLeft = false;

  // Where each stream's NEXT thing goes, decided when the previous one was
  // placed rather than re-rolled every frame.
  //
  // This matters more than it looks: rolling the gap afresh on each call and
  // asking "is it due yet" means the first roll small enough to fit wins, so
  // every gap collapses toward the floor and the road ends up metronomic.
  // Deciding once keeps the variation the child actually sees.
  //
  // The opening offsets are a gentle start — a few seconds of just driving
  // before the road asks anything, which is how a five-year-old finds out that
  // the thumb steers.
  double _nextThing = 520;
  double _nextPassenger = 760;
  double _nextWaver = 180;

  /// Passengers that were driven past, waiting to be offered again.
  final _owed = <RoadThingKind>[];

  /// A passenger the child drove past. It will be waiting a little further up
  /// the road — see the class doc.
  void missed(RoadThingKind kind) {
    if (kind.action == RoadAction.pickUp) _owed.add(kind);
  }

  /// How many passengers are owed. Exposed for tests.
  int get owed => _owed.length;

  /// The next thing to place, given how far the trip has come.
  ///
  /// Returns null when there is nothing due yet, which is most frames. Call it
  /// until it returns null to place everything that has come due.
  PlacedThing? next(double scrolled) {
    final horizon = scrolled + Perspective.viewDepth;

    // Whichever stream is due first, so the three never starve each other.
    final soonest = min(_nextThing, min(_nextPassenger, _nextWaver));
    if (soonest > horizon) return null;

    if (soonest == _nextPassenger) {
      final at = _nextPassenger;
      _nextPassenger =
          at + passengerGap + _random.nextDouble() * passengerSpread;
      return _placePassenger(at);
    }
    if (soonest == _nextWaver) {
      final at = _nextWaver;
      _nextWaver = at + waverGap + _random.nextDouble() * waverSpread;
      return _placeWaver(at);
    }
    final at = _nextThing;
    _nextThing = at + minGap + _random.nextDouble() * gapSpread;
    return _placeThing(at);
  }

  /// Something on the road: fun to drive through, or to steer around, or alive
  /// and crossing.
  PlacedThing _placeThing(double at) {
    if (_random.nextInt(crossingInEvery) == 0) {
      final crossing = RoadThingKind.withAction(RoadAction.stepsAside);
      return PlacedThing(
        kind: crossing[_random.nextInt(crossing.length)],
        distance: at,
        lateral: _acrossTarmac(0.5),
      );
    }
    if (_random.nextInt(nudgeInEvery) == 0) {
      final nudges = RoadThingKind.withAction(RoadAction.nudge);
      return PlacedThing(
        kind: nudges[_random.nextInt(nudges.length)],
        distance: at,
        // Never dead centre and never at the very edge: a thing in the middle
        // of the lane leaves the most room either side of it, which is what
        // makes "steer around it" a choice rather than a squeeze.
        lateral: _acrossTarmac(0.72),
      );
    }

    final fun = RoadThingKind.withAction(RoadAction.driveThrough);
    final kind = fun[_random.nextInt(fun.length)];
    return PlacedThing(
      kind: kind,
      distance: at,
      // The arch and the car wash span the road, so they sit on the centre
      // line; everything else can be anywhere on the tarmac.
      lateral: kind.drawWidth > 1.5 ? 0 : _acrossTarmac(0.72),
    );
  }

  PlacedThing _placePassenger(double at) {
    // Anyone driven past is offered again before anyone new, so a child who
    // wanted the bear and missed it gets the bear.
    final kind = _owed.isNotEmpty
        ? _owed.removeAt(0)
        : () {
            final all = RoadThingKind.withAction(RoadAction.pickUp);
            return all[_random.nextInt(all.length)];
          }();

    _passengerOnLeft = !_passengerOnLeft;
    return PlacedThing(
      kind: kind,
      distance: at,
      // On the verge, just off the tarmac: the child pulls over to them, which
      // is the one moment in the game where steering has a target.
      lateral: _passengerOnLeft ? -1.12 : 1.12,
    );
  }

  PlacedThing _placeWaver(double at) {
    final wavers = RoadThingKind.withAction(RoadAction.waver);
    final side = _random.nextBool() ? -1 : 1;
    return PlacedThing(
      kind: wavers[_random.nextInt(wavers.length)],
      distance: at,
      // Out in the field, well beyond anywhere the car can reach.
      lateral: side * (1.9 + _random.nextDouble() * 1.6),
    );
  }

  /// A lateral position within [extent] of the centre line.
  double _acrossTarmac(double extent) =>
      (_random.nextDouble() * 2 - 1) * extent;
}
