import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../../../shared/kid_shapes.dart';
import '../road.dart';

/// The car: the thing the child is actually holding on to.
///
/// Seen from behind, low down the screen, driving away from the viewer. It owns
/// its own steering — the game tells it where the thumb is ([steerTo]) and the
/// car decides how fast it is allowed to get there, the same way Cat Run's cat
/// owns its jump arc.
///
/// ## The smoothing is the whole control
///
/// A five-year-old's thumb is not steady, and mapping the car straight onto it
/// would make the car twitch and read as broken. [_ease] is a low pass on the
/// hand, and [maxLateralSpeed] is a cap on the car — together they mean a
/// jittery finger still draws a smooth line, which is the pre-writing motion
/// this game exists to practise (the scope's *Why*).
///
/// ## Nothing here can go wrong
///
/// There is no damage, no dirt that matters, no state the car can end up in
/// that is worse than any other. Mud is undone by the next car wash, a bump is
/// a wobble, and the colour is whatever the last rainbow made it
/// (CLAUDE.md §3).
class Car extends PositionComponent with HasGameReference<FlameGame> {
  Car({Random? random}) : _random = random ?? Random(), super(priority: 10);

  final Random _random;

  /// Drawn size, in road units.
  static const double drawWidth = 0.46;
  static const double drawHeight = 0.40;

  /// How wide the car is for the purpose of hitting things, in road units.
  /// A little narrower than it is drawn: see `road.dart` on generosity.
  static const double halfWidth = 0.18;

  /// How fast the car can cross the road, in road units per second. Crossing
  /// from one verge to the other takes about a second — fast enough to dodge,
  /// slow enough that a flick of the thumb never teleports it.
  static const double maxLateralSpeed = 2.6;

  /// How quickly the car closes the gap to the thumb. Higher is twitchier.
  static const double _ease = 9;

  double _lateral = 0;
  double _target = 0;

  /// Where the car is across the road. 0 is the centre line.
  double get lateral => _lateral;

  /// Whether the car is off the tarmac, on the drivable grass.
  bool get onVerge => _lateral.abs() > tarmacLateral;

  /// The colour it is painted right now. Changed by driving under a rainbow,
  /// and by nothing else.
  Color paint = KidPalette.playColors[0];

  /// 0..1, how muddy. Cosmetic only — a filthy car drives exactly like a clean
  /// one, because a penalty for driving through the fun thing would be a
  /// penalty for playing.
  double muddy = 0;

  double _wobble = 0;
  double _sparkle = 0;
  double _bumpy = 0;

  /// Frame time, for the wobbles. Driven by `update`, never by the wall clock:
  /// a clock-driven jiggle carries on while the game is paused and cannot be
  /// tested by stepping frames.
  double _time = 0;

  /// The passengers riding along, in the order they hopped in. They look out of
  /// the window, which is the only place the child can see how full the car is
  /// other than the dots.
  final aboard = <RoadThingKind>[];

  Perspective get view => Perspective(width: size.x, height: size.y);

  @override
  void onMount() {
    super.onMount();
    size = game.size;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x > 0 && size.y > 0) this.size = size;
  }

  /// Steer toward a point across the road. Clamped to the drivable width, so
  /// the car can always be steered and never leaves the world.
  void steerTo(double lateral) =>
      _target = lateral.clamp(-driveableLateral, driveableLateral);

  /// Put the car back in the middle, without a jump — used when a trip ends.
  void recentre() => _target = 0;

  /// Clipped something. A wobble and nothing else: no damage, no spin, no stop.
  void bump() => _wobble = 1;

  /// Drove through a puddle or a pile of leaves.
  void splash() => _wobble = max(_wobble, 0.45);

  /// Came out of the car wash.
  void sparkle() {
    _sparkle = 1;
    muddy = 0;
  }

  /// Went under a rainbow. Always a different colour from the current one, or
  /// the nicest thing in the game would sometimes visibly do nothing.
  void repaint() {
    final options =
        KidPalette.playColors.where((c) => c != paint).toList(growable: false);
    paint = options[_random.nextInt(options.length)];
  }

  /// Someone got in.
  void pickUp(RoadThingKind kind) => aboard.add(kind);

  /// Everyone piles out at the destination.
  void dropOff() => aboard.clear();

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Ease toward the thumb, then cap how fast the car may actually move.
    final remaining = _target - _lateral;
    final eased = remaining * min(1.0, dt * _ease);
    final cap = maxLateralSpeed * dt;
    _lateral += eased.clamp(-cap, cap);

    if (_wobble > 0) _wobble = max(0, _wobble - dt * 2.2);
    if (_sparkle > 0) _sparkle = max(0, _sparkle - dt * 0.8);
    // The grass is bumpy. A gentle rock, never a loss of control.
    _bumpy = onVerge ? min(1, _bumpy + dt * 4) : max(0, _bumpy - dt * 4);
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    final v = view;
    final w = v.widthAt(drawWidth, 0);
    final h = v.widthAt(drawHeight, 0);
    final x = v.xAt(_lateral, 0);
    final y = v.carY;

    canvas.save();
    canvas.translate(x, y);

    // A bump tips the car side to side; the grass jiggles it up and down.
    if (_wobble > 0) canvas.rotate(sin(_wobble * pi * 5) * 0.09 * _wobble);
    if (_bumpy > 0) canvas.translate(0, sin(_time * 17) * h * 0.02 * _bumpy);

    _renderShadow(canvas, w, h);
    _renderBody(canvas, w, h);
    _renderPassengers(canvas, w, h);
    if (muddy > 0) _renderMud(canvas, w, h);
    if (_sparkle > 0) _renderSparkle(canvas, w, h);

    canvas.restore();
  }

  void _renderShadow(Canvas canvas, double w, double h) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 1.05, height: h * 0.16),
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );
  }

  void _renderBody(Canvas canvas, double w, double h) {
    final body = Rect.fromLTWH(-w / 2, -h * 0.62, w, h * 0.6);

    // Wheels first, so the body sits over them.
    final tyre = Paint()..color = const Color(0xFF4A3B33);
    for (final side in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(side * (w * 0.5 - w * 0.12), -h * 0.24, w * 0.14, h * 0.26),
          Radius.circular(w * 0.05),
        ),
        tyre,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(h * 0.18)),
      Paint()..color = paint,
    );

    // The cabin, a little narrower, with a big window: the window is where the
    // passengers show, so it is deliberately oversized.
    final cabin = Rect.fromLTWH(-w * 0.34, -h, w * 0.68, h * 0.46);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabin, Radius.circular(h * 0.14)),
      Paint()..color = paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabin.deflate(w * 0.045), Radius.circular(h * 0.1)),
      Paint()..color = const Color(0xFFD9EFFA),
    );

    // Two rear lights. Warm amber rather than a hard red — nothing in this app
    // uses a full-saturation red, which reads as "stop"/"wrong" even to a
    // child who cannot read (see KidPalette).
    final lamp = Paint()..color = const Color(0xFFFFB03A);
    for (final side in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(side * w * 0.42 - (side > 0 ? w * 0.1 : 0), -h * 0.5, w * 0.1, h * 0.14),
          Radius.circular(w * 0.03),
        ),
        lamp,
      );
    }
  }

  /// Heads in the back window, one per passenger, so the car visibly fills up.
  void _renderPassengers(Canvas canvas, double w, double h) {
    if (aboard.isEmpty) return;
    // Only as many as fit across the window; the dots carry the count, this is
    // the picture of it.
    final shown = min(aboard.length, 4);
    final step = w * 0.5 / shown;
    for (var i = 0; i < shown; i++) {
      final kind = aboard[aboard.length - shown + i];
      final x = -step * (shown - 1) / 2 + i * step;
      canvas.drawCircle(
        Offset(x, -h * 0.78),
        max(1.5, w * 0.075),
        Paint()..color = kind.color,
      );
    }
  }

  void _renderMud(Canvas canvas, double w, double h) {
    final splat = Paint()
      ..color = const Color(0xFF7A5C38).withValues(alpha: 0.55 * muddy);
    for (var i = 0; i < 6; i++) {
      // Fixed offsets, not random per frame: mud that crawls around the car
      // every frame reads as a fault rather than as dirt.
      final a = i * pi * 2 / 6;
      canvas.drawCircle(
        Offset(cos(a) * w * 0.3, -h * 0.35 + sin(a) * h * 0.18),
        w * (0.06 + (i % 3) * 0.02),
        splat,
      );
    }
  }

  void _renderSparkle(Canvas canvas, double w, double h) {
    final paintStar = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 * _sparkle);
    for (var i = 0; i < 3; i++) {
      final a = -pi / 2 + (i - 1) * 0.9;
      canvas.drawPath(
        KidShapes.star(
          Offset(cos(a) * w * 0.55, -h * 0.8 + sin(a) * h * 0.3),
          w * 0.08 * (0.6 + _sparkle * 0.6),
        ),
        paintStar,
      );
    }
  }
}
