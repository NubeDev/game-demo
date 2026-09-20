import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../shared/celebration.dart';
import '../../shared/kid_haptics.dart';
import '../../shared/kid_sounds.dart';
import 'components/big_number.dart';
import 'components/launch_pad.dart';
import 'components/rocket.dart';
import 'components/star_jar.dart';
import 'countdown.dart';

/// Blast Off — the countdown.
///
/// The child sets a countdown going and watches it arrive. It is the first
/// thing in the app with anticipation in it, and the only one with a clock.
/// See `docs/scope/games/blast-off-scope.md` and this folder's README.
///
/// ## The rule this game bumps into, and how it is kept
///
/// CLAUDE.md §3 bans "any timer that can cause failure". This is a timer, so
/// the ban is kept by making failure structurally impossible rather than by
/// being careful:
///
///  * **Nothing is ever required before zero.** No task is attached to the
///    clock, so arriving at zero cannot be *failing* to arrive. If anything is
///    ever made to depend on beating this countdown, that is the bug — not the
///    countdown.
///  * **Zero is the nicest moment in the game.** It is a launch, a celebration
///    and a confetti burst, never an alarm. There is no buzzer in this app.
///  * **Stopping is free.** The stop button returns to waiting and nothing is
///    recorded, counted or lost.
///
/// ## What there is to *do* while waiting
///
/// A countdown is, by construction, a screen where the child is not in
/// control — so nothing here is dead. The rocket honks when poked, the clouds
/// puff, and the smoke and rattle build on their own so there is always
/// something new to look at.
class BlastOffGame extends FlameGame with TapCallbacks {
  BlastOffGame({required this.sounds, required this.countdown, this.onLaunch});

  final KidSounds sounds;
  final Countdown countdown;

  /// Told the moment the rocket goes, so the screen can start its own timer
  /// for the "again" button rather than reading a clock that stops ticking
  /// once the loop has nothing left to animate.
  final VoidCallback? onLaunch;

  late final LaunchPad _pad;
  late final Rocket _rocket;
  late final StarJar _jar;
  late final BigNumber _number;
  late final Celebration _celebration;

  /// How much of the bottom of the screen the control buttons own.
  ///
  /// The screen owns the buttons and this game owns the scene, and neither
  /// could see the other: both anchored themselves to the bottom of the
  /// canvas, so the rocket and the star jar were drawn straight through the
  /// button row. The buttons also stole taps meant for the rocket, which is
  /// tappable (it honks).
  ///
  /// The fix is this one number. The screen measures the band its buttons
  /// occupy and hands it over; the grass grows to fill that band, so the
  /// buttons sit ON the ground and the rocket stands clear above it.
  /// Held here rather than on the pad, because the screen sets it from its
  /// own `build` — which runs before the Flame loop has called `onLoad`, so
  /// there is no pad to put it on yet. `onLoad` reads it back out.
  double _bottomInset = 0;

  double get bottomInset => _bottomInset;

  set bottomInset(double value) {
    if (_bottomInset == value) return;
    _bottomInset = value;
    if (isLoaded) {
      _pad.bottomInset = value;
      _layoutScene();
    }
  }

  /// Set once per launch so the confetti and the roar fire exactly once.
  bool _launchAnnounced = false;

  @override
  Future<void> onLoad() async {
    _pad = LaunchPad(countdown: countdown, size: size)
      ..bottomInset = _bottomInset;
    await add(_pad);

    _rocket = Rocket(countdown: countdown, position: Vector2.zero());
    await add(_rocket);

    // Right of the rocket and low, where a thumb resting on the screen will
    // not cover it.
    _jar = StarJar(countdown: countdown, position: Vector2.zero());
    await add(_jar);

    _number = BigNumber(countdown: countdown, position: Vector2.zero());
    await add(_number);

    _celebration = Celebration();
    await add(_celebration);

    _layoutScene();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // `isLoaded` guards the first resize, which Flame delivers before onLoad
    // has built any of this.
    if (isLoaded) {
      _pad.size.setFrom(size);
      _layoutScene();
    }
  }

  /// Places everything relative to the pad, which moves as the grass grows.
  ///
  /// Called on load, on resize, and whenever the screen reports a different
  /// control band — so the scene is never laid out against a bottom edge the
  /// buttons have already claimed.
  void _layoutScene() {
    final padTop = _pad.padTop;

    // The rocket sizes itself: it grows with the chosen countdown length, so
    // all the scene can tell it is how much room there is to grow into.
    _rocket.fitTo(skyScale: _pad.maxSceneScale);
    _rocket.standOn(Vector2(size.x * 0.5, padTop));

    // The jar keeps the scene's scale and slides LEFT if a full-height jar
    // would reach into the home button's corner — see LaunchPad.jarRight. It
    // is the countdown a non-reading child actually follows, so it may not be
    // shrunk out of legibility to make room.
    final jarScale = _pad.jarScale;
    _jar.scale.setValues(jarScale, jarScale);
    _jar.position.setValues(size.x - _pad.jarRight, padTop + 4);

    // Centred in the sky that is left, rather than at a fixed fraction of the
    // screen — otherwise a taller ground puts the number in the grass.
    _number.position.setValues(size.x * 0.22, padTop * 0.45);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // A paused countdown does not advance at all — nothing drains while it
    // is held (see Countdown.pause).
    if (countdown.phase == CountdownPhase.paused) return;

    final reached = countdown.tick(dt);
    if (reached == null) return;

    if (reached == 0) {
      _onLaunch();
    } else {
      // One number, said once. The ladder climbs whatever the countdown's
      // length, so a five-minute tidy-up resolves into the launch the same
      // way a ten-second blast off does.
      sounds.count(countdown.soundRungsLeft, rungs: Countdown.soundRungs);
      _number.bump();
      // Only in the last three, and only the lightest tick the platform has.
      // A buzz on every number would read as urgency (CLAUDE.md §3).
      if (countdown.isFinalStretch) KidHaptics.tap();
    }
  }

  void _onLaunch() {
    if (_launchAnnounced) return;
    _launchAnnounced = true;
    sounds.launch();
    sounds.celebrate();
    KidHaptics.celebrate();
    _celebration.burst(size);
    onLaunch?.call();
  }

  /// Back to the pad, ready for another one.
  void again() {
    _launchAnnounced = false;
    _rocket.reset();
    countdown.stop();
  }

  /// Called when the child starts a countdown from the screen's GO button.
  void go() {
    _launchAnnounced = false;
    _rocket.reset();
    countdown.start();
    _number.bump();
  }

  @override
  void onTapDown(TapDownEvent event) {
    final at = event.localPosition;

    // The rocket answers first: it is the biggest, most obvious thing on
    // screen and the one a child will poke.
    if (_rocket.toRect().inflate(20).contains(at.toOffset())) {
      _rocket.honk();
      sounds.pop();
      KidHaptics.pop();
      return;
    }

    // Then the clouds. A tap that found neither is simply nothing — no sound,
    // no wobble. Missing is not an event in this game.
    if (_pad.cloudAt(at)) {
      sounds.tap();
    }
  }
}
