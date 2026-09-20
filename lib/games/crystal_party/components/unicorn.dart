import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';

/// What the unicorn is doing right now.
enum UnicornState {
  /// Four hooves, gallop. The default and the resting state.
  galloping,

  /// Rising, or floating back down. The child is holding, or has just let go.
  flying,

  /// Mid-wobble after clipping a pine tree. Still flying, still fine.
  wobbling,

  /// Nobody has touched the screen for a while: slowed to a trot, then stopped
  /// to eat a flower. A touch always wakes her (CLAUDE.md §3: never stuck).
  resting,
}

/// The unicorn. Placeholder art, drawn in code: a white blob body, a round
/// head, a triangle horn, four legs that gallop, and a rainbow ribbon of a
/// tail.
///
/// ## The flight model is the whole game, and it is deliberately not physics
///
/// Gravity is the oldest way a game has of killing you, and this one has none.
/// What is here instead:
///
///  * **Holding raises her** at [riseSpeed], easing off as she nears the top so
///    she *settles* under the clouds rather than hitting a ceiling. There is no
///    bump, no clamp the child can feel, and nothing at the top of the screen.
///  * **Letting go floats her down** at [fallSpeed] — which is deliberately
///    SLOWER than the rise. A descent that matched the climb would read as
///    falling, and a five-year-old reads falling as danger. This is a leaf
///    coming down, not a stone.
///  * **Every landing is soft**: she touches down on four hooves with a
///    sparkle, at any speed, from any height. [_land] cannot fail.
///  * **There is no bottom.** [airHeight] never goes below zero, so there is
///    nothing under her but ground.
///
/// ## Why a hold and not a tap
///
/// The scope's open question, resolved in favour of hold for the build: a hold
/// has no rhythm to keep up and nothing to be late for. A flap is Flappy Bird,
/// which is a failure machine with the failure filed off. Left as a question
/// for the first real-child session — and swapping it is a change to
/// [hold]/[release] alone, nothing else in the game reads the control.
class Unicorn extends PositionComponent {
  Unicorn({required super.position, this.onLanded, this.onLiftOff})
    : super(size: Vector2(130, 104), anchor: Anchor.bottomCenter);

  /// She touched down on four hooves.
  final void Function()? onLanded;

  /// She left the ground.
  final void Function()? onLiftOff;

  /// How fast she rises while a thumb is down, in logical pixels per second.
  ///
  /// Tuned so [ceiling] takes about two seconds of hold from the ground — the
  /// scope's limit on what a small hand can be asked to do, and the number the
  /// sky's height is derived from rather than guessed at.
  static const riseSpeed = 300.0;

  /// How fast she floats down once the thumb lifts.
  ///
  /// **Slower than [riseSpeed] on purpose** — see the class doc. This is the
  /// single most important number in the game for making height feel safe.
  static const fallSpeed = 165.0;

  /// The design ceiling: how high she can get above the ground line.
  ///
  /// Like [riseSpeed], tuned against a two-second hold. Squeezed to fit a short
  /// screen by [fitTo], and everything that places a crystal reads [ceiling]
  /// rather than this constant, so the sky and its contents shrink together.
  static const designCeiling = 560.0;

  /// The smallest sky she is ever given, however short the screen. Below this
  /// the difference between low and high crystals stops being legible.
  static const minCeiling = 200.0;

  /// Space left above her head at the very top.
  static const _topMargin = 10.0;

  /// How fast the rise eases off near the top, as a fraction of [ceiling].
  ///
  /// Over this last stretch the climb tapers to nothing, so the top of the sky
  /// is a **settle, not a stop**. With a hard clamp the child felt the game
  /// take the control away; with the taper she simply runs out of sky the way a
  /// balloon does.
  static const _easeBand = 0.22;

  double _ceiling = designCeiling;

  /// The sky this screen actually has. Read this, never [designCeiling].
  double get ceiling => _ceiling;

  /// Fit the sky to the screen. [headroom] is the distance from the ground line
  /// to the top of the screen.
  ///
  /// Headroom loses to [minCeiling], not the other way round: a sky too short
  /// to tell high from low is a broken game, whereas a unicorn that flies close
  /// to the top of the screen is merely a good flight.
  void fitTo({required double headroom}) {
    _ceiling = max(
      minCeiling,
      min(designCeiling, headroom - size.y - _topMargin),
    );
    _air = _air.clamp(0.0, _ceiling);
  }

  UnicornState _state = UnicornState.galloping;
  UnicornState get state => _state;

  /// How far above the ground line she is. **Never negative** — there is no
  /// below.
  double _air = 0;
  double get airHeight => _air;

  bool get isGrounded => _air <= 0.01;

  /// Whether a thumb is currently down.
  bool _holding = false;
  bool get isHolding => _holding;

  /// Ticks the gallop, the wobble and the mane.
  double _time = 0;

  /// Counts down a wobble after clipping something. Purely cosmetic: she keeps
  /// flying throughout, and nothing about her control is taken away.
  double _wobble = 0;

  /// 0..1, how sparkly she is after a waterfall, how fluffy after a cloud.
  /// Decays on its own.
  double _sparkle = 0;
  double _fluff = 0;

  /// Set while she is resting, so the legs stop and she dips to a flower.
  bool _resting = false;

  /// A thumb went down, anywhere on the screen.
  void hold() {
    _holding = true;
    _resting = false;
  }

  /// The thumb lifted. She floats down from wherever she is — this can never
  /// do anything but start a gentle descent.
  void release() => _holding = false;

  /// Clipped a pine. A wobble and nothing else — no height lost, no control
  /// taken, no fall (CLAUDE.md §3: keep the obstacle, delete the loss).
  void wobble() => _wobble = 0.55;

  /// Came out of a waterfall.
  void sparkleUp() => _sparkle = 1;

  /// Came out of a cloud.
  void fluffUp() => _fluff = 1;

  /// Stop and eat a flower. The world has gone quiet.
  void rest() => _resting = true;

  /// Get going again. Any touch does this.
  void wake() => _resting = false;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_wobble > 0) _wobble = max(0, _wobble - dt);
    if (_sparkle > 0) _sparkle = max(0, _sparkle - dt * 0.55);
    if (_fluff > 0) _fluff = max(0, _fluff - dt * 0.45);

    final wasGrounded = isGrounded;

    if (_holding) {
      // The taper: full speed low down, easing to nothing at the top, so the
      // sky ends in a settle rather than a wall.
      final headroomLeft = (_ceiling - _air) / (_ceiling * _easeBand);
      final ease = headroomLeft.clamp(0.0, 1.0);
      _air = min(_ceiling, _air + riseSpeed * ease * dt);
      if (wasGrounded && _air > 0) onLiftOff?.call();
    } else if (_air > 0) {
      _air = max(0, _air - fallSpeed * dt);
      if (_air <= 0) _land();
    }

    _state = _resting
        ? UnicornState.resting
        : _wobble > 0
        ? UnicornState.wobbling
        : isGrounded
        ? UnicornState.galloping
        : UnicornState.flying;
  }

  /// Touched down. **Always on four hooves, always soft, from any height.**
  void _land() {
    _air = 0;
    onLanded?.call();
  }

  /// The box a crystal, a prop or a treat is tested against.
  ///
  /// Deliberately **smaller than the art**, and the inset is generous: a child
  /// who flew what looked like straight through a crystal must get it, and a
  /// clip of a pine that looked like a clear miss must not happen. The same
  /// generosity Cat Run bakes into its obstacle data, for the same reason.
  Rect get hitBox {
    final w = size.x * 0.52;
    final h = size.y * 0.6;
    return Rect.fromCenter(
      center: Offset(position.x, position.y - _air - size.y * 0.5),
      width: w,
      height: h,
    );
  }

  /// Where the trail leaves her, in game coordinates — just behind the tail.
  Vector2 get trailAnchor =>
      Vector2(position.x - size.x * 0.42, position.y - _air - size.y * 0.52);

  @override
  void render(Canvas canvas) {
    canvas.save();
    // Air is applied here rather than to `position`, so the ground line stays
    // the one true reference for everything else in the game.
    canvas.translate(0, -_air);

    // The wobble: a small lean that settles, never a spin. A spinning unicorn
    // reads as crashing.
    if (_wobble > 0) {
      final t = _wobble / 0.55;
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(sin(t * pi * 5) * 0.12 * t);
      canvas.translate(-size.x / 2, -size.y / 2);
    }

    final flying = !isGrounded;
    final bodyTop = size.y * 0.32;

    // Legs first, so the body covers their tops.
    _renderLegs(canvas, flying: flying);

    // The rainbow tail, streaming behind. Longer and more spread in the air —
    // this is the visible difference between galloping and flying, at a glance.
    _renderTail(canvas, flying: flying);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.x * 0.12, bodyTop, size.x * 0.62, size.y * 0.42),
      Radius.circular(size.y * 0.21),
    );
    canvas.drawRRect(body, Paint()..color = _coat);

    // Head, up and forward.
    final headCentre = Offset(size.x * 0.79, size.y * 0.26);
    canvas.drawCircle(headCentre, size.y * 0.19, Paint()..color = _coat);
    // The muzzle, so she has a face direction even as a blob.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headCentre.dx + size.y * 0.13, headCentre.dy + size.y * 0.07),
        width: size.y * 0.2,
        height: size.y * 0.15,
      ),
      Paint()..color = _coat,
    );
    // An eye. Open, friendly, and it never changes — nothing in this game
    // makes her look worried.
    canvas.drawCircle(
      Offset(headCentre.dx + size.y * 0.04, headCentre.dy - size.y * 0.03),
      size.y * 0.035,
      Paint()..color = KidPalette.ink,
    );

    // The horn: a triangle, gold, pointing up and slightly forward.
    final hornBase = Offset(headCentre.dx + size.y * 0.02, headCentre.dy - size.y * 0.16);
    canvas.drawPath(
      Path()
        ..moveTo(hornBase.dx - size.y * 0.05, hornBase.dy)
        ..lineTo(hornBase.dx + size.y * 0.05, hornBase.dy)
        ..lineTo(hornBase.dx + size.y * 0.03, hornBase.dy - size.y * 0.26)
        ..close(),
      Paint()..color = const Color(0xFFFFD98E),
    );

    // The mane, a few rainbow tufts along the neck.
    for (var i = 0; i < 4; i++) {
      final t = i / 3;
      canvas.drawCircle(
        Offset(
          size.x * (0.58 + t * 0.2),
          size.y * (0.3 - t * 0.09) + sin(_time * 6 + i) * (flying ? 3 : 1.4),
        ),
        size.y * (0.085 - t * 0.02),
        Paint()..color = _rainbow[i % _rainbow.length],
      );
    }

    if (_sparkle > 0) _renderSparkle(canvas);
    if (_fluff > 0) _renderFluff(canvas);

    canvas.restore();
  }

  /// White, but fluffier and shinier after a cloud or a waterfall.
  Color get _coat => Color.lerp(
    const Color(0xFFFFFDFA),
    const Color(0xFFEAF6FF),
    _fluff.clamp(0.0, 1.0) * 0.6,
  )!;

  void _renderLegs(Canvas canvas, {required bool flying}) {
    final paint = Paint()
      ..color = _coat
      ..strokeWidth = size.y * 0.09
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 4; i++) {
      final x = size.x * (0.22 + (i % 2) * 0.36 + (i ~/ 2) * 0.07);
      final double swing;
      if (_resting) {
        // Standing still, four hooves down, head about to dip to a flower.
        swing = 0;
      } else if (flying) {
        // Tucked and gently cycling — she is not pedalling, she is floating.
        swing = sin(_time * 3 + i) * 0.1 - 0.22;
      } else {
        // The gallop: legs in two pairs, out of phase.
        swing = sin(_time * 11 + (i % 2) * pi) * 0.38;
      }
      final top = Offset(x, size.y * 0.66);
      canvas.drawLine(
        top,
        Offset(top.dx + sin(swing) * size.y * 0.3, top.dy + cos(swing) * size.y * 0.33),
        paint,
      );
    }
  }

  void _renderTail(Canvas canvas, {required bool flying}) {
    final root = Offset(size.x * 0.14, size.y * 0.4);
    // In the air the tail streams out flat behind her; at a gallop it swishes.
    final spread = flying ? 1.5 : 1.0;
    for (var i = 0; i < _rainbow.length; i++) {
      final t = i / (_rainbow.length - 1);
      final droop = flying ? 0.0 : size.y * 0.1;
      canvas.drawPath(
        Path()
          ..moveTo(root.dx, root.dy + t * size.y * 0.16)
          ..quadraticBezierTo(
            root.dx - size.x * 0.16 * spread,
            root.dy + t * size.y * 0.2 + droop + sin(_time * 5 + i) * 3,
            root.dx - size.x * 0.3 * spread,
            root.dy + t * size.y * 0.3 + droop * 1.6 + sin(_time * 4 + i) * 4,
          ),
        Paint()
          ..color = _rainbow[i]
          ..strokeWidth = size.y * 0.075
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _renderSparkle(Canvas canvas) {
    final paint = Paint()..color = Colors.white.withValues(alpha: _sparkle * 0.9);
    for (var i = 0; i < 7; i++) {
      final a = _time * 2 + i * pi * 2 / 7;
      canvas.drawCircle(
        Offset(
          size.x * 0.45 + cos(a) * size.x * 0.4,
          size.y * 0.45 + sin(a) * size.y * 0.42,
        ),
        2.5 + sin(_time * 4 + i) * 1.2,
        paint,
      );
    }
  }

  void _renderFluff(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: _fluff * 0.55);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.x * (0.2 + i * 0.16), size.y * (0.3 + (i.isEven ? 0.04 : -0.04))),
        size.y * 0.14,
        paint,
      );
    }
  }

  /// The ribbon colours, used by the mane, the tail and the trail — one list so
  /// the rainbow is the same rainbow everywhere.
  static const _rainbow = <Color>[
    Color(0xFFFF8FA8),
    Color(0xFFFFC46B),
    Color(0xFFFFE97A),
    Color(0xFF8FE3A0),
    Color(0xFF7FC9F5),
    Color(0xFFC49BF0),
  ];

  /// Exposed so the trail and the celebration use the same rainbow.
  static List<Color> get rainbow => _rainbow;
}
