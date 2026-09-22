import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../park.dart';

/// Whoever is up ahead with the bread.
///
/// ## Nobody here is frightened
///
/// The single most important thing about this component (the scope's
/// *Kid-rules impact*): the child up ahead **runs backwards, facing Quacky,
/// waving the bag and laughing**. Nobody flees, nobody cries, and the moment of
/// contact is a shared joke — they turn and tip the bread out on purpose. A
/// five-year-old reads a frightened child as real, exactly as they read a hurt
/// animal as real, so [_renderFace] only ever draws a smile and this component
/// has no "scared" state to reach.
///
/// ## And nobody gets away
///
/// This component does not decide whether it is caught — the game closes the
/// gap on its own timer (`QuackyWorld.drift`) whether or not the child ever
/// presses dash. All this does is draw the gap it is given.
class ChaseTarget extends PositionComponent {
  ChaseTarget({required this.kind, required super.position})
    : super(size: Vector2(kind.size.width, kind.size.height),
            anchor: Anchor.bottomCenter);

  final ChaseKind kind;

  /// 0..1 — how close Quacky is. Drives the "oh here he comes" wiggle and, at
  /// the very end, the turn-and-tip.
  double closeness = 0;

  /// Set when caught, so the hand-over plays before it leaves.
  bool _handingOver = false;
  double _handTime = 0;

  bool get isHandingOver => _handingOver;

  void handOver() {
    if (_handingOver) return;
    _handingOver = true;
    _handTime = 0;
  }

  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_handingOver) _handTime += dt;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y);

    // A delighted little jig the closer he gets — they can see him coming and
    // they think it is funny.
    final jig = sin(_t * (6 + closeness * 6)) * (1 + closeness * 3);
    // On the hand-over they lean back and tip the bag out, both arms up.
    final tip = _handingOver ? min(1.0, _handTime / 0.35) : 0.0;
    canvas.rotate(-tip * 0.18);

    final ink = Paint()
      ..color = KidPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    switch (kind) {
      case ChaseKind.childWithBag:
      case ChaseKind.pushchair:
        _renderPerson(canvas, ink, jig, tip);
      case ChaseKind.duckWithCrust:
        _renderDuck(canvas, ink, jig, tip);
      case ChaseKind.pigeonWithSandwich:
        _renderPigeon(canvas, ink, jig, tip);
      case ChaseKind.foodDispenser:
        _renderDispenser(canvas, ink, tip);
    }

    canvas.restore();
  }

  void _renderPerson(Canvas canvas, Paint ink, double jig, double tip) {
    final w = size.x;
    final h = size.y;
    final pram = kind == ChaseKind.pushchair;

    // Body.
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -h * 0.42 + jig * 0.3),
        width: w * 0.62,
        height: h * 0.5,
      ),
      Radius.circular(w * 0.2),
    );
    canvas.drawRRect(body, Paint()..color = kind.color);
    canvas.drawRRect(body, ink);

    // Legs, running BACKWARDS — they are facing Quacky, not away from him.
    for (final side in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(side * w * 0.16, -h * 0.2),
        Offset(side * w * 0.16 + sin(_t * 8 + side) * 10, 0),
        Paint()
          ..color = KidPalette.ink
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }

    // Head.
    final head = Offset(0, -h * 0.76 + jig * 0.4);
    canvas.drawCircle(head, w * 0.24, Paint()..color = const Color(0xFFFFD9B8));
    canvas.drawCircle(head, w * 0.24, ink);
    _renderFace(canvas, head, w * 0.24);

    // The bread bag, held out towards Quacky — the thing being offered, and on
    // the hand-over it tips right over.
    final armY = -h * 0.5;
    final bagAt = Offset(-w * 0.42 - tip * 10, armY - 6 - tip * 14);
    canvas.drawLine(
      Offset(-w * 0.28, armY),
      bagAt,
      Paint()
        ..color = KidPalette.ink
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.save();
    canvas.translate(bagAt.dx, bagAt.dy);
    canvas.rotate(-tip * 2.4);
    final bag = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w * 0.36, height: h * 0.2),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(bag, Paint()..color = const Color(0xFFF2E2C4));
    canvas.drawRRect(bag, ink);
    canvas.restore();

    if (pram) {
      // Three wheels and a handle — enough to read as a pushchair.
      for (final dx in [-w * 0.26, w * 0.24]) {
        canvas.drawCircle(
          Offset(dx, -4),
          w * 0.11,
          Paint()..color = KidPalette.ink,
        );
      }
    }
  }

  void _renderDuck(Canvas canvas, Paint ink, double jig, double tip) {
    final w = size.x;
    final h = size.y;
    // Centred so the BOTTOM of the body sits on the ground line: the first
    // version left an 8%-of-height gap under it and the duck floated, which
    // only shows up when the game is actually run against a ground line.
    final body = Rect.fromCenter(
      center: Offset(0, -h * 0.37 + jig * 0.3),
      width: w * 0.86,
      height: h * 0.74,
    );
    canvas.drawOval(body, Paint()..color = kind.color);
    canvas.drawOval(body, ink);

    final head = Offset(-w * 0.3, -h * 0.84 + jig * 0.4);
    canvas.drawCircle(head, w * 0.2, Paint()..color = kind.color);
    canvas.drawCircle(head, w * 0.2, ink);
    _renderFace(canvas, head, w * 0.2, mirrored: true);

    // The crust in its beak, offered over — it SHARES, nothing is taken.
    final crust = Rect.fromCenter(
      center: Offset(-w * 0.58 - tip * 12, -h * 0.9 + tip * 10),
      width: w * 0.24,
      height: h * 0.18,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(crust, Radius.circular(w * 0.05)),
      Paint()..color = const Color(0xFFE2C089),
    );
  }

  void _renderPigeon(Canvas canvas, Paint ink, double jig, double tip) {
    final w = size.x;
    final h = size.y;
    final body = Rect.fromCenter(
      center: Offset(0, -h * 0.35 + jig * 0.3),
      width: w * 0.82,
      height: h * 0.7,
    );
    canvas.drawOval(body, Paint()..color = kind.color);
    canvas.drawOval(body, ink);
    final head = Offset(-w * 0.28, -h * 0.8 + jig * 0.4);
    canvas.drawCircle(head, w * 0.19, Paint()..color = kind.color);
    canvas.drawCircle(head, w * 0.19, ink);
    _renderFace(canvas, head, w * 0.19, mirrored: true);

    // Half a sandwich, given up with bad grace.
    canvas.drawPath(
      Path()
        ..moveTo(-w * 0.5 - tip * 10, -h * 0.85)
        ..lineTo(-w * 0.78 - tip * 10, -h * 0.62)
        ..lineTo(-w * 0.46 - tip * 10, -h * 0.58)
        ..close(),
      Paint()..color = const Color(0xFFF2E2C4),
    );
  }

  void _renderDispenser(Canvas canvas, Paint ink, double tip) {
    final w = size.x;
    final h = size.y;
    // A post with a hopper on top: the park's duck-food dispenser. Peas,
    // sweetcorn and pellets — the good stuff, and the nicest chomp in the game.
    canvas.drawRect(
      Rect.fromLTWH(-w * 0.1, -h * 0.66, w * 0.2, h * 0.66),
      Paint()..color = const Color(0xFF8C7A5B),
    );
    final hopper = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -h * 0.8),
        width: w * 0.78,
        height: h * 0.34,
      ),
      Radius.circular(w * 0.1),
    );
    canvas.drawRRect(hopper, Paint()..color = kind.color);
    canvas.drawRRect(hopper, ink);

    // Peas trickling out on the hand-over.
    if (tip > 0) {
      for (var i = 0; i < 6; i++) {
        canvas.drawCircle(
          Offset(-w * 0.1 + i * 6.0, -h * 0.6 + tip * (14 + i * 5)),
          4,
          Paint()..color = const Color(0xFF6FD97F),
        );
      }
    }
  }

  /// A face, and it is always a happy one.
  ///
  /// There is deliberately no unhappy branch in this method. See the class doc:
  /// nothing in this park is frightened of Quacky.
  void _renderFace(Canvas canvas, Offset c, double r, {bool mirrored = false}) {
    final dir = mirrored ? -1.0 : 1.0;
    final ink = Paint()..color = KidPalette.ink;
    canvas.drawCircle(Offset(c.dx + dir * r * 0.3, c.dy - r * 0.2), 3.4, ink);
    // An open, laughing mouth — a wide arc, never a straight line and never a
    // downturn.
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(c.dx + dir * r * 0.18, c.dy + r * 0.28),
        width: r * 0.9,
        height: r * 0.7,
      ),
      0,
      pi,
      false,
      Paint()
        ..color = KidPalette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }
}
