import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../../../shared/kid_shapes.dart';
import '../countdown.dart';

/// The countdown drawn as a *quantity*: ten stars in a jar, one leaving each
/// time the number changes.
///
/// This is the load-bearing answer to the one rule this game bumps into. A
/// countdown shows digits, and digits look like text to a child who cannot
/// read (CLAUDE.md §3). The jar says the same thing without any reading at
/// all: there used to be more, now there is less, soon there will be none.
/// The digit above it is for the child who is ready for digits — a treat, not
/// a toll.
///
/// The stars fly *out and up* when they leave, rather than vanishing, so
/// nothing is ever taken away invisibly.
class StarJar extends PositionComponent {
  StarJar({required this.countdown, required super.position})
    : super(anchor: Anchor.bottomCenter, size: Vector2(140, 190));

  final Countdown countdown;

  final _leaving = <_LeavingStar>[];
  int _lastSeen = Countdown.jarStars;
  final _random = Random();

  @override
  void update(double dt) {
    super.update(dt);

    final now = countdown.starsLeft;

    // One star flies off for each that has gone since the last frame.
    for (var i = now; i < _lastSeen; i++) {
      _leaving.add(
        _LeavingStar(
          from: _slot(i),
          drift: Vector2(
            (_random.nextDouble() - 0.5) * 120,
            -150 - _random.nextDouble() * 80,
          ),
          spin: (_random.nextDouble() - 0.5) * 6,
        ),
      );
    }
    _lastSeen = now;

    for (final star in _leaving) {
      star.update(dt);
    }
    _leaving.removeWhere((s) => s.life <= 0);
  }

  /// Where the star at [index] sits in the jar — stacked from the bottom up,
  /// in a loose pile rather than a grid, so it reads as "stuff in a jar"
  /// rather than as a progress bar.
  Offset _slot(int index) {
    final row = index ~/ 2;
    final col = index % 2;
    return Offset(
      size.x / 2 + (col == 0 ? -24 : 24) + (row.isEven ? -6 : 6),
      size.y - 34 - row * 30.0,
    );
  }

  @override
  void render(Canvas canvas) {
    final outline = Paint()
      ..color = KidPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round;

    // The jar: an open-topped glass, so stars leaving have somewhere to go.
    final jar = RRect.fromRectAndCorners(
      Rect.fromLTWH(12, 26, size.x - 24, size.y - 26),
      bottomLeft: const Radius.circular(26),
      bottomRight: const Radius.circular(26),
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
    );
    canvas.drawRRect(
      jar,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
    canvas.drawRRect(jar, outline);

    final shown = countdown.starsLeft;

    for (var i = 0; i < shown; i++) {
      final at = _slot(i);
      canvas.drawPath(KidShapes.star(at, 15), Paint()..color = KidPalette.star);
    }

    for (final star in _leaving) {
      canvas.save();
      canvas.translate(
        star.from.dx + star.travelled.x,
        star.from.dy + star.travelled.y,
      );
      canvas.rotate(star.angle);
      canvas.drawPath(
        KidShapes.star(Offset.zero, 15 * (0.6 + star.life * 0.6)),
        Paint()..color = KidPalette.starBright.withValues(alpha: star.life),
      );
      canvas.restore();
    }
  }
}

class _LeavingStar {
  _LeavingStar({required this.from, required this.drift, required this.spin});

  final Offset from;
  final Vector2 drift;
  final double spin;
  final Vector2 travelled = Vector2.zero();
  double angle = 0;
  double life = 1;

  void update(double dt) {
    life -= dt * 0.8;
    angle += spin * dt;
    travelled.add(drift * dt);
    // Slows as it rises, so it drifts away rather than shooting off.
    drift.scale(1 - 0.9 * dt);
  }
}
