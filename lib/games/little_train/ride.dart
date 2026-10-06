import 'dart:math';

import 'lands.dart';

/// What the train is doing.
enum TrainPhase {
  /// Rolling along (or pulling away — speed climbs to cruise on its own).
  cruising,

  /// The child tapped: easing to a stop.
  braking,

  /// Standing still between stations. Always leaves again on its own.
  stopped,

  /// Every wagon is full: rolling into the station, braking by itself.
  arriving,

  /// At the station: the party, the goodbyes, then the next land.
  arrived,
}

/// Where one passenger is in their journey.
enum PassengerState {
  /// Beside the stop post, waving at the train.
  waiting,

  /// The train stopped near them: they trot over to it.
  hurrying,

  /// The train went past: "Wait for me!" and a scamper after it.
  chasing,

  /// The leap up into a wagon.
  boarding,

  /// Sitting in a wagon, arms in the air.
  riding,

  /// At the station: hopping down and waving goodbye.
  leaving,

  /// Waved off. Not drawn any more.
  gone,
}

/// Something that happened this frame, for the game to make a noise or a
/// sparkle about. The model only decides; the game decides what it looks like.
enum RideEvent {
  allAboard,
  nextStop,
  braking,
  perfectStop,
  hurry,
  waitForMe,
  boarded,
  stoppedAlone,
  depart,
  toot,
  arrived,
  unload,
  landChanged,
}

class Passenger {
  Passenger({required this.animal, required this.stopX}) : x = stopX;

  final String animal;

  /// Where the stop post stands, in ride units.
  final double stopX;

  /// Where the animal is right now.
  double x;

  PassengerState state = PassengerState.waiting;

  /// The wagon this passenger is heading for or sitting in.
  int? wagon;

  /// 0..1 through a leap (boarding or leaving); past 1 while waving goodbye.
  double t = 0;

  /// Where the current leap started.
  double fromX = 0;

  /// Where a leaving passenger is hopping to.
  double toX = 0;

  /// Got on from a stop right beside them. Worth an extra sparkle.
  bool perfect = false;

  /// "Next stop!" has been said for this one.
  bool announced = false;
}

/// The whole ride, as plain numbers: no Flame, no Flutter, no pictures. That
/// is what lets the kid rules below be tested without running the game.
///
/// ## Units
///
/// Everything is in **ride units**, where 1.0 is the game's design height
/// (see `LittleTrainGame.unit`). Speeds are units per second.
///
/// ## The one thing not to break
///
/// **Every passenger gets on.** This game's verb is *stop at the right place*,
/// and "the right place" is a target — which is a miss waiting to happen, and
/// a miss is a loss (CLAUDE.md §3). So the outcome is taken out of the stop:
///
///  * stop right beside them and they hop straight in ([perfectWindow]);
///  * stop short and they trot over ([walkWindow]);
///  * sail straight past and they shout "Wait for me!" and chase the train,
///    always faster than it ([chaseExtra]) — so they **always** catch up.
///
/// A child who never taps at all still fills every wagon and reaches every
/// station. Tapping well buys a sooner, sparklier boarding; it never decides
/// whether boarding happens. If a future change ever lets a passenger be left
/// behind, this game has quietly grown a fail state.
///
/// ## And the train never gets stuck
///
/// Every way of standing still has a timer out of it ([aloneResume],
/// [boardPause], the station sequence). Nothing waits on the child.
class Ride {
  Ride() {
    _startLand(0);
  }

  // --- the train's shape -------------------------------------------------
  //
  // Widths in ride units, matching how big the train component draws the
  // generated pictures. The doors are the middles of the wagons.

  static const engineWidth = 0.29;
  static const wagonWidth = 0.255;
  static const coupling = 0.013;

  /// From the front of the engine to the back of the last wagon.
  static const trainLength =
      engineWidth + passengersPerLand * (wagonWidth + coupling);

  /// Where wagon [i]'s middle is, relative to the front of the train. Wagon 0
  /// is coupled to the engine.
  static double wagonOffset(int i) =>
      -(engineWidth + coupling + wagonWidth / 2 + i * (wagonWidth + coupling));

  // --- feel --------------------------------------------------------------

  /// One gentle speed, forever. No difficulty ramp anywhere in this game.
  static const cruiseSpeed = 0.34;

  /// How quickly it pulls away. Slow enough to look heavy and toy-like.
  static const acceleration = 0.45;

  /// How far the train rolls after a tap. Short, so "tap when you reach them"
  /// is what works — the child does not have to plan ahead.
  static const brakeDistance = 0.2;
  static const brakeDecel = cruiseSpeed * cruiseSpeed / (2 * brakeDistance);

  /// The station stop is a long, slow roll-in: it is the destination, not a
  /// skill, and the train does it by itself.
  static const arriveDistance = 0.9;
  static const arriveDecel = cruiseSpeed * cruiseSpeed / (2 * arriveDistance);

  /// How close a wagon must stop to a passenger for them to hop straight in.
  /// Generous: about the width of a wagon.
  static const perfectWindow = 0.25;

  /// Stopped further away than [perfectWindow] but within this, and they trot
  /// over. Further than this and the stop was for nobody — a toot, and off
  /// again.
  static const walkWindow = 1.4;

  /// How far past the LAST empty wagon a waiting passenger has to be before
  /// they give chase. Every empty wagon has to have gone by first: any of them
  /// would do.
  static const chaseAfter = 0.15;

  static const walkSpeed = 0.6;

  /// How much faster than the train a chasing passenger runs. **Must be
  /// greater than zero** — this one number is the no-fail promise.
  static const chaseExtra = 0.5;

  static const leapSeconds = 0.55;

  /// After someone gets on at a stop, the train waits this long and goes.
  static const boardPause = 1.0;

  /// After a stop for nobody, the train toots and goes after this long.
  static const aloneResume = 1.4;

  // --- the line ----------------------------------------------------------

  static const firstStop = 2.0;
  static const stopSpacing = 2.6;
  static const stationAfter = 3.0;

  /// The station sequence, in seconds after arriving.
  static const unloadAt = [1.6, 2.2, 2.8];
  static const veilDownAt = 4.4;
  static const landChangeAt = 5.0;
  static const departAt = 5.4;
  static const veilUpAt = 5.6;

  // --- state -------------------------------------------------------------

  int _landIndex = 0;
  int get landIndex => _landIndex;
  Land get land => lands[_landIndex % lands.length];

  double _trainX = 0;

  /// The front of the engine.
  double get trainX => _trainX;

  double _speed = 0;
  double get speed => _speed;

  TrainPhase _phase = TrainPhase.cruising;
  TrainPhase get phase => _phase;

  List<Passenger> _passengers = const [];
  List<Passenger> get passengers => _passengers;

  double _stationX = 0;

  /// Where the front of the engine stops at the station.
  double get stationX => _stationX;

  /// How much of the line ahead of the engine is on screen. Set by the game,
  /// so "Next stop!" is said as the passenger comes into view.
  double viewAhead = 1.0;

  /// Counts down to leaving a stop. Null while waiting on a passenger.
  double? _resumeIn;

  /// Seconds since arriving at the station. Null when not at one.
  double? _arrivedFor;

  /// 0..1: the soft cover drawn between lands, so the scenery swaps unseen.
  double get veil {
    final t = _arrivedFor;
    if (t == null) return 0;
    const fade = landChangeAt - veilDownAt;
    if (t < veilDownAt) return 0;
    if (t < landChangeAt) return (t - veilDownAt) / fade;
    return (1 - (t - landChangeAt) / (veilUpAt - landChangeAt)).clamp(0, 1);
  }

  final _events = <(RideEvent, Passenger?)>[];

  /// Everything that happened since the last call.
  List<(RideEvent, Passenger?)> drainEvents() {
    final out = List.of(_events);
    _events.clear();
    return out;
  }

  double doorX(int wagon) => _trainX + wagonOffset(wagon);

  /// How many wagons have somebody in them or on the way.
  int get wagonsFilled =>
      _passengers.where((p) => p.state == PassengerState.riding).length;

  Iterable<int> get _freeWagons sync* {
    final taken = {for (final p in _passengers) p.wagon};
    for (var i = 0; i < passengersPerLand; i++) {
      if (!taken.contains(i)) yield i;
    }
  }

  int _nearestFreeWagon(double x) {
    final free = _freeWagons.toList();
    free.sort((a, b) => (doorX(a) - x).abs().compareTo((doorX(b) - x).abs()));
    return free.first;
  }

  // --- the child's one control -------------------------------------------

  /// A tap anywhere. Moving: brake. Standing: go. At the station: toot,
  /// because a tap must never do nothing (CLAUDE.md §3).
  void tap() {
    switch (_phase) {
      case TrainPhase.cruising:
        _phase = TrainPhase.braking;
        _emit(RideEvent.braking);
      case TrainPhase.braking:
        // Already stopping. A second tap is the same wish, not a new one.
        break;
      case TrainPhase.stopped:
        final leaping =
            _passengers.any((p) => p.state == PassengerState.boarding);
        // Mid-leap the train waits: it would be cruel to leave as they jump.
        if (leaping) {
          _emit(RideEvent.toot);
        } else {
          _depart();
        }
      case TrainPhase.arriving:
      case TrainPhase.arrived:
        _emit(RideEvent.toot);
    }
  }

  // --- the frame ---------------------------------------------------------

  void update(double dt) {
    _moveTrain(dt);
    for (final p in _passengers) {
      _updatePassenger(p, dt);
    }
    _announce();
    _checkArrival();
    _updateStopped(dt);
    _updateStation(dt);
  }

  void _moveTrain(double dt) {
    switch (_phase) {
      case TrainPhase.cruising:
        _speed = min(cruiseSpeed, _speed + acceleration * dt);
      case TrainPhase.braking:
        _speed = max(0, _speed - brakeDecel * dt);
        if (_speed == 0) {
          _phase = TrainPhase.stopped;
          _onStopped();
        }
      case TrainPhase.arriving:
        // Speed from the distance left, so it stops exactly at the station
        // whatever speed it came in at.
        final remaining = max(0.0, _stationX - _trainX);
        _speed = min(_speed, sqrt(2 * arriveDecel * remaining));
        if (remaining < 0.004 || _speed < 0.01) {
          _speed = 0;
          _trainX = _stationX;
          _phase = TrainPhase.arrived;
          _arrivedFor = 0;
          _emit(RideEvent.arrived);
        }
      case TrainPhase.stopped:
      case TrainPhase.arrived:
        _speed = 0;
    }
    _trainX += _speed * dt;
  }

  void _onStopped() {
    final p = _nextPassenger;
    if (p == null || p.state != PassengerState.waiting) {
      // Nobody waiting — or somebody is already on their way to the train,
      // and gets on when they reach it.
      if (p == null) _stoppedAlone();
      return;
    }
    final wagon = _nearestFreeWagon(p.x);
    final gap = (p.x - doorX(wagon)).abs();
    if (gap <= perfectWindow) {
      p.wagon = wagon;
      p.perfect = true;
      _emit(RideEvent.perfectStop, p);
      _startBoarding(p);
    } else if (gap <= walkWindow) {
      p.wagon = wagon;
      p.state = PassengerState.hurrying;
      _emit(RideEvent.hurry, p);
    } else {
      _stoppedAlone();
    }
  }

  void _stoppedAlone() {
    _emit(RideEvent.stoppedAlone);
    _resumeIn = aloneResume;
  }

  Passenger? get _nextPassenger {
    for (final p in _passengers) {
      if (p.state == PassengerState.waiting ||
          p.state == PassengerState.hurrying ||
          p.state == PassengerState.chasing) {
        return p;
      }
    }
    return null;
  }

  void _updatePassenger(Passenger p, double dt) {
    switch (p.state) {
      case PassengerState.waiting:
        if (_speed <= 0) return;
        final free = _freeWagons.toList();
        if (free.isEmpty) return;
        // The LAST empty wagon has gone by: the train has missed them.
        final rearmost = free.reduce(max);
        if (doorX(rearmost) > p.x + chaseAfter) {
          p.state = PassengerState.chasing;
          p.wagon = rearmost;
          _emit(RideEvent.waitForMe, p);
        }
      case PassengerState.hurrying:
      case PassengerState.chasing:
        final target = doorX(p.wagon!);
        // A chaser is always faster than the train — the no-fail promise.
        final pace = p.state == PassengerState.chasing
            ? max(walkSpeed, _speed + chaseExtra)
            : walkSpeed;
        final step = pace * dt;
        final gap = target - p.x;
        if (gap.abs() <= step) {
          p.x = target;
          _startBoarding(p);
        } else {
          p.x += gap.sign * step;
        }
      case PassengerState.boarding:
        p.t += dt / leapSeconds;
        if (p.t >= 1) {
          p.t = 1;
          p.state = PassengerState.riding;
          p.x = doorX(p.wagon!);
          _emit(RideEvent.boarded, p);
          if (_phase == TrainPhase.stopped) _resumeIn = boardPause;
        }
      case PassengerState.riding:
        p.x = doorX(p.wagon!);
      case PassengerState.leaving:
        p.t += dt / leapSeconds;
        // One leap down, then a few leaps' worth of waving, then gone.
        if (p.t >= 4) p.state = PassengerState.gone;
      case PassengerState.gone:
        break;
    }
  }

  void _startBoarding(Passenger p) {
    p.state = PassengerState.boarding;
    p.fromX = p.x;
    p.t = 0;
  }

  void _announce() {
    for (final p in _passengers) {
      if (p.announced || p.state != PassengerState.waiting) continue;
      if (p.stopX - _trainX <= viewAhead + 0.05) {
        p.announced = true;
        _emit(RideEvent.nextStop, p);
      }
    }
  }

  void _checkArrival() {
    if (_phase != TrainPhase.cruising) return;
    if (_passengers.any((p) => p.state != PassengerState.riding)) return;
    final needed = _speed * _speed / (2 * arriveDecel);
    if (_stationX - _trainX <= needed + 0.01) {
      _phase = TrainPhase.arriving;
    }
  }

  void _updateStopped(double dt) {
    if (_phase != TrainPhase.stopped) return;
    final wait = _resumeIn;
    if (wait == null) return;
    _resumeIn = wait - dt;
    if (_resumeIn! <= 0) _depart();
  }

  void _depart() {
    _resumeIn = null;
    _phase = TrainPhase.cruising;
    for (final p in _passengers) {
      // Somebody trotting over when the train set off: now they chase it,
      // and still get on.
      if (p.state == PassengerState.hurrying) p.state = PassengerState.chasing;
    }
    _emit(RideEvent.depart);
  }

  void _updateStation(double dt) {
    final before = _arrivedFor;
    if (before == null) return;
    final now = before + dt;
    _arrivedFor = now;

    bool crossed(double at) => before < at && now >= at;

    for (var i = 0; i < unloadAt.length && i < _passengers.length; i++) {
      if (crossed(unloadAt[i])) _unload(_passengers[i], i);
    }
    if (crossed(landChangeAt)) {
      _startLand(_landIndex + 1);
      _emit(RideEvent.landChanged);
    }
    if (crossed(departAt)) {
      _phase = TrainPhase.cruising;
      _emit(RideEvent.allAboard);
    }
    if (now >= veilUpAt) _arrivedFor = null;
  }

  /// Where the station building stands: behind the middle of the stopped train.
  double get stationBuildingX => _stationX - trainLength / 2;

  void _unload(Passenger p, int i) {
    p.state = PassengerState.leaving;
    p.fromX = p.x;
    p.toX = stationBuildingX + (i - 1) * 0.3;
    p.t = 0;
    _emit(RideEvent.unload, p);
  }

  void _startLand(int index) {
    _landIndex = index;
    final from = _trainX;
    final names = lands[index % lands.length].passengers;
    _passengers = [
      for (var i = 0; i < names.length; i++)
        Passenger(animal: names[i], stopX: from + firstStop + i * stopSpacing),
    ];
    _stationX =
        from + firstStop + (names.length - 1) * stopSpacing + stationAfter;
    if (index == 0) _emit(RideEvent.allAboard);
  }

  void _emit(RideEvent e, [Passenger? p]) => _events.add((e, p));
}
