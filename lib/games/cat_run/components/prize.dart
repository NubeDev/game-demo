import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../../../shared/kid_shapes.dart';
import '../obstacles.dart';

/// What pops out of a headbutted block: a butterfly, a fish, a music note or a
/// shower of leaves.
///
/// It is pure payoff. It cannot be collected, it is worth no progress, and it
/// removes itself — the child cannot fail to catch it, because there is nothing
/// to catch (CLAUDE.md §3: nothing to be missed).
class Prize extends PositionComponent with HasPaint {
  Prize({required this.kind, required super.position})
    : super(size: Vector2.all(30), anchor: Anchor.center);

  final BlockPrize kind;

  final _random = Random();
  double _time = 0;

  @override
  Future<void> onLoad() async {
    paint.color = switch (kind) {
      BlockPrize.butterfly => KidPalette.playColors[5],
      BlockPrize.fish => KidPalette.playColors[4],
      BlockPrize.musicNote => KidPalette.playColors[0],
      BlockPrize.leaves => KidPalette.hillNear,
    };

    // Up and away, slowly, then fades. Slow enough to be watched: the whole
    // point is that the child sees what they got.
    add(
      MoveByEffect(
        Vector2(
          _random.nextDouble() * 60 - 20,
          -90 - _random.nextDouble() * 40,
        ),
        EffectController(duration: 1.3),
      ),
    );
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.45, startDelay: 0.85),
        onComplete: removeFromParent,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    switch (kind) {
      case BlockPrize.butterfly:
        // Two wings that flap. Flapping is what makes it a butterfly and not
        // a blue dot.
        final flap = 0.6 + sin(_time * 14).abs() * 0.4;
        for (final side in [-1.0, 1.0]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(c.dx + side * 7, c.dy),
              width: 13 * flap,
              height: 18,
            ),
            paint,
          );
        }
        canvas.drawCircle(
          c,
          3,
          Paint()..color = KidPalette.ink.withValues(alpha: paint.color.a),
        );
      case BlockPrize.fish:
        canvas.drawOval(
          Rect.fromCenter(center: c, width: 24, height: 14),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - 11, c.dy)
            ..lineTo(c.dx - 19, c.dy - 7)
            ..lineTo(c.dx - 19, c.dy + 7)
            ..close(),
          paint,
        );
      case BlockPrize.musicNote:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c.dx - 3, c.dy + 6),
            width: 14,
            height: 11,
          ),
          paint,
        );
        canvas.drawRect(Rect.fromLTWH(c.dx + 2, c.dy - 12, 3.5, 19), paint);
      case BlockPrize.leaves:
        for (var i = 0; i < 3; i++) {
          final a = _time * 3 + i * 2.1;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(c.dx + cos(a) * 9, c.dy + i * 7 - 7),
              width: 14,
              height: 8,
            ),
            paint,
          );
        }
    }
  }
}

/// A fish floating along the run, collected by touching it.
///
/// **Fish are the only thing that fills the progress stars.** They sit at easy
/// heights — some on the ground, some at jump height — and a fish that is
/// missed simply scrolls past: there is always another one, nothing is counted,
/// and nothing goes down (CLAUDE.md §3).
class Fish extends PositionComponent {
  Fish({required super.position})
    : super(size: Vector2(46, 34), anchor: Anchor.center);

  bool _taken = false;
  bool get isTaken => _taken;

  double _time = 0;

  /// Generous: a fish is a reward, so the box that collects it is bigger than
  /// the art. The child should never watch one pass through the cat uncollected.
  Rect get hitBox => Rect.fromCenter(
    center: Offset(position.x, position.y),
    width: size.x * 1.4,
    height: size.y * 1.6,
  );

  /// Collected. Sparkles up and away rather than blinking out.
  void take() {
    if (_taken) return;
    _taken = true;
    add(MoveByEffect(Vector2(0, -50), EffectController(duration: 0.4)));
    add(
      ScaleEffect.to(
        Vector2.all(1.6),
        EffectController(duration: 0.4),
        onComplete: removeFromParent,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    // Bobs, so it reads as alive and catches the eye against the scenery.
    final bob = sin(_time * 3) * 2;
    final body = Paint()..color = KidPalette.playColors[4];

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx + 3, c.dy + bob),
        width: 32,
        height: 20,
      ),
      body,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 12, c.dy + bob)
        ..lineTo(c.dx - 22, c.dy + bob - 9)
        ..lineTo(c.dx - 22, c.dy + bob + 9)
        ..close(),
      body,
    );
    canvas.drawCircle(
      Offset(c.dx + 11, c.dy + bob - 3),
      2.6,
      Paint()..color = KidPalette.ink,
    );
    // A star glint, so it matches the progress stars it fills — the only
    // instruction a child gets that these two things are connected.
    canvas.drawPath(
      KidShapes.star(Offset(c.dx + 2, c.dy + bob - 4), 4),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }
}
