import 'dart:math';

import 'park.dart';

/// One thing the park has decided to place, and how far along the walk it goes.
class PlacedHazard {
  PlacedHazard({required this.kind, required this.distance});

  final HazardKind kind;

  /// How far into the walk it sits, in logical pixels from the start.
  final double distance;
}

/// Decides what comes next, and when.
///
/// Pulled out of the game class and made pure so **the rules that keep this
/// game safe are testable without a running game**. Every number here is
/// load-bearing against CLAUDE.md §3, and a regression in any of them turns a
/// no-lose game into a reaction test:
///
///  * **[minGap] is a floor on the space between hazards**, wider still around
///    a duck one ([duckGap]) because moving a thumb from one button to the
///    other is the slowest thing a five-year-old does here.
///  * **Duck hazards are rare** ([duckInEvery]) and **never back-to-back**.
///  * **Nothing gets faster, denser or harder, ever.** Nothing in this class
///    reads elapsed time or distance to decide how hard to be — a child still
///    learning the duck button must not be punished for staying.
///  * **The chase target never escapes.** [catchUpSeconds] is the longest a
///    child who never once presses dash can wait for a treat; the target's own
///    speed is derived from it, so pursuit is a throttle on *when*, never on
///    *whether* (the scope's central promise).
class QuackyWorld {
  QuackyWorld({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// How fast the park scrolls past, in logical pixels per second.
  ///
  /// **One gentle speed, forever.** Nothing in this class or the game ever
  /// changes it. This is Quacky's ordinary waddle; dashing moves *the target*
  /// closer, it does not speed the world up.
  static const scrollSpeed = 180.0;

  /// The minimum space between any two hazards.
  static const minGap = 430.0;

  /// The space demanded either side of a duck hazard, for the thumb journey.
  static const duckGap = 780.0;

  /// Roughly one hazard in this many is one to duck under. The rest are there
  /// to be bumped into for fun.
  static const duckInEvery = 3;

  /// How far ahead of the screen edge things are placed.
  static const spawnLookahead = 260.0;

  /// How far before a duck hazard Quacky's neck goes flat and the music dips.
  ///
  /// At [scrollSpeed] this is about 2.6 seconds of warning — the whole reason a
  /// duck is fair at five (CLAUDE.md §3: telegraph, never surprise).
  static const duckTelegraph = 470.0;

  // --- the chase ----------------------------------------------------------

  /// How long a child who **never presses dash at all** waits for a treat.
  ///
  /// This is the number that makes the scope's central promise true. The target
  /// closes on its own at a rate derived from this, so every treat in the game
  /// arrives whether or not the dash button is ever discovered. Dashing makes
  /// it sooner; nothing makes it never.
  ///
  /// **It must stay below `QuackyTheDuckGame.idleTimeout`, and a test pins
  /// that.** The two are coupled, and the first version got it wrong: at 9
  /// seconds against a 6-second idle, Quacky sat down before the gap ever
  /// closed, so a child who only ever *watched* got nothing at all and the
  /// promise was false in exactly the case it was written for. The gap has to
  /// close inside the window the child is still being counted as present.
  static const catchUpSeconds = 4.5;

  /// The gap the next target starts at, in logical pixels.
  ///
  /// Far enough beyond [caughtWithin] that the chase visibly *closes* — a
  /// target that starts nearly caught is not a chase, it is a queue.
  static const startGap = 620.0;

  /// How much of the gap a single dash burst closes, as a fraction.
  ///
  /// Generous: about four bursts catches anything. A child who has just found
  /// the button should see it work, not have to work it.
  static const dashClose = 0.16;

  /// How close counts as caught, measured **centre to centre**.
  ///
  /// Deliberately large. Quacky arriving *near* them is the catch: the scope
  /// rules out any frame where a duck is pressed against a child, and "nearly"
  /// is far more forgiving for a small thumb (the scope's open question,
  /// answered this way for now).
  ///
  /// The number has to clear both bodies, not just look small: at the first
  /// value of 56 the gap was centre-to-centre while the art is 126 and 104 wide,
  /// so at the moment of the catch Quacky was drawn *inside* the child — which
  /// no test could see and the browser run showed immediately. This is half
  /// Quacky's width plus half the widest target plus a clear margin.
  static const caughtWithin = 150.0;

  /// How fast the gap closes on its own, px/sec. Derived, not guessed.
  static double get drift => (startGap - caughtWithin) / catchUpSeconds;

  /// Distance at which the last hazard was placed.
  double _lastDistance = 0;

  /// Whether the last hazard was a duck one, so two never follow each other.
  /// A duck-and-dash pair in quick succession is explicitly out of scope.
  bool _lastWasDuck = false;

  /// The walk so far. Never resets, never shown, never counted for the child —
  /// it is only the spawner's own bookkeeping.
  double get lastDistance => _lastDistance;

  /// The next hazard, given how far the park has scrolled.
  ///
  /// Returns null when there is nothing to place yet, which is most frames.
  PlacedHazard? next(double scrolled, double screenWidth) {
    final horizon = scrolled + screenWidth + spawnLookahead;
    final at = _lastDistance + _gapAfter(_lastWasDuck);
    if (at > horizon) return null;

    final kind = _pickKind();
    _lastDistance = at;
    _lastWasDuck = kind.action == HazardAction.duck;
    return PlacedHazard(kind: kind, distance: at);
  }

  /// The gap before the next hazard. Varied so the walk is not metronomic, but
  /// **never below the floor** — the variation is all upward.
  double _gapAfter(bool afterDuck) {
    final floor = afterDuck ? duckGap : minGap;
    return floor + _random.nextDouble() * 280;
  }

  HazardKind _pickKind() {
    if (!_lastWasDuck && _random.nextInt(duckInEvery) == 0) {
      final ducks = HazardKind.withAction(HazardAction.duck);
      return ducks[_random.nextInt(ducks.length)];
    }
    final bumps = HazardKind.withAction(HazardAction.bump);
    return bumps[_random.nextInt(bumps.length)];
  }

  /// Who is up ahead next. Never the same as [previous] twice running, so the
  /// child gets variety without anything being rare enough to feel missed.
  ChaseKind nextTarget(ChaseKind? previous) {
    final options = ChaseKind.values.where((k) => k != previous).toList();
    return options[_random.nextInt(options.length)];
  }
}
