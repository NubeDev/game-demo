import 'dart:math';

/// The whole of Surf's Up as plain numbers — no Flame, no pictures — so the
/// rules that keep it fair are tested directly.
///
/// ## The game
///
/// Koko sits on her board out past the breakers. Swells roll in from behind
/// her. **Tap as a swell lifts her** and she pops up and rides it towards the
/// beach. While riding, **a tap is a hop**: low shells on the water are hers
/// anyway, high ones need a hop. Three waves reach the beach, where friends are
/// waiting for a party.
///
/// One verb, one meaning: **a tap is always "up"** — up onto the board, then
/// up into the air.
///
/// ## Distances
///
/// Everything is in *units*, where one unit is the height of a 16:9 screen
/// (see `SurfsUpGame.unit`). Heights are measured UP from the flat sea.
///
/// ## The rule that makes it legal (CLAUDE.md §3: no losing, no timer)
///
/// A swell can be missed, and a missed swell is not a failure: another one is
/// always coming. After [helpAfterMisses] misses in a row Koko catches the
/// next one by herself, so **a child who never taps still reaches the beach**.
/// A tap that is too early is a paddle, never a "wrong". Tests pin this.
class Surf {
  Surf({Random? random}) : _random = random ?? Random();

  final Random _random;

  // --- Tuning --------------------------------------------------------------

  /// How fast Koko drifts towards the shore while sitting on her board.
  static const paddleSpeed = 0.12;

  /// How fast a swell rolls in. Faster than [paddleSpeed], so it catches her
  /// up from behind: the relative speed is under 0.4 units a second, which is
  /// slow enough to watch it come.
  static const swellSpeed = 0.5;

  /// Where a new swell starts, behind Koko. Just off the left of the screen,
  /// so it slides into view and there is time to see it coming.
  static const spawnBehind = 1.1;

  /// The pause between one swell going by and the next being sent.
  static const swellGap = 0.8;

  /// The catch window, as the crest's distance from Koko: from [catchEarly]
  /// behind her to [catchLate] ahead of her. At the relative swell speed that
  /// is about a second and a half — deliberately generous: the finger covers
  /// the target and a five-year-old's tap lands late.
  static const catchEarly = 0.34;
  static const catchLate = 0.22;

  /// Misses in a row before Koko catches the next swell by herself.
  static const helpAfterMisses = 2;

  static const popUpTime = 0.45;
  static const rideSpeed = 1.0;
  static const rideTime = 6.0;
  static const settleTime = 1.0;

  static const hopTime = 0.6;
  static const hopHeight = 0.16;

  /// How long before a hop ends a second tap is kept for the next one, so a
  /// tap mid-air is never a dead tap.
  static const hopBuffer = 0.25;

  /// How high Koko must be for a high shell. Well under [hopHeight]: any hop
  /// that is anywhere near the shell gets it.
  static const highShellReach = 0.07;

  /// How close in x Koko must pass to a shell to pick it up.
  static const shellReach = 0.14;

  static const wavesPerTrip = 3;
  static const shellsPerRide = 5;

  /// The first shell's distance ahead when a ride starts, and the spacing.
  static const firstShell = 0.9;
  static const shellSpacing = 0.95;

  /// Which shells in a ride float high (needing a hop). Two per ride, never
  /// first, so every ride opens with a free shell. Cycled by wave.
  static const highPatterns = [
    [false, false, true, false, true],
    [false, true, false, false, true],
    [false, true, false, true, false],
  ];

  static const arriveTime = 1.6;
  static const partyTime = 5.0;
  static const veilTime = 1.2;

  /// The swell's shape: height (as a fraction of [swellRise]) at distance
  /// from its crest. Steeper in front than behind, like a real wave.
  static const swellRise = 0.13;
  static const swellFront = 0.3;
  static const swellBack = 0.55;

  /// A ridden swell stands this much taller than one rolling in.
  static const ridingSize = 1.6;

  /// Where Koko rides on a swell's face: just in front of the crest.
  static const rideAhead = 0.1;

  /// How many friends wait on each beach.
  static const friendsOnBeach = 3;

  // --- State ---------------------------------------------------------------

  SurfPhase phase = SurfPhase.paddling;
  double phaseTime = 0;

  /// Koko's distance along the sea.
  double kokoX = 0;

  final swells = <Swell>[];

  /// Seconds until the next swell is sent, while none is coming.
  double _nextSwellIn = 1.2;

  int missedRun = 0;

  /// Waves ridden this trip — the progress dots. Never goes down within a
  /// trip (CLAUDE.md §3: progress never decreases).
  int wavesCaught = 0;

  /// Which trip this is, from 0. Picks the time of day and the friends.
  int trip = 0;

  /// The current ride was caught by Koko herself, after misses.
  bool helped = false;

  /// Seconds into the current hop, or null on the board.
  double? hopT;
  bool _hopQueued = false;

  final shells = <Shell>[];
  int shellsThisRide = 0;

  /// Where the water meets the sand, once the beach is in sight.
  double? shoreX;

  /// The cover between trips, 0..1.
  double veil = 0;

  final _events = <SurfEvent>[];

  /// The swell rolling in that has not reached Koko yet, if any.
  Swell? get incoming {
    for (final s in swells) {
      if (s.state == SwellState.incoming) return s;
    }
    return null;
  }

  /// Koko is on the board in a catchable spot on a swell.
  bool get inCatchWindow {
    final s = incoming;
    if (s == null) return false;
    final d = s.x - kokoX;
    return d >= -catchEarly && d <= catchLate;
  }

  /// Koko's lift above the board, from a hop.
  double get hopLift {
    final t = hopT;
    if (t == null) return 0;
    final p = (t / hopTime).clamp(0.0, 1.0);
    return hopHeight * 4 * p * (1 - p);
  }

  /// The sea's height at [x], from every swell.
  double seaHeight(double x) {
    var h = 0.0;
    for (final s in swells) {
      h += s.size * swellRise * swellShape(x - s.x);
    }
    return h;
  }

  /// The sand's height at [x]: nothing before the beach, rising out of the
  /// water at [shoreX] to a flat top.
  double sandHeight(double x) {
    final shore = shoreX;
    if (shore == null) return double.negativeInfinity;
    final t = ((x - shore) / 0.6).clamp(0.0, 1.0);
    return -0.04 + 0.1 * (1 - pow(1 - t, 2));
  }

  /// Where Koko's board sits: on the water, or on the sand once she is up it.
  double boardHeight(double x) => max(seaHeight(x), sandHeight(x));

  /// The board's slope at Koko, for tilting it.
  double get boardSlope {
    const dx = 0.02;
    return (boardHeight(kokoX + dx) - boardHeight(kokoX - dx)) / (2 * dx);
  }

  /// The height a ridden swell holds Koko at — where low shells float.
  static double get rideLevel =>
      ridingSize * swellRise * swellShape(rideAhead);

  /// Height of a swell of size 1 at [d] from its crest, 0..1.
  static double swellShape(double d) {
    final w = d > 0 ? swellFront : swellBack;
    return exp(-pow(d / w, 2));
  }

  /// Every event since the last call, oldest first.
  List<SurfEvent> drainEvents() {
    final out = List.of(_events);
    _events.clear();
    return out;
  }

  // --- The one control -----------------------------------------------------

  /// A tap anywhere. Every phase answers it somehow: there is no dead tap.
  void tap() {
    switch (phase) {
      case SurfPhase.paddling:
        if (inCatchWindow) {
          _catch(helped: false);
        } else {
          // Too early, or nothing coming yet: a paddle stroke and a splash.
          // Never a "wrong" — nothing is taken away and the swell still comes.
          _events.add(SurfEvent.paddle);
        }
      case SurfPhase.poppingUp:
        _hopQueued = true;
      case SurfPhase.riding:
      case SurfPhase.party:
        _hop();
      case SurfPhase.settling:
        _events.add(SurfEvent.paddle);
      case SurfPhase.arriving:
      case SurfPhase.veil:
        break;
    }
  }

  void _hop() {
    final t = hopT;
    if (t == null) {
      hopT = 0;
      _events.add(SurfEvent.hop);
    } else if (t > hopTime - hopBuffer) {
      _hopQueued = true;
    }
  }

  void _catch({required bool helped}) {
    final s = incoming!;
    s.state = SwellState.ridden;
    this.helped = helped;
    missedRun = 0;
    _setPhase(SurfPhase.poppingUp);
    _events.add(helped ? SurfEvent.helpedCatch : SurfEvent.caught);
  }

  // --- Time ----------------------------------------------------------------

  void update(double dt) {
    phaseTime += dt;
    _updateSwells(dt);
    _updateHop(dt);

    switch (phase) {
      case SurfPhase.paddling:
        kokoX += paddleSpeed * dt;
        _updateIncoming(dt);
      case SurfPhase.poppingUp:
        kokoX += _lerp(paddleSpeed, rideSpeed, phaseTime / popUpTime) * dt;
        _holdRiddenSwell();
        if (phaseTime >= popUpTime) _startRide();
      case SurfPhase.riding:
        kokoX += rideSpeed * dt;
        _holdRiddenSwell();
        _collectShells();
        if (phaseTime >= rideTime) _endRide();
      case SurfPhase.settling:
        kokoX += _lerp(rideSpeed, paddleSpeed, phaseTime / settleTime) * dt;
        if (phaseTime >= settleTime) {
          _setPhase(SurfPhase.paddling);
          _nextSwellIn = swellGap;
        }
      case SurfPhase.arriving:
        // Glide up the sand, slowing to a stop.
        final p = (phaseTime / arriveTime).clamp(0.0, 1.0);
        kokoX += rideSpeed * (1 - p) * dt;
        if (phaseTime >= arriveTime) {
          _setPhase(SurfPhase.party);
          _events.add(SurfEvent.party);
        }
      case SurfPhase.party:
        if (phaseTime >= partyTime) _setPhase(SurfPhase.veil);
      case SurfPhase.veil:
        final half = veilTime / 2;
        if (phaseTime < half) {
          veil = phaseTime / half;
        } else {
          // Behind the full cover: swap the beach out of sight.
          if (shoreX != null) _nextTrip();
          veil = (1 - (phaseTime - half) / half).clamp(0.0, 1.0);
        }
        if (phaseTime >= veilTime) {
          veil = 0;
          _setPhase(SurfPhase.paddling);
        }
    }
  }

  void _updateSwells(double dt) {
    for (final s in swells) {
      switch (s.state) {
        case SwellState.incoming:
          s.x += swellSpeed * dt;
          s.size = _approach(s.size, 1, dt / 0.8);
        case SwellState.ridden:
          s.size = _approach(s.size, ridingSize, dt / 0.6);
        case SwellState.passed:
          s.x += swellSpeed * dt;
          s.size = _approach(s.size, 0, dt / 1.5);
        case SwellState.broken:
          s.x += rideSpeed * 0.6 * dt;
          s.size = _approach(s.size, 0, dt / 0.7);
      }
    }
    swells.removeWhere((s) => s.state != SwellState.incoming &&
        s.state != SwellState.ridden &&
        s.size <= 0);
  }

  void _updateIncoming(double dt) {
    final s = incoming;
    if (s == null) {
      _nextSwellIn -= dt;
      if (_nextSwellIn <= 0) {
        swells.add(Swell(kokoX - spawnBehind));
        _events.add(SurfEvent.swellComing);
      }
      return;
    }
    final d = s.x - kokoX;
    if (missedRun >= helpAfterMisses && d >= 0) {
      // Two have gone by. This one Koko catches herself — the child is never
      // left waiting on a skill they don't have yet.
      _catch(helped: true);
    } else if (d > catchLate) {
      s.state = SwellState.passed;
      missedRun++;
      _nextSwellIn = swellGap;
      // Not a failure cue: Koko just looks back for the next one.
      _events.add(SurfEvent.missed);
    }
  }

  void _holdRiddenSwell() {
    for (final s in swells) {
      if (s.state == SwellState.ridden) s.x = kokoX - rideAhead;
    }
  }

  void _startRide() {
    _setPhase(SurfPhase.riding);
    final pattern = highPatterns[wavesCaught % highPatterns.length];
    shells
      ..clear()
      ..addAll([
        for (var i = 0; i < shellsPerRide; i++)
          Shell(
            kokoX + firstShell + i * shellSpacing,
            high: pattern[i],
            kind: _random.nextInt(ShellKind.values.length),
          ),
      ]);
    shellsThisRide = 0;
    if (wavesCaught == wavesPerTrip - 1) {
      // The last wave of the trip: the beach comes into sight ahead, and the
      // ride ends at the water's edge.
      shoreX = kokoX + rideSpeed * rideTime + 0.05;
    }
    if (_hopQueued) {
      _hopQueued = false;
      _hop();
    }
  }

  void _collectShells() {
    for (final shell in shells) {
      if (shell.state != ShellState.floating) continue;
      final d = shell.x - kokoX;
      if (d.abs() <= shellReach && (!shell.high || hopLift >= highShellReach)) {
        shell.state = ShellState.collected;
        shellsThisRide++;
        _events.add(SurfEvent.shell);
      } else if (d < -shellReach) {
        // A high shell sailed over. It just floats on; nothing is lost.
        shell.state = ShellState.passed;
      }
    }
  }

  void _endRide() {
    wavesCaught++;
    for (final s in swells) {
      if (s.state == SwellState.ridden) s.state = SwellState.broken;
    }
    _events.add(SurfEvent.waveDone);
    if (wavesCaught >= wavesPerTrip) {
      _setPhase(SurfPhase.arriving);
      _events.add(SurfEvent.landed);
    } else {
      _setPhase(SurfPhase.settling);
    }
  }

  void _updateHop(double dt) {
    final t = hopT;
    if (t == null) return;
    if (t + dt >= hopTime) {
      hopT = null;
      if (_hopQueued) {
        _hopQueued = false;
        if (phase == SurfPhase.riding || phase == SurfPhase.party) _hop();
      }
    } else {
      hopT = t + dt;
    }
  }

  void _nextTrip() {
    trip++;
    wavesCaught = 0;
    missedRun = 0;
    shoreX = null;
    shells.clear();
    swells.clear();
    hopT = null;
    _hopQueued = false;
    _nextSwellIn = 1.2;
    _events.add(SurfEvent.nextTrip);
  }

  void _setPhase(SurfPhase p) {
    phase = p;
    phaseTime = 0;
  }

  static double _lerp(double a, double b, double t) =>
      a + (b - a) * t.clamp(0.0, 1.0);

  static double _approach(double v, double target, double step) =>
      v < target ? min(target, v + step) : max(target, v - step);
}

enum SurfPhase { paddling, poppingUp, riding, settling, arriving, party, veil }

enum SurfEvent {
  swellComing,
  paddle,
  caught,
  helpedCatch,
  missed,
  hop,
  shell,
  waveDone,
  landed,
  party,
  nextTrip,
}

enum SwellState { incoming, ridden, passed, broken }

class Swell {
  Swell(this.x);

  /// Where its crest is.
  double x;

  /// How big it is right now, as a multiple of [Surf.swellRise]. Swells grow
  /// in as they arrive and shrink away after, so none pops into being.
  double size = 0;

  SwellState state = SwellState.incoming;
}

enum ShellState { floating, collected, passed }

/// The shell pictures, drawn in code (`components/shells.dart`).
enum ShellKind { scallop, spiral, starfish }

class Shell {
  Shell(this.x, {required this.high, required this.kind});

  final double x;

  /// Floating up high, on a bubble — needs a hop.
  final bool high;

  /// Index into [ShellKind].
  final int kind;

  ShellState state = ShellState.floating;
}
