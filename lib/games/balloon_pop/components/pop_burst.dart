import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_shapes.dart';

/// The burst a popped balloon leaves behind.
///
/// This is the whole point of popping, so it gets more attention than the
/// balloon it replaces. A balloon that merely disappeared would leave the
/// child's tap unanswered on screen — the sound would be the only evidence it
/// worked, and the sound might be muted.
///
/// Three things happen at once, all in the balloon's own colour so the child
/// reads it as "that one, the one I hit":
///  * rubber shreds fly outwards and fall, slowing as they go;
///  * a ring expands and fades, like the burst pushing the air out;
///  * sparkly balloons add a handful of stars.
///
/// Calm by design (CLAUDE.md §3): nothing flashes, nothing is white-hot,
/// everything fades rather than blinking out, and the whole thing is over in
/// about half a second so it never sits on top of the next balloon.
///
/// Drawn as ONE component rather than a component per shred: a child pops many
/// balloons a minute, and this keeps each pop at a fixed, tiny cost.
class PopBurst extends PositionComponent {
  PopBurst({
    required this.color,
    required this.radius,
    required super.position,
    this.sparkly = false,
    Random? random,
  })  : _random = random ?? Random(),
        super(anchor: Anchor.center, priority: 50) {
    for (var i = 0; i < _shredCount; i++) {
      // Spread evenly around the circle, then jittered — evenly spaced alone
      // looks mechanical, fully random leaves bald patches.
      final angle = (i / _shredCount) * pi * 2 + _random.nextDouble() * 0.5;
      _shreds.add(_Shred(
        direction: Vector2(cos(angle), sin(angle)),
        speed: radius * (2.6 + _random.nextDouble() * 2.4),
        spin: (_random.nextDouble() - 0.5) * 12,
        size: radius * (0.16 + _random.nextDouble() * 0.14),
      ));
    }
  }

  final Color color;

  /// The popped balloon's radius: the burst scales with what was hit, so a big
  /// balloon feels like a bigger event than a small one.
  final double radius;

  /// A sparkly balloon adds stars on top of the ordinary shreds.
  final bool sparkly;

  final Random _random;
  final _shreds = <_Shred>[];

  static const _shredCount = 9;

  /// Total length of the effect, in seconds. Short on purpose.
  static const _life = 0.55;

  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / _life).clamp(0.0, 1.0);
    // Ease out: everything is fastest at the moment of the pop and settles.
    final eased = 1 - pow(1 - p, 2.2).toDouble();
    final fade = (1 - p * p).clamp(0.0, 1.0);

    _renderRing(canvas, eased, fade);

    for (final shred in _shreds) {
      final travel = shred.speed * eased * _life;
      final offset = Offset(
        shred.direction.x * travel,
        // Gravity, so the shreds arc down instead of flying off in a starburst
        // — it reads as bits of rubber rather than an explosion.
        shred.direction.y * travel + 180 * (p * _life) * (p * _life) * 2.2,
      );

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(shred.spin * eased);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: shred.size * 1.6,
            height: shred.size,
          ),
          Radius.circular(shred.size * 0.5),
        ),
        Paint()..color = color.withValues(alpha: fade),
      );
      canvas.restore();
    }

    if (sparkly) _renderSparkles(canvas, eased, fade);
  }

  void _renderRing(Canvas canvas, double eased, double fade) {
    canvas.drawCircle(
      Offset.zero,
      radius * (0.55 + eased * 1.7),
      Paint()
        ..color = Colors.white.withValues(alpha: fade * 0.55)
        ..style = PaintingStyle.stroke
        // The ring thins as it grows, so it dissolves rather than stopping.
        ..strokeWidth = 7 * (1 - eased).clamp(0.0, 1.0) + 1,
    );
  }

  void _renderSparkles(Canvas canvas, double eased, double fade) {
    for (var i = 0; i < 6; i++) {
      final angle = -pi / 2 + (i / 6) * pi * 2;
      final travel = radius * (1.2 + eased * 1.6);
      canvas.drawPath(
        KidShapes.star(
          Offset(cos(angle) * travel, sin(angle) * travel),
          radius * 0.24 * (1 - eased * 0.5),
        ),
        Paint()..color = Colors.white.withValues(alpha: fade * 0.9),
      );
    }
  }
}

class _Shred {
  _Shred({
    required this.direction,
    required this.speed,
    required this.spin,
    required this.size,
  });

  final Vector2 direction;
  final double speed;
  final double spin;
  final double size;
}
