import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../shared/celebration.dart';
import '../../shared/kid_haptics.dart';
import '../../shared/kid_sounds.dart';
import 'components/arch.dart';
import 'components/crystal.dart';
import 'components/prop.dart';
import 'components/sky.dart';
import 'components/trail.dart';
import 'components/treat.dart';
import 'components/unicorn.dart';
import 'lands.dart';
import 'world.dart';

/// Crystal Party.
///
/// A unicorn gallops left to right at one gentle speed forever. **Hold anywhere
/// and she rises on a rainbow; let go and she floats back down to a gallop.**
/// That is the whole control scheme — the entire screen is the button. Blue
/// crystals live low, pink ones float high, so going up and coming back down is
/// the skill, and sorting by colour happens as a side effect of flying well.
///
/// ## The one hard problem in this game
///
/// **"Collect them all" is a completion goal, and completion invites being
/// incomplete** — which is the shape of failure CLAUDE.md §3 forbids. Resolved
/// by making completion *guaranteed rather than earned*, in three places that
/// all have to stay true together:
///
///  1. **A missed crystal is not missed** ([_recycle]). Fly past one and it
///     twinkles, drifts, and the same colour is put back into the run ahead.
///  2. **The land does not end until the arch is full.** There is no distance,
///     no timer and no end of level — the only thing that finishes a land is
///     the arch filling, so nobody can run out of anything.
///  3. **The quiet help** ([CrystalPartyWorld.helpingColour]). A colour that
///     falls behind starts appearing more often and lower down, so a child who
///     cannot yet manage the hold still reaches the party. It is never
///     announced, and nothing on screen says it happened.
///
/// Together: **there is no state in which a child is one crystal short.**
///
/// ## Everything else that keeps it safe
///
///  * **No gravity, no falling, no crash, no ceiling bump** — see [Unicorn].
///  * **One speed, forever** ([CrystalPartyWorld.scrollSpeed]). Nothing in this
///    file reads elapsed time, distance or the child's performance to decide
///    how hard to be. Later lands are prettier, never harder.
///  * **Clipping a prop is slapstick, not a loss** ([_onClip]): a wobble, some
///    leaves, a soft boing, and the gallop carries on. Nothing is taken.
///  * **Leave it alone and she stops to eat a flower** ([idleTimeout]). The
///    world waits.
class CrystalPartyGame extends FlameGame {
  CrystalPartyGame({required this.sounds, Random? random})
    : _random = random ?? Random(),
      _world = CrystalPartyWorld(random: random);

  final KidSounds sounds;
  final Random _random;

  /// Owns every random decision, so a test can seed it and replay a run.
  final CrystalPartyWorld _world;

  /// How many crystals fill the arch — six a side, twelve a land.
  ///
  /// About a minute of flying at [CrystalPartyWorld.scrollSpeed]. Close to Cat
  /// Run's ten fish so the app's rhythm is consistent, and short enough that a
  /// child actually reaches the snowy mountain in one sitting. **It is one
  /// constant**: if a real child's thumb tires before the arch fills, the fix
  /// is to lower this, not to make the sky easier (the scope says so).
  static const crystalsPerSide = 6;

  /// How long with no touch before she slows to a trot and stops for a flower.
  static const idleTimeout = 6.0;

  /// How long she takes to slow to a stop.
  static const _slowDownSeconds = 1.4;

  /// How far left of the screen she flies. A third in, so there is plenty of
  /// sky visible ahead — the child has to see a crystal coming to choose a
  /// height for it.
  static const unicornXFraction = 0.3;

  // NOT `late final`. These are built in the async onLoad(), and the whole
  // screen is live from the moment it paints — so a child who holds during that
  // gap would hit a LateInitializationError. In a release build a thrown error
  // inside a gesture callback is swallowed, so the hold would silently do
  // nothing and the game would look broken. Nullable plus a guard in every
  // control is the honest version.
  Sky? _sky;
  Unicorn? _unicorn;
  Arch? _arch;
  Trail? _trail;
  late final Celebration _celebration;

  double _scrolled = 0;

  /// 0..1 — how much of full speed the world is moving at. Only ever driven by
  /// the idle behaviour, **never by difficulty**.
  double _speedFactor = 1;

  double _sinceLastTouch = 0;

  /// The rung of the rising chime, per colour — the two ladders that make blue
  /// and pink sound different. Never reset by anything that goes wrong.
  final _chimeRung = <CrystalColour, int>{
    CrystalColour.blue: 0,
    CrystalColour.pink: 0,
  };

  /// Colours whose crystal was flown past and owes the child a replacement.
  /// Drained by [_placeThings] — this is mechanism (1) of the guarantee.
  final _owed = <CrystalColour>[];

  /// How many lands have been finished. Only used to pick the next place.
  int _lands = 0;

  /// Paused only while the party plays.
  bool _placing = true;

  /// True while the arch is blazing and she is galloping through it.
  bool _partying = false;

  @override
  Color backgroundColor() => Land.meadow.skyBottom;

  @override
  Future<void> onLoad() async {
    final sky = Sky(random: _random);
    _sky = sky;
    add(sky);

    final arch = Arch(
      piecesPerSide: crystalsPerSide,
      position: Vector2.zero(),
    );
    _arch = arch;
    add(arch);
    _fitArch();

    final unicorn = Unicorn(
      position: Vector2(size.x * unicornXFraction, _groundY),
      onLanded: _onLanded,
      onLiftOff: _onLiftOff,
    );
    _unicorn = unicorn;
    unicorn.fitTo(headroom: _groundY);
    add(unicorn);

    final trail = Trail(position: Vector2.zero());
    _trail = trail;
    add(trail);

    _celebration = Celebration();
    add(_celebration);

    // NO Rive character yet. The scope asks whether this is finally the Rive
    // character's job, and it is the strongest candidate so far — but the
    // flight model was tuned against this exact body height, and a shape-drawn
    // unicorn proves the feel today. `lib/shared/rive_character.dart` stays
    // ready. See the README.

    // A gentle start: the first crystal is far enough away that the child gets
    // a few seconds of just watching her gallop before anything is offered.
    _world.next(0, size.x);
  }

  double get _groundY {
    final sky = _sky;
    return sky != null && sky.isMounted ? sky.groundY : size.y * 0.8;
  }

  /// The sky this screen has, which everything placed high is measured against.
  double get _ceiling => _unicorn?.ceiling ?? Unicorn.designCeiling;

  /// The arch sits on the horizon, centred and standing on the ground line.
  void _fitArch() {
    final arch = _arch;
    if (arch == null || size.x <= 0) return;
    // Sized against the sky, and placed so it stands on the ground line — it
    // is a thing in the world ON THE HORIZON, not an overlay.
    //
    // Deliberately modest: it has to be legible from the first second without
    // taking the sky the pink crystals live in, and without becoming the thing
    // the child is looking at instead of the unicorn.
    final height = min(size.y * 0.34, _groundY * 0.46);
    arch
      ..size = Vector2(height * 2.1, height)
      ..position = Vector2((size.x - height * 2.1) / 2, _groundY - height);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isMounted) return;
    final unicorn = _unicorn;
    if (unicorn != null) {
      unicorn.position = Vector2(size.x * unicornXFraction, _groundY);
      // Fit the sky to what this screen has: the design ceiling assumes a
      // tablet, and on a landscape phone it would carry her off the top.
      // Everything placed high reads `unicorn.ceiling`, not the constant, so
      // the crystals come down with her.
      unicorn.fitTo(headroom: _groundY);
    }
    _fitArch();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Nothing to run until onLoad has built the world. One guard here lets
    // every helper below take these as given.
    final unicorn = _unicorn;
    final sky = _sky;
    final arch = _arch;
    final trail = _trail;
    if (unicorn == null || sky == null || arch == null || trail == null) return;

    _sinceLastTouch += dt;
    _updateSpeed(dt, unicorn);

    final distance = CrystalPartyWorld.scrollSpeed * _speedFactor * dt;
    _scrolled += distance;
    sky.advance(distance);

    // The trail streams from just behind her tail, so it rises and falls with
    // her — the progress readout is attached to the thing the child is
    // watching, not parked in a corner.
    trail.origin = unicorn.trailAnchor;

    _moveThings(distance);
    if (_placing) _placeThings();
    _checkCollisions(unicorn);
  }

  /// The idle behaviour: slow to a trot, then stop and eat a flower.
  ///
  /// This is what gives the child back the control a scrolling world takes away
  /// (CLAUDE.md §3). It is not a pause screen and there is nothing to dismiss —
  /// any touch starts her again.
  void _updateSpeed(double dt, Unicorn unicorn) {
    final shouldRun = _sinceLastTouch < idleTimeout;
    final target = shouldRun ? 1.0 : 0.0;
    final step = dt / _slowDownSeconds;
    _speedFactor = target > _speedFactor
        ? min(target, _speedFactor + step * 3) // wakes up quickly
        : max(target, _speedFactor - step);
    if (_speedFactor <= 0.01) {
      unicorn.rest();
    } else {
      unicorn.wake();
    }
  }

  void _moveThings(double distance) {
    // `.toList()` on every one of these: `children.query()` returns a live
    // view, and removing a component while iterating it throws a concurrent
    // modification error. That would be a hard crash on a real device the
    // first time anything scrolled off the left edge.
    for (final crystal in children.query<Crystal>().toList()) {
      if (!crystal.isTaken) crystal.position.x -= distance;
      if (crystal.position.x < -80) {
        // Went past without being taken. **Owed back** — mechanism (1) of the
        // completion guarantee. Nothing is lost here; the same colour is put
        // into the run ahead.
        if (!crystal.isTaken) _recycle(crystal.colour);
        crystal.removeFromParent();
      }
    }
    for (final prop in children.query<Prop>().toList()) {
      prop.position.x -= distance;
      if (prop.position.x + prop.size.x < -60) prop.removeFromParent();
    }
    for (final treat in children.query<Treat>().toList()) {
      treat.position.x -= distance;
      if (treat.position.x + treat.size.x < -60) treat.removeFromParent();
    }
  }

  /// A crystal went by. It owes the child a replacement, and until that lands
  /// the arch is simply unfinished — which is why the land cannot end early.
  void _recycle(CrystalColour colour) => _owed.add(colour);

  /// How many crystals are owed back. Exposed for tests: this is the mechanism
  /// that makes the party unmissable, so it is worth pinning.
  @visibleForTesting
  int get owed => _owed.length;

  void _placeThings() {
    final placed = _world.next(_scrolled, size.x);
    if (placed == null) return;

    // distance is measured from the start of the run; x is where that lands on
    // screen right now.
    final x = placed.distance - _scrolled;

    final prop = placed.prop;
    if (prop != null) {
      add(
        Prop(
          kind: prop,
          position: Vector2(
            x,
            prop.groundStanding
                // Stands on the ground.
                ? _groundY
                // Hangs in the air with clear sky underneath, at a height she
                // drops under. Derived from HER ceiling, so on a short screen
                // the gap underneath stays flyable.
                : _groundY - _ceiling * 0.42 + prop.height,
          ),
        ),
      );
      return;
    }

    final treat = placed.treat;
    if (treat != null) {
      add(
        Treat(
          kind: treat,
          position: Vector2(
            x,
            treat.high
                ? _groundY - _ceiling * placed.heightFraction
                // A ground treat sits ON the ground: a waterfall's pool and a
                // puddle are both things she gallops through without rising.
                : _groundY - treat.height * 0.3,
          ),
        ),
      );
      return;
    }

    final colour = placed.crystal;
    if (colour == null) return;
    // An owed crystal jumps the queue: the colour the child missed is the one
    // that comes back, so the arch's lagging side is the one being refilled.
    final wanted = _owed.isNotEmpty ? _owed.removeAt(0) : colour;
    _addCrystal(
      wanted,
      x,
      wanted == colour ? placed.heightFraction : _world.crystalHeight(wanted),
    );
  }

  void _addCrystal(CrystalColour colour, double x, double heightFraction) {
    add(
      Crystal(
        colour: colour,
        position: Vector2(
          x,
          // Blue sits just above the grass; pink floats up in her sky.
          _groundY - 34 - _ceiling * heightFraction,
        ),
      ),
    );
  }

  void _checkCollisions(Unicorn unicorn) {
    final box = unicorn.hitBox;

    for (final crystal in children.query<Crystal>().toList()) {
      if (crystal.isTaken) continue;
      if (box.overlaps(crystal.hitBox)) _onCrystalTaken(crystal);
    }

    for (final treat in children.query<Treat>().toList()) {
      if (treat.isUsed) continue;
      if (box.overlaps(treat.hitBox)) _onTreat(treat, unicorn);
    }

    for (final prop in children.query<Prop>().toList()) {
      if (prop.isSpent) continue;
      if (box.overlaps(prop.hitBox)) _onClip(prop, unicorn);
    }
  }

  void _onCrystalTaken(Crystal crystal) {
    crystal.take();
    final colour = crystal.colour;

    // Behind her.
    _trail?.add_(colour);
    // And in front of her. **Progress is visible twice** (the scope).
    _arch?.addPiece(colour);
    _world.recordGathered(colour);

    // The chime: each crystal is the next note up, on its colour's own ladder,
    // so blue rings like a bell and pink chimes and the two sound different as
    // well as looking different (CLAUDE.md §3 — three cues, any one enough).
    final rung = _chimeRung[colour] = _chimeRung[colour]! + 1;
    sounds.pop(progress: chimeProgress(colour, rung));
    KidHaptics.pop();

    if (_arch?.isFull ?? false) _party();
  }

  /// Where the chime sits, 0..1, for a colour on its [rung].
  ///
  /// Blue climbs the lower half of the ladder and pink the upper half, so the
  /// two colours are distinguishable by ear alone. Both **wrap at the top so
  /// they can always climb again** — neither ever falls, and neither runs out.
  @visibleForTesting
  static double chimeProgress(CrystalColour colour, int rung) {
    final within = (rung % crystalsPerSide) / (crystalsPerSide - 1);
    return colour == CrystalColour.blue ? within * 0.45 : 0.55 + within * 0.45;
  }

  /// Flew through something lovely. **No failure branch exists here** — a treat
  /// is either enjoyed or simply not, and not enjoying one costs nothing and
  /// makes no sound.
  void _onTreat(Treat treat, Unicorn unicorn) {
    treat.use();
    switch (treat.kind) {
      case TreatKind.waterfall:
        unicorn.sparkleUp();
      case TreatKind.cloud:
        unicorn.fluffUp();
      case TreatKind.butterflies:
        unicorn.sparkleUp();
        // They swirl into the trail.
        _celebration.puff(unicorn.trailAnchor, pieces: 8);
      case TreatKind.rainbowPuddle:
        _celebration.puff(
          Vector2(unicorn.position.x, _groundY - 10),
          pieces: 6,
        );
    }
    // Deliberately quiet — a soft sparkle, not a reward cue. These are lovely,
    // not correct, and they must not compete with the crystal chime.
    sounds.pop(progress: 0.2);
  }

  /// Clipped a pine. **Keep the obstacle, delete the loss** (CLAUDE.md §3).
  ///
  /// Note what is NOT here: no height lost, no control taken, no crystal
  /// removed, no fall, no restart, no sad noise, and no haptic — a physical
  /// jolt after a mistake is punishment, however small (see [KidHaptics]).
  void _onClip(Prop prop, Unicorn unicorn) {
    prop.markSpent();
    prop.react();
    unicorn.wobble();

    // Leaves scatter — the miss gets a *nicer* response than silence, because
    // it is meant to be funny rather than something to avoid.
    sounds.wobble();
    _celebration.puff(
      Vector2(prop.position.x + prop.size.x / 2, prop.position.y - prop.size.y * 0.5),
      pieces: 7,
    );
  }

  void _onLanded() {
    // Deliberately quiet. She lands constantly and it must not compete with
    // the chime — the landing is felt in the animation, not heard.
  }

  void _onLiftOff() {
    // Also quiet. The rainbow trail is the feedback for rising, and a cue on
    // every lift-off would fire dozens of times a minute.
  }

  // --- the control --------------------------------------------------------

  /// A thumb went down, anywhere on the screen. Also wakes her from a rest.
  ///
  /// Safe before the game has finished loading: a hold that arrives in that gap
  /// is simply the child being quicker than the loader, and must never throw
  /// (see the note on [_unicorn]).
  void hold() {
    _sinceLastTouch = 0;
    _unicorn?.hold();
  }

  /// The thumb lifted. She floats down — this can never do anything else.
  void release() => _unicorn?.release();

  /// The party. The arch blazes, the whole land lights up, confetti.
  ///
  /// **Bright but SLOW.** A "crystal party" is a strobe waiting to happen and
  /// that is a real photosensitivity risk (CLAUDE.md §3). Big is achieved with
  /// scale and colour, never with rate — the blaze swells over
  /// [Arch._blazeSeconds] and nothing here changes faster than about twice a
  /// second. A future session making this feel bigger must add size, not speed.
  void _party() {
    if (_partying) return;
    _partying = true;

    _arch?.startBlaze();
    sounds.celebrate();
    KidHaptics.celebrate();
    _celebration.burst(size);
    _lands++;

    // Stop offering new things so the party is the thing on screen. She keeps
    // galloping — she gallops THROUGH the arch, and there is no "well done"
    // screen to dismiss.
    _placing = false;

    add(
      TimerComponent(
        period: _partySeconds,
        removeOnFinish: true,
        onTick: _nextLand,
      ),
    );
  }

  /// How long the party lasts before the next land fades in. Long enough to
  /// watch, short enough that a child who wants to fly again is not waiting.
  static const _partySeconds = 3.4;

  /// Then the next land, always, forever.
  void _nextLand() {
    // The trail empties in the same frame the new land arrives, so the child
    // never watches it drain (the same rule as Balloon Pop's stars).
    _trail?.clear();
    _arch?.reset();
    _world.resetLand();
    // Anything owed belonged to the land that just finished. It was already
    // honoured — the arch filled — so carrying it forward would quietly make
    // the next land's colours lopsided for no reason.
    _owed.clear();

    _sky?.changeTo(_sky!.land.next);
    _partying = false;
    _placing = true;
  }

  // --- for tests ----------------------------------------------------------

  /// Only valid after [onLoad]; the tests that use these always await it.
  @visibleForTesting
  Unicorn get unicorn => _unicorn!;

  @visibleForTesting
  Arch get arch => _arch!;

  @visibleForTesting
  Trail get trail => _trail!;

  @visibleForTesting
  Sky get sky => _sky!;

  /// Named `spawner` rather than `world` because [FlameGame] already has a
  /// `world` of its own, of a different type.
  @visibleForTesting
  CrystalPartyWorld get spawner => _world;

  @visibleForTesting
  double get speedFactor => _speedFactor;

  @visibleForTesting
  int get lands => _lands;

  @visibleForTesting
  bool get isPartying => _partying;

  /// The ground line, so a test can place something at a known height.
  @visibleForTesting
  double get groundY => _groundY;
}
