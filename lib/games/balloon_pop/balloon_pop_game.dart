import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../shared/celebration.dart';
import '../../shared/kid_haptics.dart';
import '../../shared/kid_palette.dart';
import '../../shared/kid_sounds.dart';
import '../../shared/rive_character.dart';
import 'assets.dart';
import 'components/balloon.dart';
import 'components/progress_stars.dart';
import 'components/sky.dart';

/// Balloon Pop.
///
/// Balloons float up through a drifting sky; touching one pops it with a sound
/// and a burst of rubber. Every [popsPerCelebration] pops there is a
/// celebration, then more balloons. It never ends and it cannot be lost:
///
///  * a balloon that reaches the top fades away — no sound, no penalty,
///    nothing subtracted;
///  * there is no timer, no miss counter, no accuracy, no streak;
///  * the progress stars only ever fill.
///
/// Three things here are about a five-year-old's hands rather than about
/// balloons, and are the difference between a game they can play and one they
/// can only watch:
///
///  * **A dragged finger pops.** Swiping is easier than aiming, and it is what
///    a child does naturally when they get excited. See [onDragUpdate].
///  * **Balloons come in three sizes** ([balloonRadii]), and the big slow ones
///    are the easy targets. Even the smallest touch target clears 80x80.
///  * **Touch targets are bigger than the art** ([Balloon.touchTargetRatio]),
///    so a near miss still counts.
class BalloonPopGame extends FlameGame with TapCallbacks, DragCallbacks {
  BalloonPopGame({required this.sounds});

  final KidSounds sounds;

  /// How many pops earn a celebration. Small enough that a child gets there
  /// quickly and often.
  static const popsPerCelebration = 10;

  /// The three balloon sizes, smallest first.
  ///
  /// The smallest must keep `radius * Balloon.touchTargetRatio` at or above the
  /// 80x80 floor (CLAUDE.md §3) — there is a test pinning this.
  static const balloonRadii = [38.0, 46.0, 56.0];

  /// At most this many balloons at once. Past this the screen stops reading as
  /// "balloons in a sky" and starts reading as clutter, and a child who cannot
  /// choose just stabs.
  static const maxBalloons = 7;

  /// Roughly one balloon in this many sparkles. Rare enough to stay a treat.
  static const sparklyInEvery = 7;

  /// How far from a dragged finger a balloon still pops, beyond its own touch
  /// target. A swipe is coarser than a tap, so it is more forgiving still.
  static const dragReach = 18.0;

  final _random = Random();

  late final Celebration _celebration;
  late final ProgressStars _stars;
  RiveCharacter? _character;

  /// Pops since the last celebration.
  int _popsThisRound = 0;

  /// Seconds until the next balloon spawns.
  double _spawnCountdown = 0;

  /// Seconds since the last empty-sky tap cue, and the minimum gap between
  /// them. Without this, drumming fingers produce a wall of sound.
  ///
  /// Starts "ready" so the very first tap of a session is answered — a child's
  /// opening tap must never be the one that gets silence.
  double _sinceLastMissCue = missCueInterval;

  /// Minimum gap between empty-sky cues.
  static const missCueInterval = 0.45;

  /// How many empty-sky cues have actually fired. Exposed for tests, which
  /// cannot hear the sound itself.
  @visibleForTesting
  int debugMissCueResetCount = 0;

  /// Paused only while a celebration plays, so the screen isn't busy at once.
  bool _spawning = true;

  @override
  Color backgroundColor() => KidPalette.skyBottom;

  @override
  Future<void> onLoad() async {
    // The drifting sky, behind everything.
    add(Sky());

    _stars = ProgressStars(
      total: popsPerCelebration,
      // Top-left, clear of the home button (which the screen puts top-right).
      position: Vector2(24, 24),
    );
    add(_stars);

    _celebration = Celebration();
    add(_celebration);

    // The Rive character watches from the bottom-left corner.
    //
    // It is added optimistically: if the file or its properties are missing,
    // RiveCharacter logs and does nothing, and the game still plays. A missing
    // character must never block the child.
    final character = RiveCharacter(
      assetPath: BalloonPopAssets.character,
      properties: balloonPopCharacterProperties,
      // Small and cornered: rewards.riv is a stand-in (it is a whole rewards
      // SCREEN, not a character), so it is kept out of the play area until real
      // character art replaces it.
      size: Vector2(150, 150),
      position: Vector2(16, size.y - 166),
    );
    _character = character;
    add(character);

    // A few balloons to start, so the screen is never empty on arrival.
    for (var i = 0; i < 3; i++) {
      _spawnBalloon(startY: size.y * (0.7 + i * 0.22));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _sinceLastMissCue += dt;

    if (_spawning) {
      _spawnCountdown -= dt;
      if (_spawnCountdown <= 0) {
        _spawnBalloon();
        // Sparse on purpose: too many balloons at once reads as chaos.
        // 1.2-2.2s keeps a few on screen without crowding.
        _spawnCountdown = 1.2 + _random.nextDouble() * 1.0;
      }
    }

    // Retire balloons that floated off the top. Not a failure — see class doc.
    for (final balloon in children.query<Balloon>()) {
      if (balloon.position.y < -balloon.size.y) {
        balloon.driftAway();
      }
    }
  }

  void _spawnBalloon({double? startY}) {
    if (children.query<Balloon>().length >= maxBalloons) return;

    final radius = balloonRadii[_random.nextInt(balloonRadii.length)];
    // Keep clear of the screen edges so nothing spawns half-off.
    final margin = radius * 1.6;
    final x = margin + _random.nextDouble() * max(1.0, size.x - margin * 2);

    add(Balloon(
      color: KidPalette.playColors[_random.nextInt(
        KidPalette.playColors.length,
      )],
      // Slow and varied, and the bigger the balloon the slower it climbs — so
      // the easiest target is also the one that hangs around longest. The
      // slowest is well within a five-year-old's reach; the fastest still gives
      // several seconds of screen time.
      riseSpeed: _riseSpeedFor(radius),
      radius: radius,
      sparkly: _random.nextInt(sparklyInEvery) == 0,
      position: Vector2(x, startY ?? size.y + radius * 2),
      onPopped: _onBalloonPopped,
    ));
  }

  /// Big balloons rise slowly, small ones a little quicker. Never fast enough
  /// to be a test of reaction time.
  double _riseSpeedFor(double radius) {
    final smallness =
        (balloonRadii.last - radius) / (balloonRadii.last - balloonRadii.first);
    return 30 + smallness * 18 + _random.nextDouble() * 14;
  }

  void _onBalloonPopped(Balloon balloon) {
    _popsThisRound++;
    _stars.filled = _popsThisRound;

    // The cue climbs as the stars fill — see KidSounds.pop.
    sounds.pop(progress: _popsThisRound / popsPerCelebration);
    KidHaptics.pop();

    // A sparkly balloon pays out where the child was looking. It is worth no
    // extra progress: there is no score, so a lucky balloon can only ever be a
    // better moment, never a bigger number (CLAUDE.md §3).
    if (balloon.sparkly) _celebration.puff(balloon.position.clone());

    // Build anticipation as the stars fill.
    _character?.setExcitement(_popsThisRound / popsPerCelebration);

    if (_popsThisRound >= popsPerCelebration) {
      _celebrate();
    }
  }

  /// A tap that landed on empty sky.
  ///
  /// Balloons handle their own taps, so this only runs when nothing was hit.
  /// It answers the child — a tap that produces nothing at all reads as the
  /// game being broken — but it is deliberately NOT a failure cue: no counter
  /// moves, no progress is lost, the sound is the quietest in the app, and
  /// there is no haptic (CLAUDE.md §3: never punish, never scold).
  ///
  /// Rate-limited so a child drumming on the screen gets a calm response
  /// rather than a stutter of overlapping sounds.
  @override
  void onTapDown(TapDownEvent event) {
    if (_sinceLastMissCue < missCueInterval) return;
    _sinceLastMissCue = 0;
    debugMissCueResetCount++;
    sounds.wobble();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    popBalloonsNear(event.canvasPosition);
  }

  /// A finger dragged across the screen pops everything it passes through.
  ///
  /// This is the single biggest accessibility win in the game. Aiming a tap at
  /// a moving target is a fine-motor skill a five-year-old is still building;
  /// sweeping an arm is not. It also matches what an excited child actually
  /// does — and a swipe that pops nothing reads as the game being broken.
  ///
  /// Deliberately NOT paired with the empty-sky cue: a drag across open sky
  /// would fire it over and over, which is exactly the nagging the wobble is
  /// rate-limited to avoid.
  @override
  void onDragUpdate(DragUpdateEvent event) {
    popBalloonsNear(event.canvasEndPosition);
  }

  /// Pops every balloon a finger at [point] is touching or nearly touching.
  @visibleForTesting
  void popBalloonsNear(Vector2 point) {
    for (final balloon in children.query<Balloon>()) {
      if (balloon.isSpent) continue;
      if (isWithinDragReach(balloon, point)) balloon.pop();
    }
  }

  /// Whether a finger at [point] counts as touching [balloon] during a swipe.
  ///
  /// Generous: the balloon's own (already forgiving) touch target, plus
  /// [dragReach], because a moving finger only samples a handful of points a
  /// second and the gaps between them are where a swipe would otherwise appear
  /// to pass straight through a balloon.
  ///
  /// Static and pure so it can be tested without loading the game, which needs
  /// `RiveNative.init()` and so cannot run under `flutter test`.
  static bool isWithinDragReach(Balloon balloon, Vector2 point) =>
      balloon.position.distanceTo(point) <= balloon.size.x / 2 + dragReach;

  /// The smallest touch target the game will ever spawn, in logical pixels.
  /// Pinned by a test against the 80x80 floor (CLAUDE.md §3).
  static double get smallestTouchTarget =>
      balloonRadii.reduce(min) * Balloon.touchTargetRatio;

  void _celebrate() {
    sounds.celebrate();
    KidHaptics.celebrate();
    _celebration.burst(size);
    _character?.celebrate();

    // Pause spawning briefly so the confetti is the thing on screen, then roll
    // straight back into play. There is no "well done" screen to dismiss: a
    // child cannot read one, and stopping play to acknowledge success breaks
    // the rhythm.
    _spawning = false;
    _popsThisRound = 0;
    // The row empties here, in the same frame the confetti arrives, rather than
    // later: balloons already in the air can still be popped during the pause,
    // and a row that emptied afterwards would visibly fall from ten back to one
    // — progress draining away, which is the one thing it must never do
    // (CLAUDE.md §3).
    _stars.filled = 0;

    add(TimerComponent(
      period: 1.8,
      removeOnFinish: true,
      onTick: () {
        _spawning = true;
        _character?.setExcitement(0);
        // Come back generous: a couple of balloons already on their way up, so
        // the moment after a celebration is the fullest the sky ever looks.
        _spawnBalloon();
        _spawnBalloon(startY: size.y * 0.9);
      },
    ));
  }
}

/// What the character's `.riv` file must expose.
///
/// These names match `rewards.riv` from the official flame_rive example, which
/// is a stand-in until real art exists. A custom file swaps these names and
/// needs no Dart changes — see `README.md` in this folder.
const balloonPopCharacterProperties = RiveCharacterProperties(
  // rewards.riv has no triggers of its own; it exposes nested numbers. The
  // excitement number below drives its coin counter, which is enough to prove
  // the data binding works end to end.
  excitementNumber: 'Coin/Item_Value',
  excitementScale: 100,
);
