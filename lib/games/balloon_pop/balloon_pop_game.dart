import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../shared/celebration.dart';
import '../../shared/kid_haptics.dart';
import '../../shared/kid_palette.dart';
import '../../shared/kid_sounds.dart';
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
/// ## What there is to *do*
///
/// Tapping one balloon at a time is a thing to look at, not a thing to play.
/// Three mechanics give the child something to cause:
///
///  * **Bunches chain.** Balloons arrive in same-colour bunches, and popping
///    one sets its neighbours off in a ripple ([_enqueueChain]) with the pop
///    note climbing through the whole run. One tap, eight pops — cause and
///    effect, and the best thing in the game to discover.
///  * **Big balloons take three taps** and swell between them ([Balloon.taps]),
///    then burst into a shower of little ones. Every tap counts as progress, so
///    the middle taps are never wasted.
///  * **The sun and the clouds answer.** A tap that missed every balloon can
///    still be something the child did, rather than a near-miss. See [Sky].
///
/// ## What is about a five-year-old's hands
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
  static const maxBalloons = 9;

  /// An absolute ceiling that even a shower cannot pass.
  ///
  /// [maxBalloons] is the limit for ordinary spawning; a big balloon's shower
  /// deliberately ignores it, because that brief moment of plenty is the reward
  /// for three taps. This is the backstop: without it, a mechanic that spawns
  /// past the cap can stack with the next one, and "bright, friendly, calm"
  /// quietly becomes a screen a child cannot read (CLAUDE.md §3).
  static const maxBalloonsHard = maxBalloons + bigBalloonShower;

  /// Roughly one balloon in this many sparkles. Rare enough to stay a treat.
  static const sparklyInEvery = 7;

  /// How many balloons in a bunch, and how often a spawn is a bunch rather
  /// than a single balloon. Bunches are what make chains happen at all: with
  /// six colours scattered at random, two of a colour are almost never
  /// neighbours, and the child would never discover the ripple.
  static const bunchSize = 3;
  static const bunchInEvery = 3;

  /// How often a spawn is a big three-tap balloon.
  static const bigInEvery = 8;

  /// Taps a big balloon takes, and the radius it is drawn at.
  static const bigBalloonTaps = 3;
  static const bigBalloonRadius = 74.0;

  /// How many little balloons a big one bursts into.
  static const bigBalloonShower = 5;

  /// How close a same-colour balloon has to be to catch the ripple, and the
  /// gap between links in it.
  ///
  /// The gap matters as much as the radius: popped all at once a chain is one
  /// loud noise, but staggered it is a *run* — the child hears the pop note
  /// climb link by link and sees the ripple travel outward.
  static const chainRadius = 170.0;
  static const chainDelay = 0.11;

  /// How far from a dragged finger a balloon still pops, beyond its own touch
  /// target. A swipe is coarser than a tap, so it is more forgiving still.
  static const dragReach = 18.0;

  final _random = Random();

  late final Celebration _celebration;
  late final ProgressStars _stars;

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

  /// Balloons waiting their turn in a ripple, and the set of them, so a
  /// balloon caught by two chains at once is only queued once.
  final _pendingChain = <_ChainLink>[];
  final _queuedForChain = <Balloon>{};

  /// Links fired since the game started. Exposed for tests, which cannot watch
  /// a ripple travel.
  @visibleForTesting
  int debugChainLinksFired = 0;

  @override
  Color backgroundColor() => KidPalette.skyBottom;

  @override
  Future<void> onLoad() async {
    // The drifting sky, behind everything. It claims only taps that land on
    // the sun or a cloud — see Sky.containsLocalPoint.
    add(Sky(
      onSunTapped: (at) {
        sounds.tap();
        _celebration.puff(at, pieces: 8);
      },
      onCloudTapped: (at) {
        sounds.tap();
        _celebration.puff(at, pieces: 6);
      },
    ));

    _stars = ProgressStars(
      total: popsPerCelebration,
      // Top-left, clear of the home button (which the screen puts top-right).
      position: Vector2(24, 24),
    );
    add(_stars);

    _celebration = Celebration();
    add(_celebration);

    // NO Rive character yet. The plumbing for one is ready and unused:
    // lib/shared/rive_character.dart, plus the property names and the drop-in
    // steps in this folder's README. It is deliberately not wired to anything,
    // because the only .riv file to hand was the flame_rive example's rewards
    // SCREEN, which rendered as a small dark rectangle in the grass. A thing
    // that sits in the play area and does nothing when touched reads to a
    // five-year-old as the game being broken (CLAUDE.md §3), so nothing is
    // better than a stand-in until real character art exists.

    // A bunch and a single to start, so the screen is never empty on arrival —
    // and so the ripple is there to be discovered in the first few seconds.
    _spawnBunch(startY: size.y * 0.82);
    _spawnBalloon(startY: size.y * 1.05);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _sinceLastMissCue += dt;
    if (_pendingChain.isNotEmpty) _advanceChain(dt);

    if (_spawning) {
      _spawnCountdown -= dt;
      if (_spawnCountdown <= 0) {
        _spawnSomething();
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

  /// One spawn tick: usually a bunch, sometimes a big balloon, otherwise a
  /// single. Weighted so a child sees a bunch within the first few seconds —
  /// the ripple is the best thing here and it has to be discoverable.
  void _spawnSomething() {
    if (_random.nextInt(bigInEvery) == 0) {
      _spawnBigBalloon();
    } else if (_random.nextInt(bunchInEvery) == 0) {
      _spawnBunch();
    } else {
      _spawnBalloon();
    }
  }

  void _spawnBalloon({
    double? startY,
    Color? color,
    double? radius,
    Vector2? at,
    int taps = 1,
    double? riseSpeed,
    bool force = false,
  }) {
    final onScreen = children.query<Balloon>().length;
    if (onScreen >= maxBalloonsHard) return;
    if (!force && onScreen >= maxBalloons) return;

    final r = radius ?? balloonRadii[_random.nextInt(balloonRadii.length)];
    // Keep clear of the screen edges so nothing spawns half-off.
    final margin = r * 1.6;
    final x = margin + _random.nextDouble() * max(1.0, size.x - margin * 2);

    add(Balloon(
      color: color ??
          KidPalette.playColors[_random.nextInt(
            KidPalette.playColors.length,
          )],
      // Slow and varied, and the bigger the balloon the slower it climbs — so
      // the easiest target is also the one that hangs around longest. The
      // slowest is well within a five-year-old's reach; the fastest still gives
      // several seconds of screen time.
      riseSpeed: riseSpeed ?? _riseSpeedFor(r),
      radius: r,
      sparkly: _random.nextInt(sparklyInEvery) == 0,
      taps: taps,
      position: at ?? Vector2(x, startY ?? size.y + r * 2),
      onPopped: _onBalloonPopped,
    ));
  }

  /// A bunch: [bunchSize] balloons of the SAME colour, clustered close enough
  /// that popping one ripples through the rest.
  ///
  /// One colour is the whole point. A mixed cluster is just clutter; a matching
  /// one is a thing the child can learn to look for, and the first time they
  /// hit the middle of one is the best moment in the game.
  void _spawnBunch({double? startY}) {
    if (children.query<Balloon>().length + bunchSize > maxBalloons) {
      // No room for a whole bunch. A partial one would teach the ripple
      // unreliably, so send a single instead.
      _spawnBalloon(startY: startY);
      return;
    }

    final color =
        KidPalette.playColors[_random.nextInt(KidPalette.playColors.length)];
    final radius = balloonRadii[_random.nextInt(balloonRadii.length)];
    // One rise speed for the whole bunch, so it stays a bunch on the way up
    // rather than stringing out and quietly stopping being one.
    final speed = _riseSpeedFor(radius);
    final margin = radius * 2.4;
    final centreX = margin + _random.nextDouble() * max(1.0, size.x - margin * 2);
    final baseY = startY ?? size.y + radius * 2.4;

    for (var i = 0; i < bunchSize; i++) {
      // Spread well inside chainRadius, so the ripple is reliable even after
      // they have drifted apart a little.
      final spread = radius * 1.35;
      _spawnBalloon(
        color: color,
        radius: radius,
        riseSpeed: speed,
        force: true,
        at: Vector2(
          (centreX + (i - 1) * spread).clamp(margin, max(margin, size.x - margin)),
          baseY + (i.isOdd ? radius * 0.85 : 0),
        ),
      );
    }
  }

  /// A big balloon: three taps, swelling between them, then a shower.
  void _spawnBigBalloon({double? startY}) {
    _spawnBalloon(
      radius: bigBalloonRadius,
      taps: bigBalloonTaps,
      // Slower than anything else. It has to be tappable three times before it
      // leaves, or the three taps are a promise the game does not keep.
      riseSpeed: 22 + _random.nextDouble() * 6,
      startY: startY,
    );
  }

  /// A big balloon bursting: little balloons thrown out of it, already rising.
  ///
  /// This is the payoff for three taps, and it is deliberately *more to do*
  /// rather than more progress — the reward for popping is always another thing
  /// to pop (CLAUDE.md §3: nothing to be efficient at).
  void _burstIntoLittleOnes(Balloon source) {
    final small = balloonRadii.reduce(min);
    for (var i = 0; i < bigBalloonShower; i++) {
      final spread = (i - (bigBalloonShower - 1) / 2) * small * 1.6;
      _spawnBalloon(
        radius: small,
        force: true,
        riseSpeed: 40 + _random.nextDouble() * 22,
        at: Vector2(
          (source.position.x + spread).clamp(small * 1.6, max(small * 1.6, size.x - small * 1.6)),
          source.position.y + (i.isOdd ? small : 0),
        ),
      );
    }
  }

  /// Big balloons rise slowly, small ones a little quicker. Never fast enough
  /// to be a test of reaction time.
  double _riseSpeedFor(double radius) {
    final smallness =
        (balloonRadii.last - radius) / (balloonRadii.last - balloonRadii.first);
    return 30 + smallness * 18 + _random.nextDouble() * 14;
  }

  /// Every tap that counted, on any balloon — including the squeezes of a big
  /// one, which is why this checks [Balloon.isSpent] before doing anything that
  /// belongs to a balloon actually bursting.
  void _onBalloonPopped(Balloon balloon) {
    _popsThisRound++;
    _stars.filled = _popsThisRound;

    // The cue climbs as the stars fill — see KidSounds.pop. Through a ripple
    // this becomes a rising run rather than one noise repeated.
    sounds.pop(progress: _popsThisRound / popsPerCelebration);
    KidHaptics.pop();

    if (balloon.isSpent) {
      // A sparkly balloon pays out where the child was looking. It is worth no
      // extra progress: there is no score, so a lucky balloon can only ever be
      // a better moment, never a bigger number (CLAUDE.md §3).
      if (balloon.sparkly) _celebration.puff(balloon.position.clone());
      if (balloon.isBig) _burstIntoLittleOnes(balloon);
      _enqueueChain(balloon);
    }

    if (_popsThisRound >= popsPerCelebration) {
      _celebrate();
    }
  }

  /// Sets off the ripple: every same-colour balloon near [source] is queued to
  /// pop a moment later, and each of those queues its own neighbours in turn.
  ///
  /// It cannot run away: a balloon latches the moment it starts popping, and
  /// [_queuedForChain] stops one being queued twice, so the ripple visits each
  /// balloon at most once and dies out on its own.
  void _enqueueChain(Balloon source) {
    for (final other in children.query<Balloon>()) {
      if (_queuedForChain.contains(other)) continue;
      if (!catchesRipple(source, other)) continue;
      _queuedForChain.add(other);
      _pendingChain.add(_ChainLink(other, chainDelay));
    }
  }

  /// Whether [other] is caught by a ripple starting at [source].
  ///
  /// Same colour, near enough, and not already on its way out. Static and pure
  /// so it can be tested without loading the game, which needs
  /// `RiveNative.init()` and so cannot run under `flutter test`.
  static bool catchesRipple(Balloon source, Balloon other) {
    if (other == source || other.isSpent) return false;
    if (other.color != source.color) return false;
    return other.position.distanceTo(source.position) <= chainRadius;
  }

  /// Fires whichever links are due this frame.
  ///
  /// The pops happen after the queue has been drained rather than during, so a
  /// link that queues further links cannot disturb the list being walked.
  void _advanceChain(double dt) {
    final due = <Balloon>[];
    _pendingChain.removeWhere((link) {
      link.delay -= dt;
      if (link.delay > 0) return false;
      due.add(link.balloon);
      return true;
    });

    for (final balloon in due) {
      _queuedForChain.remove(balloon);
      // It may have been popped by a finger, or drifted off, while it waited.
      if (balloon.isSpent || !balloon.isMounted) continue;
      debugChainLinksFired++;
      balloon.pop();
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
        // Come back generous: a whole bunch already on its way up, so the
        // moment after a celebration is the fullest the sky ever looks — and
        // the first thing back is the thing most worth popping.
        _spawnBunch();
        _spawnBalloon(startY: size.y * 0.9);
      },
    ));
  }
}

/// One balloon waiting its turn in a ripple.
class _ChainLink {
  _ChainLink(this.balloon, this.delay);

  final Balloon balloon;
  double delay;
}
