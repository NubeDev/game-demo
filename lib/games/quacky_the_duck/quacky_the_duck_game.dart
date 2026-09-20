import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../shared/celebration.dart';
import '../../shared/kid_haptics.dart';
import '../../shared/kid_sounds.dart';
import 'components/chase_target.dart';
import 'components/hazard.dart';
import 'components/park_view.dart';
import 'components/progress_rolls.dart';
import 'components/quacky.dart';
import 'park.dart';
import 'world.dart';

/// Quacky the Duck.
///
/// A grumpy duck waddles left to right through a park at one gentle speed
/// forever. Somebody up ahead always has bread. The child presses the right
/// side to dash after them and the left side to skid under a bench. Catch up
/// and they laugh and tip the bread out; every treat lifts Quacky's eyebrows a
/// notch and fills a bread roll. A full row is a celebration and the park
/// changes.
///
/// ## The one hard problem in this game
///
/// **A chase is pressure-shaped.** Pursuit implies a gap that can fail to
/// close, and that is a loss with a friendly face on it — CLAUDE.md §3 forbids
/// losing outright. This is resolved by taking the outcome out of the chase
/// entirely:
///
///  * the gap closes **on its own** at [QuackyWorld.drift], so a child who
///    never once presses dash still eats every treat in the game — it just
///    takes [QuackyWorld.catchUpSeconds] instead of a few bursts;
///  * dashing is a **throttle on when**, never on whether ([_dashClose]);
///  * a beak-bonk **does not touch the gap** ([_onBonk]) — whatever he is
///    chasing waits for him.
///
/// If a future session ever makes a target genuinely outrun the player, this
/// game has quietly grown a fail state. [chaseGap] only ever decreases, and a
/// test pins that.
///
/// ## Everything else that makes it fair
///
///  * **One speed, forever** ([QuackyWorld.scrollSpeed]). No difficulty ramp
///    anywhere: nothing in this file reads elapsed time or distance to decide
///    how hard to be.
///  * **A floor on the spacing** ([QuackyWorld.minGap]), wider around a duck
///    hazard ([QuackyWorld.duckGap]).
///  * **Every duck hazard is telegraphed** — Quacky's neck goes flat and a soft
///    cue plays [QuackyWorld.duckTelegraph] px before it arrives.
///  * **Leave it alone and he sits down** ([idleTimeout]) rather than waddling
///    into benches unattended. The park stops, so the child can look.
class QuackyTheDuckGame extends FlameGame {
  QuackyTheDuckGame({required this.sounds, Random? random})
    : _world = QuackyWorld(random: random);

  final KidSounds sounds;

  /// Owns every random decision in the game, so a test can seed it and replay
  /// the same walk.
  final QuackyWorld _world;

  /// How many treats make a celebration. Same size as Cat Run's row and Balloon
  /// Pop's, so the rhythm of the app is consistent.
  static const treatsPerCelebration = 10;

  /// How long with no press before Quacky sits down on the path and grumbles.
  ///
  /// Long enough not to interrupt a child who is just watching, short enough
  /// that he is not left bonking into benches alone.
  static const idleTimeout = 6.0;

  /// How long he takes to slow to a stop when he sits.
  static const _slowDownSeconds = 1.2;

  /// How far left of the screen Quacky waddles. A quarter in, so there is
  /// plenty of path visible ahead — the child has to see the chase and the
  /// benches coming.
  static const quackyXFraction = 0.24;

  // NOT `late final`. These are built in the async onLoad(), and both play
  // buttons are live from the moment the screen paints — so a child who presses
  // during that gap would hit a LateInitializationError. In a release build
  // (and in a browser) a thrown error inside a gesture callback is swallowed,
  // so the button does nothing at all, silently, and it looks like the game is
  // broken. Nullable plus a guard in every control is the honest version.
  ParkView? _park;
  Quacky? _quacky;
  ChaseTarget? _target;
  late final ProgressRolls _rolls;
  late final Celebration _celebration;

  /// How far the park has scrolled.
  double _scrolled = 0;

  /// 0..1 — how much of full speed the park is moving at. Only ever driven by
  /// the idle behaviour, never by difficulty.
  double _speedFactor = 1;

  /// Seconds since the child last pressed anything.
  double _sinceLastPress = 0;

  /// Treats eaten since the last celebration.
  int _treatsThisRound = 0;

  /// The gap to whoever is up ahead, in logical pixels.
  ///
  /// **Only ever decreases** until the catch. This is the game's central
  /// promise expressed as one number, and a test pins it.
  double _chaseGap = QuackyWorld.startGap;

  /// Exposed for tests, which cannot watch the chase.
  @visibleForTesting
  double get chaseGap => _chaseGap;

  /// How many clean clears in a row, which is the chime ladder's rung.
  ///
  /// A bonk **does not reset this** — it simply stops it climbing until the
  /// next clean clear. A reset is the one place a miss could read as a
  /// punishment.
  int _chimeRung = 0;

  @visibleForTesting
  int get chimeRung => _chimeRung;

  /// Whether a duck telegraph is currently running, so the cue fires once.
  Hazard? _telegraphing;

  /// How many celebrations have happened. Only used to pick the next place.
  int _celebrations = 0;

  @visibleForTesting
  int get celebrations => _celebrations;

  /// Paused only while the confetti plays.
  bool _placing = true;

  /// What was chased last, so the next one is different.
  ChaseKind? _lastTarget;

  @override
  Color backgroundColor() => ParkPlace.pond.skyBottom;

  @override
  Future<void> onLoad() async {
    final park = ParkView();
    _park = park;
    add(park);

    final quacky = Quacky(
      position: Vector2(size.x * quackyXFraction, _groundY),
    );
    _quacky = quacky;
    add(quacky);

    _rolls = ProgressRolls(
      total: treatsPerCelebration,
      // Top-left, clear of the home button (top-right) and both play buttons
      // (bottom corners).
      position: Vector2(24, 24),
    );
    add(_rolls);

    _celebration = Celebration();
    add(_celebration);

    // NO Rive character yet. A shape-drawn duck does everything this game
    // needs, and `Mood.brightness` is already the 0..1 a bound Rive number
    // would take if real art arrives — see `assets.dart`.

    _spawnTarget();

    // A gentle start: the first bench is far enough away that the child gets a
    // few seconds of just watching him waddle before anything is asked of them.
    _world.next(0, size.x);
  }

  double get _groundY {
    final park = _park;
    return park != null && park.isMounted ? park.groundY : size.y * 0.68;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isMounted) return;
    final quacky = _quacky;
    if (quacky != null) {
      quacky.position = Vector2(size.x * quackyXFraction, _groundY);
    }
    _positionTarget();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Nothing to run until onLoad has built the park. One guard here means
    // every helper below can take them as given.
    final quacky = _quacky;
    final park = _park;
    if (quacky == null || park == null) return;

    _sinceLastPress += dt;
    _updateSpeed(dt);

    final distance = QuackyWorld.scrollSpeed * _speedFactor * dt;
    _scrolled += distance;
    park.advance(distance);

    _updateChase(dt, quacky);
    _updateRespawn(dt);
    _updatePlacingHold(dt);
    _moveHazards(distance);
    if (_placing) _placeHazards();
    _checkTelegraph(quacky);
    _checkCollisions(quacky);
  }

  /// The idle behaviour: slow to a stop, sit down on the path and grumble.
  ///
  /// This is what gives the child back the control a scrolling world takes
  /// away (CLAUDE.md §3). It is not a pause screen and there is nothing to
  /// dismiss — any press starts him off again.
  void _updateSpeed(double dt) {
    final shouldWalk = _sinceLastPress < idleTimeout;
    final target = shouldWalk ? 1.0 : 0.0;
    final step = dt / _slowDownSeconds;
    _speedFactor = target > _speedFactor
        ? min(target, _speedFactor + step * 3) // wakes up quickly
        : max(target, _speedFactor - step);

    final quacky = _quacky;
    if (quacky == null) return;
    if (_speedFactor <= 0.01) {
      quacky.sit();
    } else {
      quacky.wake();
    }
  }

  // --- the chase ----------------------------------------------------------

  /// Close the gap, and hand over the treat when it is closed.
  ///
  /// The drift here is the no-fail promise in code: it runs **every frame the
  /// park is moving**, whether or not the child has ever touched the dash
  /// button.
  void _updateChase(double dt, Quacky quacky) {
    final target = _target;
    if (target == null || target.isHandingOver) return;

    // Only while the park is moving — a sitting duck is not gaining on anybody,
    // which is what makes the idle read as "stopped" rather than "cheating".
    _chaseGap = max(
      QuackyWorld.caughtWithin,
      _chaseGap - QuackyWorld.drift * _speedFactor * dt,
    );

    target.closeness = 1 -
        ((_chaseGap - QuackyWorld.caughtWithin) /
                (QuackyWorld.startGap - QuackyWorld.caughtWithin))
            .clamp(0.0, 1.0);
    _positionTarget();

    if (_chaseGap <= QuackyWorld.caughtWithin) _catchUp(target);
  }

  void _positionTarget() {
    final target = _target;
    final quacky = _quacky;
    if (target == null || quacky == null) return;
    target.position = Vector2(quacky.position.x + _chaseGap, _groundY);
  }

  /// Caught up. They laugh, turn round and tip the bread out.
  void _catchUp(ChaseTarget target) {
    target.handOver();
    _eat(target.kind.treat);

    // Clear it NOW so `_updateChase` stops closing a gap that is already
    // closed, but let the hand-over play before the next one appears —
    // nothing vanishes the instant it is caught.
    _target = null;
    _leaving = target;
    _respawnIn = _handOverSeconds;
  }

  /// How long the hand-over plays before the next target walks on.
  static const _handOverSeconds = 0.9;

  /// The one who has just given the bread over, still on screen.
  ChaseTarget? _leaving;

  /// Seconds until the next target appears, or negative when none is due.
  ///
  /// A plain countdown rather than a `TimerComponent` **on purpose**. Spawning
  /// the next target is the core loop of this game, and a component-based timer
  /// makes it depend on Flame's async add/load lifecycle: the component is only
  /// queued, and its load only completes when the event loop turns. That is
  /// invisible in production and silently dead in a synchronous test, which is
  /// exactly how the first version shipped a chase that stopped after one
  /// catch. A number counted down in [update] cannot do that.
  double _respawnIn = -1;

  void _updateRespawn(double dt) {
    if (_respawnIn < 0) return;
    _respawnIn -= dt;
    if (_respawnIn > 0) return;
    _respawnIn = -1;
    _leaving?.removeFromParent();
    _leaving = null;
    if (_target == null) _spawnTarget();
  }

  void _spawnTarget() {
    final kind = _world.nextTarget(_lastTarget);
    _lastTarget = kind;
    _chaseGap = QuackyWorld.startGap;
    final target = ChaseTarget(
      kind: kind,
      position: Vector2(
        (_quacky?.position.x ?? size.x * quackyXFraction) + _chaseGap,
        _groundY,
      ),
    );
    _target = target;
    add(target);
  }

  /// A treat eaten. The chomp, the roll, and one notch less grumpy.
  void _eat(TreatKind treat) {
    _treatsThisRound++;
    _rolls.filled = _treatsThisRound;

    // The mood only ever climbs within a round — see `Mood`.
    _quacky?.mood = Mood.forProgress(_treatsThisRound, treatsPerCelebration);

    // The chomp, climbing the ladder as the row fills, so the sound itself says
    // "nearly there" to a child who cannot read the row.
    sounds.pop(progress: _treatsThisRound / treatsPerCelebration);
    KidHaptics.pop();

    // A little burst of crumbs where he ate it.
    final at = _quacky?.position ?? Vector2(size.x * quackyXFraction, _groundY);
    _celebration.puff(Vector2(at.x + 40, _groundY - 40), pieces: 7);

    if (_treatsThisRound >= treatsPerCelebration) _celebrate();
  }

  // --- the path -----------------------------------------------------------

  void _moveHazards(double distance) {
    // A COPY of the list. `removeFromParent` mutates the component list while
    // it is being walked, and Flame's query returns the live one — Crystal
    // Party hit this exact crash the first time anything scrolled off screen.
    for (final hazard in children.query<Hazard>().toList()) {
      hazard.position.x -= distance;
      // Off the left edge: gone, and if it was never hit the child cleared it.
      if (hazard.position.x + hazard.size.x < -40) {
        if (!hazard.isSpent && hazard.kind.action == HazardAction.duck) {
          _onCleared(hazard);
        }
        hazard.removeFromParent();
      }
    }
  }

  void _placeHazards() {
    final placed = _world.next(_scrolled, size.x);
    if (placed == null) return;

    // distance is measured from the start of the walk; x is where that lands on
    // screen right now.
    final x = placed.distance - _scrolled;
    final kind = placed.kind;

    final y = switch (kind.action) {
      // Things to bump into sit on the ground.
      HazardAction.bump => _groundY,
      // Things to duck under hang down from above, leaving a gap a flat duck
      // fits through and a standing one does not.
      HazardAction.duck => _duckHazardY(kind),
    };

    add(Hazard(kind: kind, position: Vector2(x, y)));
  }

  /// Head-room left above a flat duck. Generous: a duck that only just works is
  /// a duck that mostly does not.
  static const _duckClearance = 18.0;

  /// Where to place a duck hazard so a flat Quacky passes and a standing one
  /// does not.
  ///
  /// Both halves are asserted by a test, for every duck hazard there is.
  ///
  /// `position.y` is the hazard's baseline, but its hitbox hangs from the TOP
  /// of its art — and every hazard has a different art-to-hitbox inset.
  /// Working back through that inset per hazard is what makes the mechanic work
  /// for all of them, including any added later. (Cat Run learnt this the hard
  /// way: placing them all at one flat height left two of its three duck
  /// obstacles above a standing cat's head, so the duck button did nothing.)
  @visibleForTesting
  static double duckHazardYFor(HazardKind kind, double groundY) {
    final bottom = groundY - Quacky.duckedHeight - _duckClearance;
    final insetTop = kind.size.height - kind.hitBox.height;
    return bottom + insetTop;
  }

  double _duckHazardY(HazardKind kind) => duckHazardYFor(kind, _groundY);

  /// The duck telegraph: stretch the neck flat and dip a cue, well before it
  /// lands.
  void _checkTelegraph(Quacky quacky) {
    Hazard? upcoming;
    for (final hazard in children.query<Hazard>()) {
      if (hazard.kind.action != HazardAction.duck) continue;
      if (hazard.isSpent) continue;
      final ahead = hazard.position.x - quacky.position.x;
      if (ahead < 0 || ahead > QuackyWorld.duckTelegraph) continue;
      if (upcoming == null || ahead < upcoming.position.x - quacky.position.x) {
        upcoming = hazard;
      }
    }

    if (upcoming == null) {
      _telegraphing = null;
      return;
    }

    if (_telegraphing != upcoming) {
      _telegraphing = upcoming;
      // The "something is coming" cue. The softest sound in the app, and NOT a
      // warning noise: this is help, not a threat (CLAUDE.md §3).
      sounds.wobble();
    }
  }

  void _checkCollisions(Quacky quacky) {
    final box = quacky.hitBox;

    for (final hazard in children.query<Hazard>()) {
      if (hazard.isSpent) continue;
      if (!box.overlaps(hazard.hitBox)) continue;

      switch (hazard.kind.action) {
        case HazardAction.bump:
          // Rattles, splashes, scatters — and he carries straight on. These
          // cannot be missed and are never required.
          hazard.markSpent(cleared: true);
          hazard.react();
          sounds.wobble();
        case HazardAction.duck:
          // Reaching here at all means he did NOT get under it: a flat duck
          // passes below the hitbox and never overlaps, which is what
          // [_checkPassed] is for.
          if (!quacky.isDucking) _onBonk(hazard);
      }
    }

    _checkPassed(quacky);
  }

  /// A duck hazard that has gone by without being bonked was skidded under.
  ///
  /// This is a separate check because **a successful duck produces no
  /// collision at all** — a flat Quacky passes below the hitbox, so there is
  /// nothing to detect at the moment of the skid. Waiting for it to scroll off
  /// the far edge of the screen instead would put the chime seconds after the
  /// press that earned it, which at five reads as the sound belonging to
  /// something else entirely.
  void _checkPassed(Quacky quacky) {
    for (final hazard in children.query<Hazard>()) {
      if (hazard.isSpent) continue;
      if (hazard.kind.action != HazardAction.duck) continue;
      // Its trailing edge is behind his leading edge: it is past him.
      if (hazard.hitBox.right < quacky.hitBox.left) _onCleared(hazard);
    }
  }

  /// Got under something cleanly. Climbs the chime ladder.
  void _onCleared(Hazard hazard) {
    if (hazard.isSpent) return;
    hazard.markSpent(cleared: true);
    _chimeRung++;
    // The rising chime — the reward gradient for playing well. Each clean skid
    // is a note higher than the last.
    sounds.pop(progress: _chimeProgress);
  }

  /// Where the chime sits, 0..1. Climbs with clean clears and wraps round at
  /// the top so it can always climb again — it never falls, and never runs out.
  double get _chimeProgress => (_chimeRung % 8) / 7;

  /// Bonked his beak. Plays the slapstick and carries on.
  ///
  /// Note what is NOT here: no life lost, no progress removed, no restart, no
  /// pause, no sad noise, and **[_chaseGap] is untouched** — whatever he is
  /// chasing waits for him. The chime simply stops climbing until the next
  /// clean clear.
  void _onBonk(Hazard hazard) {
    hazard.markSpent(cleared: false);
    hazard.react();
    _quacky?.bonk();

    // The soft cue, and a puff of feathers where it happened — the miss gets a
    // *nicer* response than silence, because it is meant to be funny rather
    // than something to avoid.
    sounds.wobble();
    final at = _quacky?.position.x ?? size.x * quackyXFraction;
    _celebration.puff(Vector2(at + 30, _groundY - 50), pieces: 8);
    // No haptic. A physical jolt after a mistake is punishment, however small
    // (see KidHaptics).
  }

  // --- the controls -------------------------------------------------------

  /// The dash button. Also wakes a sitting duck.
  ///
  /// Safe before the game has finished loading: a press that arrives in that
  /// gap is simply the child being quicker than the loader, and must never
  /// throw (see the note on [_quacky]).
  void pressDash() {
    _sinceLastPress = 0;
    _quacky?.dash();
    // A burst closes a chunk of the gap. This is the ONLY thing dash does to
    // the chase — it never affects whether the treat arrives, only when.
    final target = _target;
    if (target != null && !target.isHandingOver) {
      _chaseGap = max(
        QuackyWorld.caughtWithin,
        _chaseGap - QuackyWorld.startGap * QuackyWorld.dashClose,
      );
      _positionTarget();
    }
  }

  /// The flat-duck button.
  void pressDuck() {
    _sinceLastPress = 0;
    _quacky?.duck();
  }

  void releaseDuck() => _quacky?.releaseDuck();

  /// Only valid after [onLoad]; the tests that use it always await that.
  @visibleForTesting
  Quacky get quacky => _quacky!;

  /// Only valid after [onLoad]; the tests that use it always await that.
  @visibleForTesting
  ParkView get park => _park!;

  @visibleForTesting
  ChaseTarget? get target => _target;

  @visibleForTesting
  double get speedFactor => _speedFactor;

  @visibleForTesting
  int get treatsThisRound => _treatsThisRound;

  void _celebrate() {
    sounds.celebrate();
    KidHaptics.celebrate();
    _celebration.burst(size);
    _celebrations++;

    _treatsThisRound = 0;
    // Empties in the same frame the confetti arrives, so the row is never seen
    // draining away (the same rule as every other progress row here).
    _rolls.filled = 0;

    // **The park changes** — the reward for a full row. Every celebration, so a
    // child who plays for two minutes sees the bandstand.
    _park?.changeTo(_park!.place.next);

    // Hold off placing hazards briefly so the confetti is the thing on screen.
    // Quacky keeps waddling: stopping to acknowledge success breaks the rhythm,
    // and there is no "well done" screen to dismiss.
    _placing = false;
    _placingHeldFor = _celebrationHold;
  }

  /// How long hazards stop arriving after a celebration, so the confetti is the
  /// thing on screen. A countdown rather than a `TimerComponent`, for the same
  /// reason as [_respawnIn].
  static const _celebrationHold = 1.8;
  double _placingHeldFor = -1;

  void _updatePlacingHold(double dt) {
    if (_placingHeldFor < 0) return;
    _placingHeldFor -= dt;
    if (_placingHeldFor <= 0) {
      _placingHeldFor = -1;
      _placing = true;
    }
  }
}
