import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../shared/celebration.dart';
import '../../shared/kid_haptics.dart';
import '../../shared/kid_sounds.dart';
import 'components/cat.dart';
import 'components/obstacle.dart';
import 'components/prize.dart';
import 'components/progress_fish.dart';
import 'components/scenery.dart';
import 'obstacles.dart';
import 'world.dart';

/// Cat Run.
///
/// A cat runs left to right at one gentle speed forever. The child presses a
/// paw to jump and a crouching cat to duck. Things come past to jump over, duck
/// under, bounce on and headbutt. Fish fill the progress stars; a full row is a
/// celebration and the world changes place.
///
/// ## The one hard problem in this game
///
/// **A runner with obstacles is failure-shaped**, and CLAUDE.md §3 forbids
/// losing outright. This is resolved by keeping the obstacle and deleting the
/// loss: every miss is slapstick the child will want to see (a tumble, a
/// pancake, a belly-flop), the cat always lands on its feet and runs on, and
/// there is no counter, no life, no restart and no end.
///
/// The reason to play *well* is moved entirely into the gradient of nicer
/// outcomes — the chime ladder ([_chimeRung]) and what pops out of a block —
/// with nothing at the bottom of it.
///
/// ## Everything that makes the timing fair
///
///  * **One speed, forever** ([CatRunWorld.scrollSpeed]). No difficulty ramp
///    anywhere: nothing in this file reads elapsed time or distance to decide
///    how hard to be.
///  * **A floor on the spacing** ([CatRunWorld.minGap]), wider still around a
///    duck ([CatRunWorld.duckGap]).
///  * **Every duck is telegraphed** — the cat's ears flatten and a soft cue
///    plays [CatRunWorld.duckTelegraph] px before it arrives.
///  * **Late and early presses both work** — see [Cat.coyoteTime] and
///    [Cat.jumpBufferTime].
///  * **Leave it alone and the cat sits down** ([idleTimeout]) rather than
///    running into things unattended. The world stops, so the child can look.
class CatRunGame extends FlameGame {
  CatRunGame({required this.sounds, Random? random})
    : _world = CatRunWorld(random: random);

  final KidSounds sounds;

  /// Owns every random decision in the game, so a test can seed it and replay
  /// the same run.
  final CatRunWorld _world;

  /// How many fish make a celebration. Same size as Balloon Pop's row, so the
  /// rhythm of the app is consistent.
  static const fishPerCelebration = 10;

  /// How long with no press before the cat slows to a trot and sits down.
  ///
  /// Long enough not to interrupt a child who is just watching, short enough
  /// that the cat is not left running into fences alone (the scope: *it does not
  /// keep running into things while nobody is playing*).
  static const idleTimeout = 6.0;

  /// How long the cat takes to slow to a stop when it sits.
  static const _slowDownSeconds = 1.2;

  /// How far left of the screen the cat runs. A third in, so there is plenty of
  /// road visible ahead — the child has to see a thing coming to time it.
  static const catXFraction = 0.28;

  // NOT `late final`. These are built in the async onLoad(), and the two play
  // buttons are live from the moment the screen paints — so a child who presses
  // during that gap would hit a LateInitializationError. In a release build (and
  // in a browser) a thrown error inside a gesture callback is swallowed, so the
  // button does nothing at all, silently, and it looks like the game is broken.
  // Nullable plus a guard in every control is the honest version.
  Scenery? _scenery;
  Cat? _cat;
  late final ProgressFish _stars;
  late final Celebration _celebration;

  /// How far the world has scrolled.
  double _scrolled = 0;

  /// 0..1 — how much of full speed the world is moving at. Only ever driven by
  /// the idle behaviour, never by difficulty.
  double _speedFactor = 1;

  /// Seconds since the child last pressed anything.
  double _sinceLastPress = 0;

  /// Fish collected since the last celebration.
  int _fishThisRound = 0;

  /// How many clean clears in a row, which is the chime ladder's rung.
  ///
  /// A bonk **does not reset this** — it simply stops it climbing until the next
  /// clean clear. A reset is the one place a miss could read as a punishment,
  /// and the scope leans against it.
  int _chimeRung = 0;

  /// Exposed for tests, which cannot hear the ladder.
  @visibleForTesting
  int get chimeRung => _chimeRung;

  /// Whether a duck telegraph is currently running, so the cue fires once.
  Obstacle? _telegraphing;

  /// How many celebrations have happened. Only used to pick the next scene.
  int _celebrations = 0;

  /// Paused only while the confetti plays.
  bool _placing = true;

  @override
  Color backgroundColor() => Scene.garden.skyBottom;

  @override
  Future<void> onLoad() async {
    final scenery = Scenery();
    _scenery = scenery;
    add(scenery);

    final cat = Cat(
      position: Vector2(size.x * catXFraction, _groundY),
      onLanded: _onCatLanded,
    );
    _cat = cat;
    cat.fitTo(headroom: _groundY);
    add(cat);

    _stars = ProgressFish(
      total: fishPerCelebration,
      // Top-left, clear of the home button (top-right) and both play buttons
      // (bottom corners).
      position: Vector2(24, 24),
    );
    add(_stars);

    _celebration = Celebration();
    add(_celebration);

    // NO Rive character. A shape-drawn cat does everything this game needs, and
    // the jump arc was tuned against its exact body height — see the README's
    // note on the scope's open question. `lib/shared/rive_character.dart`
    // remains ready if real art arrives.

    // A gentle start: the first thing is far enough away that the child gets a
    // few seconds of just watching the cat run before anything is asked of them.
    _world.next(0, size.x);
  }

  /// The rise the cat is actually using on this screen — see [Cat.fitTo].
  /// Everything placed at "jump height" reads this, never [Cat.jumpRise], or a
  /// short screen would put the block and the fish out of reach.
  double get _jumpRise => _cat?.rise ?? Cat.jumpRise;

  double get _groundY {
    final scenery = _scenery;
    return scenery != null && scenery.isMounted
        ? scenery.groundY
        : size.y * 0.76;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Keep the cat on the ground line and a third in, whatever the screen.
    if (isMounted) {
      final cat = _cat;
      if (cat != null) {
        cat.position = Vector2(size.x * catXFraction, _groundY);
        // Fit the arc to the sky this screen has: the design rise assumes a
        // tablet, and on a phone in landscape it would carry the cat off the
        // top. Placement below reads `cat.rise`, not the constant, so the
        // block and the fish move with it.
        cat.fitTo(headroom: _groundY);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Nothing to run until onLoad has built the world. One guard here means
    // every helper below can take the cat and the scenery as given.
    final cat = _cat;
    final scenery = _scenery;
    if (cat == null || scenery == null) return;

    _sinceLastPress += dt;
    _updateSpeed(dt);

    final distance = CatRunWorld.scrollSpeed * _speedFactor * dt;
    _scrolled += distance;
    scenery.advance(distance);

    _moveThings(distance);
    if (_placing) _placeThings();
    _checkTelegraph(cat);
    _checkCollisions(cat);
  }

  /// The idle behaviour: slow to a trot, then sit down and sniff a flower.
  ///
  /// This is what gives the child back the control a scrolling world takes away
  /// (CLAUDE.md §3). It is not a pause screen and there is nothing to dismiss —
  /// any press starts it running again.
  void _updateSpeed(double dt) {
    final shouldRun = _sinceLastPress < idleTimeout;
    final target = shouldRun ? 1.0 : 0.0;
    final step = dt / _slowDownSeconds;
    _speedFactor = target > _speedFactor
        ? min(target, _speedFactor + step * 3) // wakes up quickly
        : max(target, _speedFactor - step);
    final cat = _cat;
    if (cat == null) return;
    if (_speedFactor <= 0.01) {
      cat.sit();
    } else {
      cat.wake();
    }
  }

  void _moveThings(double distance) {
    for (final obstacle in children.query<Obstacle>()) {
      obstacle.position.x -= distance;
      // Off the left edge: gone, and if it was never hit the child cleared it.
      if (obstacle.position.x + obstacle.size.x < -40) {
        if (!obstacle.isSpent) _onCleared(obstacle);
        obstacle.removeFromParent();
      }
    }
    for (final fish in children.query<Fish>()) {
      if (!fish.isTaken) fish.position.x -= distance;
      if (fish.position.x < -80) fish.removeFromParent();
    }
  }

  void _placeThings() {
    final placed = _world.next(_scrolled, size.x);
    if (placed == null) return;

    // distance is measured from the start of the run; x is where that lands on
    // screen right now.
    final x = placed.distance - _scrolled;
    final kind = placed.kind;

    final y = switch (kind.action) {
      // Ground things sit on the ground line.
      ObstacleAction.jump || ObstacleAction.bounce => _groundY,
      // Duck things hang down from above, leaving a gap the ducked cat fits
      // through and a standing one does not.
      //
      // Positioned by where its BOTTOM EDGE must land, not by its own top:
      // every duck obstacle has a different hitbox height, so placing them all
      // at the same y put the pipe's and the washing line's lower edges above a
      // standing cat's head — the cat walked underneath and the duck button did
      // nothing at all. Deriving it per obstacle is what makes the mechanic
      // work for every one of them, including any added later.
      ObstacleAction.duck => _duckObstacleY(kind),
      // A block floats at head height for a jumping cat.
      // Just under the top of the arc, so a block is headbutted by a normal
      // jump rather than needing a bounce.
      ObstacleAction.block => _groundY - _jumpRise * 0.62,
    };

    add(Obstacle(kind: kind, position: Vector2(x, y), prize: placed.prize));

    // A fish in the gap after it, at an easy height.
    if (_world.wantsFish()) {
      add(
        Fish(
          position: Vector2(
            x + CatRunWorld.minGap * 0.5,
            _groundY - _world.fishHeight(_jumpRise) - 20,
          ),
        ),
      );
    }
  }

  /// Head-room left above a ducked cat. Generous: a duck that only just works
  /// is a duck that mostly does not.
  static const _duckClearance = 16.0;

  /// Where to place a duck obstacle so a ducked cat passes and a standing one
  /// does not.
  ///
  /// Both halves are asserted by a test, for every duck obstacle there is.
  /// [_duckObstacleY] for a given ground line, so a test can check the
  /// placement without standing up a whole game.
  @visibleForTesting
  static double duckObstacleYFor(ObstacleKind kind, double groundY) {
    // Where the obstacle's lower edge has to sit: just above a ducked cat.
    final bottom = groundY - Cat.duckedHeight - _duckClearance;
    // `position.y` is the obstacle's baseline, but its hitbox hangs from the
    // TOP of its art — and every duck obstacle has a different art-to-hitbox
    // inset. Working back through that inset per obstacle is the whole fix:
    // placing them all at one flat height left the pipe's and the washing
    // line's lower edges above a standing cat's head, so the cat walked
    // underneath and the duck button did nothing for two of the three.
    final insetTop = kind.size.height - kind.hitBox.height;
    return bottom + insetTop;
  }

  double _duckObstacleY(ObstacleKind kind) => duckObstacleYFor(kind, _groundY);

  /// The duck telegraph: flatten the ears and dip a cue, well before it lands.
  void _checkTelegraph(Cat cat) {
    Obstacle? upcoming;
    for (final obstacle in children.query<Obstacle>()) {
      if (obstacle.kind.action != ObstacleAction.duck) continue;
      if (obstacle.isSpent) continue;
      final ahead = obstacle.position.x - cat.position.x;
      if (ahead < 0 || ahead > CatRunWorld.duckTelegraph) continue;
      if (upcoming == null || ahead < upcoming.position.x - cat.position.x) {
        upcoming = obstacle;
      }
    }

    if (upcoming == null) {
      cat.earFlatten = 0;
      _telegraphing = null;
      return;
    }

    // Ears flatten progressively as it closes, so the warning grows rather
    // than switching on — a child tracks a rising signal more easily.
    final ahead = upcoming.position.x - cat.position.x;
    cat.earFlatten = 1 - (ahead / CatRunWorld.duckTelegraph);

    if (_telegraphing != upcoming) {
      _telegraphing = upcoming;
      // The "something is coming" cue. The softest sound in the app, and NOT a
      // warning noise: this is help, not a threat (CLAUDE.md §3).
      sounds.wobble();
    }
  }

  void _checkCollisions(Cat cat) {
    final catBox = cat.hitBox;

    for (final fish in children.query<Fish>()) {
      if (fish.isTaken) continue;
      if (catBox.overlaps(fish.hitBox)) _onFishTaken(fish);
    }

    for (final obstacle in children.query<Obstacle>()) {
      if (obstacle.isSpent) continue;
      if (!catBox.overlaps(obstacle.hitBox)) continue;

      switch (obstacle.kind.action) {
        case ObstacleAction.bounce:
          // Only a landing counts as a bounce; running into the side of a
          // mushroom just brushes past it. Nothing is ever squashed.
          if (cat.airHeight > 6 || !cat.isGrounded) {
            obstacle.markSpent(cleared: true);
            obstacle.react();
            cat.bounce();
            sounds.pop(progress: _chimeProgress);
            KidHaptics.pop();
            _onCleared(obstacle, silent: true);
          }
        case ObstacleAction.block:
          // Headbutted from below, mid-jump.
          obstacle.markSpent(cleared: true);
          obstacle.react();
          _popPrize(obstacle);
          _onCleared(obstacle, silent: true);
        case ObstacleAction.jump:
        case ObstacleAction.duck:
          _onBonk(obstacle);
      }
    }
  }

  /// The cat touched down. A landing on a bouncy thing is handled by the
  /// collision check; this is just the sound of feet.
  void _onCatLanded() {
    // Deliberately quiet. A landing happens constantly and must not compete
    // with the chime.
  }

  void _onFishTaken(Fish fish) {
    fish.take();
    _fishThisRound++;
    _stars.filled = _fishThisRound;
    sounds.pop(progress: _fishThisRound / fishPerCelebration);
    KidHaptics.pop();
    if (_fishThisRound >= fishPerCelebration) _celebrate();
  }

  /// Got past something cleanly. Climbs the chime ladder.
  ///
  /// [silent] for the things that already made their own noise (a bounce, a
  /// block), so one action is never two sounds.
  void _onCleared(Obstacle obstacle, {bool silent = false}) {
    obstacle.markSpent(cleared: true);
    _chimeRung++;
    if (!silent) {
      // The rising chime — the entire reward gradient for playing well. Each
      // clean clear is a note higher than the last.
      sounds.pop(progress: _chimeProgress);
    }
  }

  /// Where the chime sits, 0..1. Climbs with clean clears and wraps round at the
  /// top so it can always climb again — it never falls, and it never runs out.
  double get _chimeProgress => (_chimeRung % 8) / 7;

  /// Bonked. Plays the slapstick and carries on.
  ///
  /// Note what is NOT here: no life lost, no progress removed, no restart, no
  /// pause, no sad noise. The chime simply stops climbing until the next clean
  /// clear (see [_chimeRung]).
  void _onBonk(Obstacle obstacle) {
    obstacle.markSpent(cleared: false);
    obstacle.react();
    _cat?.bonk(obstacle.kind.missStyle);

    // The soft cue, and a puff of dust where it happened — the miss gets a
    // *nicer* response than silence, because it is meant to be funny rather
    // than something to avoid.
    sounds.wobble();
    final at = _cat?.position.x ?? size.x * catXFraction;
    _celebration.puff(Vector2(at + 20, _groundY - 20), pieces: 6);
    // No haptic. A physical jolt after a mistake is punishment, however small
    // (see KidHaptics).
  }

  void _popPrize(Obstacle block) {
    final prize = block.prize ?? BlockPrize.butterfly;
    add(
      Prize(
        kind: prize,
        position: Vector2(
          block.position.x + block.size.x / 2,
          block.position.y - block.size.y,
        ),
      ),
    );
    sounds.pop(progress: 1);
    KidHaptics.pop();
  }

  // --- the controls -------------------------------------------------------

  /// The paw button. Also wakes a sitting cat.
  ///
  /// Safe before the game has finished loading: a press that arrives in that
  /// gap is simply the child being quicker than the loader, and must never
  /// throw (see the note on [_cat]).
  void pressJump() {
    _sinceLastPress = 0;
    _cat?.jump();
  }

  /// The crouching-cat button.
  void pressDuck() {
    _sinceLastPress = 0;
    _cat?.duck();
  }

  void releaseDuck() => _cat?.releaseDuck();

  /// Exposed for tests and for the screen's idle handling.
  /// Only valid after [onLoad]; the tests that use it always await that.
  @visibleForTesting
  Cat get cat => _cat!;

  /// Only valid after [onLoad]; the tests that use it always await that.
  @visibleForTesting
  Scenery get scenery => _scenery!;

  @visibleForTesting
  double get speedFactor => _speedFactor;

  void _celebrate() {
    sounds.celebrate();
    KidHaptics.celebrate();
    _celebration.burst(size);
    _celebrations++;

    _fishThisRound = 0;
    // Empties in the same frame the confetti arrives, so the row is never seen
    // draining away (the same rule as Balloon Pop's stars).
    _stars.filled = 0;

    // **The world changes place** — the reward for a full row. Every
    // celebration, so a child who plays for two minutes sees the beach.
    _scenery?.changeTo(_scenery!.scene.next);

    // Hold off placing new things briefly so the confetti is the thing on
    // screen. The cat keeps running: stopping to acknowledge success breaks the
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

  /// How many scenes have been seen. Exposed for tests.
  @visibleForTesting
  int get celebrations => _celebrations;
}
