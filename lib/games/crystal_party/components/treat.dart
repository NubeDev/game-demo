import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../world.dart';

/// A waterfall, a cloud, a flock of butterflies, a rainbow puddle.
///
/// **These have no failure state at all.** They cannot be missed (flying past
/// one costs nothing and makes no sound), they cannot be hit wrong, and nothing
/// counts them. They exist purely so that flying somewhere is its own reward —
/// the scope calls them *things that are a delight to fly straight through*,
/// and the delight is the entire specification.
class Treat extends PositionComponent {
  Treat({required this.kind, required super.position})
    : super(
        size: Vector2(kind.width, kind.height),
        anchor: Anchor.center,
      );

  final TreatKind kind;

  /// Flown through already, so one cloud does not fire every frame she is
  /// inside it.
  bool _used = false;
  bool get isUsed => _used;
  void use() => _used = true;

  double _time = 0;

  Rect get hitBox => Rect.fromCenter(
    center: Offset(position.x, position.y),
    // Full size, no inset: there is nothing to be fair about here, and a
    // generous box means flying NEAR a waterfall still sparkles.
    width: size.x,
    height: size.y,
  );

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    switch (kind) {
      case TreatKind.waterfall:
        _waterfall(canvas);
      case TreatKind.cloud:
        _cloud(canvas);
      case TreatKind.butterflies:
        _butterflies(canvas);
      case TreatKind.rainbowPuddle:
        _puddle(canvas);
    }
  }

  void _waterfall(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Radius.circular(size.x * 0.3),
      ),
      Paint()..color = const Color(0xFF9BDCF7).withValues(alpha: 0.75),
    );
    // Falling streaks. Slow and soft — water, not static.
    for (var i = 0; i < 5; i++) {
      final x = size.x * (0.14 + i * 0.18);
      final offset = (_time * 90 + i * 40) % size.y;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, offset, size.x * 0.07, size.y * 0.22),
          const Radius.circular(6),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.6),
      );
    }
    // The pool at the bottom.
    canvas.drawOval(
      Rect.fromLTWH(-size.x * 0.2, size.y * 0.9, size.x * 1.4, size.y * 0.12),
      Paint()..color = const Color(0xFF7FC9EC).withValues(alpha: 0.8),
    );
  }

  void _cloud(Canvas canvas) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.92);
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(size.x * (0.2 + i * 0.2), size.y * (0.5 + (i.isEven ? -0.08 : 0.08))),
        size.y * (0.36 + (i == 1 || i == 2 ? 0.12 : 0)),
        paint,
      );
    }
  }

  void _butterflies(Canvas canvas) {
    const colours = [
      Color(0xFFFFC46B),
      Color(0xFFFF9EC4),
      Color(0xFFA9D8FF),
      Color(0xFFC9A9F5),
      Color(0xFFFFE97A),
    ];
    for (var i = 0; i < 5; i++) {
      final a = _time * 1.4 + i * pi * 2 / 5;
      final centre = Offset(
        size.x * 0.5 + cos(a) * size.x * 0.32,
        size.y * 0.5 + sin(a * 1.3) * size.y * 0.3,
      );
      final flap = 0.5 + sin(_time * 9 + i) * 0.45;
      final paint = Paint()..color = colours[i];
      // Two wings, opening and closing.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centre.dx - 6 * flap, centre.dy),
          width: 13 * flap + 3,
          height: 15,
        ),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centre.dx + 6 * flap, centre.dy),
          width: 13 * flap + 3,
          height: 15,
        ),
        paint,
      );
    }
  }

  void _puddle(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFF9EC4),
            Color(0xFFFFE97A),
            Color(0xFF8FE3A0),
            Color(0xFF7FC9F5),
          ],
        ).createShader(rect)
        ..color = Colors.white,
    );
    // A soft highlight, so it reads as wet.
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.12, size.y * 0.16, size.x * 0.3, size.y * 0.24),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
  }
}
