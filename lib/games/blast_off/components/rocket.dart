import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../countdown.dart';

/// The rocket: placeholder art, drawn as coloured shapes.
///
/// It carries the whole build-up. As the countdown runs it rattles harder and
/// smokes more, so a child looking at the screen — not the digit, not the jar —
/// can still see that zero is getting close.
///
/// The build is deliberately *comic* rather than tense (CLAUDE.md §3): a
/// wobble and puffs of smoke, never a shudder, never anything that reads as
/// about to go wrong.
///
/// ## Why it changes size
///
/// The rocket is drawn bigger for a longer countdown and smaller for a
/// shorter one, and it grows or shrinks *while the child presses more and
/// less* — so the button they are pressing visibly does something to the
/// biggest thing on screen. It is the same information as the row of dots,
/// said where a five-year-old is already looking and without a number in it
/// (CLAUDE.md §3). See [CountdownLength.sizeFactor] and [fitTo].
class Rocket extends PositionComponent {
  Rocket({required this.countdown, required super.position})
    : super(anchor: Anchor.bottomCenter, size: Vector2(120, 220));

  final Countdown countdown;

  /// How fast the rocket is climbing, once it has gone. Accelerating rather
  /// than constant: the shove is the reward, and a child should feel it
  /// rather than watch it slide away.
  double _climb = 0;

  /// Where the rocket stands when it is not flying, so [reset] can put it
  /// back without the screen having to remember.
  ///
  /// Not final: the pad moves when the screen resizes, because the grass grows
  /// to clear the control buttons (see LaunchPad.groundHeight). A `late final`
  /// here meant the rocket snapped back to the pad it had on the FIRST frame
  /// after a launch, which on a resized window is somewhere else entirely.
  late Vector2 _home = position.clone();

  /// Time, for the idle bob and the rattle.
  double _t = 0;

  /// The biggest the sky can hold, handed over by the game, which gets it
  /// from the pad. See [fitTo].
  double _skyScale = 1;

  /// The scale actually drawn, and how fast it is moving. The rocket springs
  /// toward [_targetScale] rather than jumping to it: a size that changes
  /// smoothly reads as *this button made the rocket grow*, where a snap just
  /// looks like the picture was swapped.
  double _shownScale = 0;
  double _scaleSpeed = 0;

  /// Tells the rocket how much sky it has to grow into.
  ///
  /// [skyScale] is the biggest the pad says will still fit above the ground
  /// (LaunchPad.maxSceneScale). The rocket spreads the whole countdown ladder
  /// across the room between its floor and that ceiling, rather than scaling
  /// a fixed set of sizes down — so on a phone, where the sky is barely
  /// taller than the rocket, every rung is still a *visibly* different size
  /// instead of the long half of the ladder flattening into one big rocket.
  void fitTo({required double skyScale}) {
    _skyScale = skyScale;
    // First time through there is nothing to animate from — start at size.
    if (_shownScale == 0) {
      _shownScale = _targetScale;
      scale.setValues(_shownScale, _shownScale);
    }
  }

  /// The size this countdown length asks for: the ladder laid out between the
  /// smallest rocket allowed and the biggest this screen can hold.
  double get _targetScale {
    final big = min(maxScale, _skyScale);
    final small = max(minScale, big * _smallEndShare);
    return small + (big - small) * countdown.length.sizeStep;
  }

  /// The floor: the rocket is 120 wide at scale 1, and a touch target may not
  /// go below 80 logical pixels (CLAUDE.md §3). It is the shortest countdown
  /// that lands here, so the smallest rocket in the game is still pokeable.
  static const minScale = 80 / 120;

  /// The ceiling, on a screen with sky to spare. Past this the rocket stops
  /// reading as a rocket and starts reading as a wall.
  static const maxScale = 1.4;

  /// How much smaller the shortest countdown is than the longest, where there
  /// is room for the difference. Wide enough that a child sees it at a
  /// glance, narrow enough that "the little one" is still a proper rocket.
  static const _smallEndShare = 0.6;

  /// Set briefly when the child pokes it: the rocket honks and leans.
  double _honk = 0;

  final _random = Random();
  final _smoke = <_Puff>[];

  /// Where the smoke comes out, in parent coordinates.
  Vector2 get nozzle => position + Vector2(0, -6);

  void honk() => _honk = 1;

  /// Moves the rocket to a new pad and makes that its home.
  ///
  /// Only takes effect while the rocket is on the ground — a rocket in flight
  /// is left alone, so a resize mid-launch cannot yank it back down.
  void standOn(Vector2 at) {
    _home = at.clone();
    if (countdown.phase != CountdownPhase.launched) position.setFrom(_home);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _honk = max(0, _honk - dt * 2.2);
    _settleScale(dt);

    final counting = countdown.phase == CountdownPhase.counting;
    final launched = countdown.phase == CountdownPhase.launched;
    // Paused settles everything: the rattle stops and the smoke thins to the
    // idle trickle, so "held" cannot be mistaken for "stuck".

    if (launched) {
      _climb += dt * 900;
      position.y -= _climb * dt;
    }

    // Smoke: a slow drift while waiting, thickening as zero approaches, a
    // gout of it on the way up.
    final rate = launched
        ? 60.0
        : counting
        ? 2 + countdown.progress * 14
        : countdown.phase == CountdownPhase.paused
        ? 1.5
        : 0.0;
    if (rate > 0 && _random.nextDouble() < rate * dt) {
      _smoke.add(
        _Puff(
          offset: Vector2((_random.nextDouble() - 0.5) * 26, 0),
          radius: 10 + _random.nextDouble() * 14,
          drift: Vector2(
            (_random.nextDouble() - 0.5) * 30,
            30 + _random.nextDouble() * 40,
          ),
        ),
      );
    }
    for (final puff in _smoke) {
      puff.update(dt);
    }
    _smoke.removeWhere((p) => p.life <= 0);
  }

  /// Eases the drawn size toward the size the chosen length asks for.
  ///
  /// A soft spring, tuned just under critical damping, so the rocket arrives
  /// with a small bounce — growing is a little event, not a redraw. The
  /// result is clamped rather than left to overshoot: the bottom of that
  /// clamp is the 80px touch-target floor, which a bounce may not dip under
  /// even for a frame.
  void _settleScale(double dt) {
    final target = _targetScale;
    const stiffness = 180.0;
    const damping = 22.0;

    _scaleSpeed += (target - _shownScale) * stiffness * dt;
    _scaleSpeed -= _scaleSpeed * damping * dt;
    _shownScale = (_shownScale + _scaleSpeed * dt).clamp(
      minScale,
      max(minScale, min(maxScale, _skyScale)),
    );
    scale.setValues(_shownScale, _shownScale);
  }

  /// Puts the rocket back on its pad. Called when the child asks for another
  /// one — there is nothing else to undo, because nothing was scored.
  void reset() {
    _climb = 0;
    position.setFrom(_home);
    _smoke.clear();
  }

  @override
  void render(Canvas canvas) {
    final counting = countdown.phase == CountdownPhase.counting;

    // Rattle: nothing at all while waiting, rising to a visible shake at one.
    // Capped low on purpose — a violent shake reads as damage.
    final shake = counting
        ? countdown.progress * countdown.progress * 5.0
        : 0.0;
    final dx = counting ? sin(_t * 46) * shake : 0.0;
    final dy = counting ? sin(_t * 38) * shake * 0.5 : 0.0;
    // A slow bob while waiting, so the rocket is never a dead object.
    final bob = counting || countdown.phase == CountdownPhase.launched
        ? 0.0
        : sin(_t * 1.6) * 4;
    final lean = _honk * 0.12;

    canvas.save();
    canvas.translate(size.x / 2 + dx, size.y + dy + bob);
    canvas.rotate(lean * sin(_t * 30));

    _renderSmoke(canvas);

    final body = Paint()..color = KidPalette.playColors[4];
    final fin = Paint()..color = KidPalette.playColors[0];
    final outline = Paint()
      ..color = KidPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round;

    // Fins.
    for (final side in const [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(side * 26, -40)
        ..lineTo(side * 56, -4)
        ..lineTo(side * 26, -4)
        ..close();
      canvas.drawPath(path, fin);
      canvas.drawPath(path, outline);
    }

    // Body: a capsule with a nose cone.
    final bodyPath = Path()
      ..moveTo(-30, -6)
      ..lineTo(-30, -130)
      ..quadraticBezierTo(-30, -200, 0, -212)
      ..quadraticBezierTo(30, -200, 30, -130)
      ..lineTo(30, -6)
      ..close();
    canvas.drawPath(bodyPath, body);
    canvas.drawPath(bodyPath, outline);

    // Window. A round porthole is the friendliest shape available, and it is
    // where a Rive character would sit later.
    canvas.drawCircle(
      const Offset(0, -140),
      20,
      Paint()..color = KidPalette.skyBottom,
    );
    canvas.drawCircle(const Offset(0, -140), 20, outline);

    canvas.restore();
  }

  void _renderSmoke(Canvas canvas) {
    for (final puff in _smoke) {
      canvas.drawCircle(
        Offset(
          puff.offset.x + puff.travelled.x,
          puff.offset.y + puff.travelled.y,
        ),
        puff.radius * (0.6 + (1 - puff.life) * 0.9),
        Paint()..color = Colors.white.withValues(alpha: 0.55 * puff.life),
      );
    }
  }
}

class _Puff {
  _Puff({required this.offset, required this.radius, required this.drift});

  final Vector2 offset;
  final double radius;
  final Vector2 drift;
  final Vector2 travelled = Vector2.zero();
  double life = 1;

  void update(double dt) {
    life -= dt * 0.9;
    travelled.add(drift * dt);
  }
}
