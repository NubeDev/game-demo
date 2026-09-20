import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../road.dart';

/// One thing on or beside the road, while it is on its way to the car.
///
/// A plain object rather than a Flame component, because everything here has to
/// be drawn **back to front** — a cone at the horizon must not paint over a cow
/// beside the car. Sorting one list per frame does that exactly; juggling Flame
/// priorities as things move would be the same job done less reliably.
class RoadThing {
  RoadThing({
    required this.kind,
    required this.distance,
    required this.lateral,
  });

  final RoadThingKind kind;

  /// How far into the trip it sits, in world pixels.
  final double distance;

  /// Where across the road it is. Mutable: the living things move aside.
  double lateral;

  /// Already done whatever it does — bounced away, been driven through, hopped
  /// in. Nothing is ever done twice.
  bool spent = false;

  /// Seconds since it reacted, or null if it has not. Drives the bounce, the
  /// splash and the wave.
  double? reactedAt;

  /// Which way it was knocked, so the bounce goes away from the car.
  double knockedTo = 1;

  /// How far ahead of the car this is, right now.
  double depthAt(double scrolled) => distance - scrolled;

  /// Start the reaction: a cone bounces away, a puddle splashes, a duck looks
  /// up. Only ever happens once — a thing that has reacted stays reacted.
  void react({double away = 1}) {
    reactedAt ??= 0;
    knockedTo = away;
  }

  /// Wave back at the horn. Unlike [react] this restarts every time, because a
  /// child leaning on the horn should see the cow answer every single press.
  void wave() => reactedAt = 0;

  void tick(double dt) {
    final at = reactedAt;
    if (at != null) reactedAt = at + dt;
  }
}

/// Draws everything on the road, furthest away first.
///
/// Holds the list as well as painting it: one owner means the game cannot
/// collide with something that is not on screen, or draw something it has
/// already forgotten about.
class Traffic extends PositionComponent with HasGameReference<FlameGame> {
  Traffic() : super(priority: -50);

  final things = <RoadThing>[];

  /// How far the trip has come. Set by the game each frame.
  double scrolled = 0;

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

  @override
  void update(double dt) {
    super.update(dt);
    for (final thing in things) {
      thing.tick(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    final v = view;

    // Back to front. Sorting a copy keeps the game's list in placement order,
    // which is the order the spawner reasons about.
    final sorted = [...things]
      ..sort((a, b) => b.distance.compareTo(a.distance));

    for (final thing in sorted) {
      final depth = thing.depthAt(scrolled);
      if (depth > Perspective.viewDepth || depth < -160) continue;
      _paint(canvas, v, thing, depth);
    }
  }

  void _paint(Canvas canvas, Perspective v, RoadThing thing, double depth) {
    final kind = thing.kind;
    final since = thing.reactedAt;

    // Knocked things fly away sideways and fade; everything else holds still.
    var lateral = thing.lateral;
    var lift = 0.0;
    var opacity = 1.0;
    if (since != null && kind.action == RoadAction.nudge) {
      lateral += thing.knockedTo * since * 1.6;
      // A comic hop: up, then down. It never lands on anything and nothing
      // breaks — it just tumbles off into the grass.
      lift = sin((since * 2.6).clamp(0.0, pi)) * 0.5;
      opacity = (1 - (since - 0.6) / 0.8).clamp(0.0, 1.0);
    }
    if (since != null && kind.action == RoadAction.pickUp) {
      // Hopping in: up and toward the car, fading as it is "aboard".
      lift = sin((since * 3.4).clamp(0.0, pi)) * 0.6;
      lateral += (0 - thing.lateral) * (since * 2.2).clamp(0.0, 1.0);
      opacity = (1 - (since - 0.25) / 0.35).clamp(0.0, 1.0);
    }

    final x = v.xAt(lateral, depth);
    final baseY = v.yAt(depth) - v.widthAt(lift, depth);
    final w = v.widthAt(kind.drawWidth, depth);
    final h = v.widthAt(kind.drawHeight, depth);
    if (w < 0.5 || h < 0.5) return;

    canvas.save();
    canvas.translate(x, baseY);
    if (opacity < 1) {
      canvas.saveLayer(
        Rect.fromCenter(center: Offset.zero, width: w * 4, height: h * 4),
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }

    switch (kind.action) {
      case RoadAction.driveThrough:
        _paintThrough(canvas, kind, w, h, since);
      case RoadAction.nudge:
        _paintNudge(canvas, kind, w, h, since);
      case RoadAction.pickUp:
      case RoadAction.stepsAside:
        _paintCreature(canvas, kind, w, h, since);
      case RoadAction.waver:
        _paintWaver(canvas, kind, w, h, since);
    }

    if (opacity < 1) canvas.restore();
    canvas.restore();
  }

  /// Flat things painted ON the road, plus the two that arch over it.
  void _paintThrough(
    Canvas canvas,
    RoadThingKind kind,
    double w,
    double h,
    double? since,
  ) {
    switch (kind.effect) {
      case ThroughEffect.repaint:
      case ThroughEffect.wash:
        // An arch over the road. Drawn as a thick band so it reads as a thing
        // to drive UNDER, with two legs on the verges.
        final band = h * 0.22;
        final arch = Rect.fromLTWH(-w / 2, -h, w, h);
        canvas.drawPath(
          Path()
            ..moveTo(arch.left, arch.bottom)
            ..lineTo(arch.left, arch.top + h * 0.45)
            ..quadraticBezierTo(
              0,
              arch.top - h * 0.25,
              arch.right,
              arch.top + h * 0.45,
            )
            ..lineTo(arch.right, arch.bottom)
            ..lineTo(arch.right - band, arch.bottom)
            ..lineTo(arch.right - band, arch.top + h * 0.6)
            ..quadraticBezierTo(
              0,
              arch.top + band * 0.4,
              arch.left + band,
              arch.top + h * 0.6,
            )
            ..lineTo(arch.left + band, arch.bottom)
            ..close(),
          Paint()..color = kind.color,
        );
        // A second, inner stripe: a rainbow needs at least two colours to read
        // as one at placeholder stage.
        canvas.drawPath(
          Path()
            ..moveTo(arch.left + band, arch.bottom)
            ..lineTo(arch.left + band, arch.top + h * 0.6)
            ..quadraticBezierTo(
              0,
              arch.top + band * 0.4,
              arch.right - band,
              arch.top + h * 0.6,
            )
            ..lineTo(arch.right - band, arch.bottom)
            ..lineTo(arch.right - band * 1.8, arch.bottom)
            ..lineTo(arch.right - band * 1.8, arch.top + h * 0.72)
            ..quadraticBezierTo(
              0,
              arch.top + band * 1.5,
              arch.left + band * 1.8,
              arch.top + h * 0.72,
            )
            ..lineTo(arch.left + band * 1.8, arch.bottom)
            ..close(),
          Paint()..color = kind.secondColor ?? kind.color,
        );

      case ThroughEffect.splash:
      case ThroughEffect.scatter:
      case ThroughEffect.muddy:
      case null:
        // A flat patch on the tarmac. Squashed vertically because it is lying
        // down and being looked at from a low angle.
        canvas.drawOval(
          Rect.fromCenter(center: Offset(0, -h / 2), width: w, height: h),
          Paint()..color = kind.color.withValues(alpha: 0.85),
        );
        if (since != null) {
          // Driven through: a ring of spray/leaves flying out.
          final spread = (since * 3).clamp(0.0, 1.0);
          final fade = (1 - since / 0.7).clamp(0.0, 1.0);
          for (var i = 0; i < 7; i++) {
            final a = i * pi * 2 / 7;
            canvas.drawCircle(
              Offset(cos(a) * w * spread, -h / 2 + sin(a) * h * spread * 1.6),
              w * 0.09,
              Paint()..color = kind.color.withValues(alpha: 0.7 * fade),
            );
          }
        }
    }
  }

  void _paintNudge(
    Canvas canvas,
    RoadThingKind kind,
    double w,
    double h,
    double? since,
  ) {
    // A gentle tilt once knocked, so it reads as tumbling rather than sliding.
    if (since != null) {
      canvas.rotate(since * 3.0 * kind.drawWidth * knockedSpin);
    }
    final body = Rect.fromLTWH(-w / 2, -h, w, h);
    switch (kind.id) {
      case 'cone':
        canvas.drawPath(
          Path()
            ..moveTo(0, body.top)
            ..lineTo(body.right, body.bottom)
            ..lineTo(body.left, body.bottom)
            ..close(),
          Paint()..color = kind.color,
        );
        canvas.drawRect(
          Rect.fromLTWH(body.left + w * 0.2, body.top + h * 0.45, w * 0.6, h * 0.16),
          Paint()..color = kind.secondColor ?? Colors.white,
        );
      case 'beach_ball':
        canvas.drawCircle(
          Offset(0, body.top + h / 2),
          w / 2,
          Paint()..color = kind.color,
        );
        canvas.drawPath(
          Path()
            ..moveTo(0, body.top)
            ..quadraticBezierTo(w * 0.3, body.top + h / 2, 0, body.bottom)
            ..quadraticBezierTo(-w * 0.1, body.top + h / 2, 0, body.top)
            ..close(),
          Paint()..color = kind.secondColor ?? Colors.white,
        );
      case 'bin':
        canvas.drawRRect(
          RRect.fromRectAndRadius(body, Radius.circular(w * 0.18)),
          Paint()..color = kind.color,
        );
        canvas.drawRect(
          Rect.fromLTWH(body.left - w * 0.08, body.top, w * 1.16, h * 0.16),
          Paint()..color = kind.color.withValues(alpha: 0.7),
        );
      default: // hay bale
        canvas.drawRRect(
          RRect.fromRectAndRadius(body, Radius.circular(h * 0.4)),
          Paint()..color = kind.color,
        );
        canvas.drawArc(body.deflate(w * 0.15), 0, pi * 2, false,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(1, w * 0.05));
    }
  }

  /// How much a knocked thing spins. Small: a cone cartwheeling across the
  /// screen is chaos, and this has to read as gentle and funny.
  static const knockedSpin = 0.7;

  /// A passenger waiting at the kerb, or something alive crossing the road.
  ///
  /// Both are drawn the same way on purpose: a child should read "that is an
  /// animal" and never have to work out which sort of animal it is before
  /// deciding what to do. Getting it wrong costs nothing either way.
  void _paintCreature(
    Canvas canvas,
    RoadThingKind kind,
    double w,
    double h,
    double? since,
  ) {
    final body = Rect.fromLTWH(-w / 2, -h, w, h * 0.72);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(h * 0.32)),
      Paint()..color = kind.color,
    );
    // Head, a bit higher and to one side — enough to read as facing the road.
    canvas.drawCircle(
      Offset(w * 0.22, -h * 0.72),
      w * 0.26,
      Paint()..color = kind.color,
    );
    // Two dot eyes, because a face is what makes a child want to stop for it.
    final eye = Paint()..color = kind.secondColor ?? const Color(0xFF4A3B33);
    canvas.drawCircle(Offset(w * 0.3, -h * 0.78), max(0.8, w * 0.05), eye);
    canvas.drawCircle(Offset(w * 0.14, -h * 0.78), max(0.8, w * 0.05), eye);
    // Legs.
    canvas.drawRect(
      Rect.fromLTWH(-w * 0.3, -h * 0.28, w * 0.16, h * 0.28),
      eye,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.16, -h * 0.28, w * 0.16, h * 0.28),
      eye,
    );

    // Waiting passengers bob, so the child's eye is drawn to them from a long
    // way off — it is the only thing on the road worth aiming at.
    if (since == null && kind.action == RoadAction.pickUp) {
      canvas.drawCircle(
        Offset(0, -h * 1.25),
        w * 0.1,
        Paint()..color = Colors.white.withValues(alpha: 0.75),
      );
    }
  }

  /// Out in the field: a cow, a tractor, a tree. Waves when beeped at.
  void _paintWaver(
    Canvas canvas,
    RoadThingKind kind,
    double w,
    double h,
    double? since,
  ) {
    // The wave: a small bounce that settles. Nothing here is ever reached, so
    // this is pure answer-to-the-horn.
    if (since != null && since < 1.2) {
      canvas.translate(0, -sin(since * pi * 3) * h * 0.18 * (1 - since / 1.2));
    }

    if (kind.id == 'tree') {
      canvas.drawRect(
        Rect.fromLTWH(-w * 0.09, -h * 0.45, w * 0.18, h * 0.45),
        Paint()..color = kind.secondColor ?? const Color(0xFF8D6742),
      );
      canvas.drawCircle(
        Offset(0, -h * 0.66),
        w * 0.44,
        Paint()..color = kind.color,
      );
      return;
    }

    final body = Rect.fromLTWH(-w / 2, -h * 0.9, w, h * 0.62);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(h * 0.2)),
      Paint()..color = kind.color,
    );
    if (kind.id == 'cow') {
      // Patches, so a white blob reads as a cow.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-w * 0.16, -h * 0.62),
          width: w * 0.3,
          height: h * 0.22,
        ),
        Paint()..color = kind.secondColor ?? Colors.black,
      );
      canvas.drawCircle(
        Offset(w * 0.4, -h * 0.78),
        w * 0.18,
        Paint()..color = kind.color,
      );
    } else {
      // Tractor: a big wheel and a little one.
      canvas.drawCircle(
        Offset(-w * 0.26, -h * 0.28),
        w * 0.2,
        Paint()..color = kind.secondColor ?? Colors.orange,
      );
      canvas.drawCircle(
        Offset(w * 0.3, -h * 0.28),
        w * 0.13,
        Paint()..color = kind.secondColor ?? Colors.orange,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(-w * 0.36, -h * 0.2, w * 0.72, h * 0.06),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );
  }
}
