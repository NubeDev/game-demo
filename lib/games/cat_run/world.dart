import 'dart:math';

import 'obstacles.dart';

/// One thing the world has decided to place, and how far along the run it goes.
class PlacedObstacle {
  PlacedObstacle({required this.kind, required this.distance, this.prize});

  final ObstacleKind kind;

  /// How far into the run it sits, in logical pixels from the start.
  final double distance;

  final BlockPrize? prize;
}

/// Decides what comes next, and when.
///
/// Pulled out of the game class and made pure so the **rules that keep this
/// game safe are testable without a running game**. Every one of these numbers
/// is load-bearing against CLAUDE.md §3, and a regression in any of them turns a
/// no-lose game into a reaction test:
///
///  * **[minGap] is a floor on the space between obstacles**, in pixels. At
///    [CatRunWorld.scrollSpeed] it is comfortably longer than a jump arc, so the
///    child is never asked to land and immediately jump again.
///  * **[duckGap] is a much bigger floor around a duck obstacle**, because
///    moving a thumb from one button to the other is the slowest thing a
///    five-year-old does here.
///  * **Duck obstacles are rare** ([duckInEvery]) and **never back-to-back**.
///  * **Nothing gets faster, denser or harder, ever.** There is no difficulty
///    ramp and no reference to elapsed time or distance in any of these
///    decisions — a child still learning the jump must not be punished for
///    staying (the scope's *Not this*).
class CatRunWorld {
  CatRunWorld({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// How fast the world scrolls past, in logical pixels per second.
  ///
  /// **One gentle speed, forever.** Nothing in this class or the game ever
  /// changes it.
  static const scrollSpeed = 190.0;

  /// The minimum space between any two obstacles.
  ///
  /// Derived, not guessed: a jump lasts [Cat.jumpDuration], during which the
  /// world moves `scrollSpeed * jumpDuration` px, and this leaves a bit over
  /// double that — so a child who has just landed always has a clear beat
  /// before the next thing. Pinned by a test.
  static const minGap = 420.0;

  /// The space demanded either side of a duck obstacle, for the thumb journey.
  static const duckGap = 760.0;

  /// Roughly one obstacle in this many is a duck one.
  static const duckInEvery = 7;

  /// Roughly one in this many is a bouncy thing, and one in this many a block.
  static const bounceInEvery = 4;
  static const blockInEvery = 4;

  /// Roughly one gap in this many also gets a fish in it.
  static const fishInEvery = 2;

  /// How far ahead of the screen edge things are placed.
  static const spawnLookahead = 240.0;

  /// How far before a duck obstacle the cat's ears flatten and the music dips.
  /// At [scrollSpeed] this is about 2.4 seconds of warning — the whole reason a
  /// duck is fair at five (CLAUDE.md §3: telegraph, never surprise).
  static const duckTelegraph = 460.0;

  /// Distance at which the last obstacle was placed.
  double _lastDistance = 0;

  /// Whether the last obstacle placed was a duck one, so two never follow each
  /// other. A jump-duck pair in quick succession is explicitly out of scope.
  bool _lastWasDuck = false;

  /// The run so far. Never resets, never shown, never counted for the child —
  /// it is only the spawner's own bookkeeping.
  double get lastDistance => _lastDistance;

  /// The next obstacle, given how far the world has scrolled.
  ///
  /// Returns null when there is nothing to place yet, which is most frames.
  PlacedObstacle? next(double scrolled, double screenWidth) {
    final horizon = scrolled + screenWidth + spawnLookahead;
    final gap = _gapAfter(_lastWasDuck);
    final at = _lastDistance + gap;
    if (at > horizon) return null;

    final kind = _pickKind();
    _lastDistance = at;
    _lastWasDuck = kind.action == ObstacleAction.duck;
    return PlacedObstacle(
      kind: kind,
      distance: at,
      prize: kind.action == ObstacleAction.block
          ? BlockPrize.values[_random.nextInt(BlockPrize.values.length)]
          : null,
    );
  }

  /// The gap before the next obstacle. Varied so the run is not metronomic, but
  /// **never below the floor** — the variation is all upward.
  double _gapAfter(bool afterDuck) {
    final floor = afterDuck ? duckGap : minGap;
    return floor + _random.nextDouble() * 260;
  }

  /// What the next thing is.
  ///
  /// Weighted so jumping is the common case — the jump is the skill the game is
  /// about, and the child needs many goes at it. Duck obstacles are rare and
  /// never twice in a row.
  ObstacleKind _pickKind() {
    if (!_lastWasDuck && _random.nextInt(duckInEvery) == 0) {
      final ducks = ObstacleKind.withAction(ObstacleAction.duck);
      // A duck obstacle needs room on BOTH sides, so the gap before the *next*
      // thing is widened too — handled by _lastWasDuck in _gapAfter.
      return ducks[_random.nextInt(ducks.length)];
    }
    if (_random.nextInt(bounceInEvery) == 0) {
      final bouncy = ObstacleKind.withAction(ObstacleAction.bounce);
      return bouncy[_random.nextInt(bouncy.length)];
    }
    if (_random.nextInt(blockInEvery) == 0) return ObstacleKind.block;
    final jumps = ObstacleKind.withAction(ObstacleAction.jump);
    return jumps[_random.nextInt(jumps.length)];
  }

  /// Whether a fish should go in the gap before [obstacleDistance].
  bool wantsFish() => _random.nextInt(fishInEvery) == 0;

  /// How high a fish floats: on the ground, or at an easy jump height.
  ///
  /// Never higher than the cat can comfortably reach — a fish that could not be
  /// got would be the one missable thing in the game.
  double fishHeight(double jumpRise) =>
      _random.nextBool() ? 26 : jumpRise * (0.45 + _random.nextDouble() * 0.25);
}
