import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';

/// One balloon: floats up, pops when tapped.
///
/// Placeholder art — a coloured circle with a knot and a string, drawn in code.
/// Replacing it with a sprite means changing [render] and reading the path from
/// `assets.dart`; nothing else here changes.
class Balloon extends PositionComponent with TapCallbacks {
  Balloon({
    required this.color,
    required this.riseSpeed,
    required this.onPopped,
    required super.position,
    required double radius,
  })  : _radius = radius,
        super(
          // Size is the TOUCH TARGET, not the drawn balloon. It is deliberately
          // larger than the art (see BalloonPopGame.balloonRadius): a
          // five-year-old aiming at the balloon and landing just outside it
          // should still pop it. A tap that visibly misses but felt on-target
          // reads to them as the game ignoring them.
          size: Vector2.all(radius * 2.6),
          anchor: Anchor.center,
        );

  final Color color;

  /// Logical pixels per second upward. Gentle and varied.
  final double riseSpeed;

  /// Called when this balloon is popped by a tap (not when it drifts away).
  final void Function(Balloon balloon) onPopped;

  final double _radius;
  final _random = Random();

  /// Horizontal drift, so balloons don't rise in straight mechanical lines.
  late final double _driftPhase = _random.nextDouble() * pi * 2;
  late final double _driftAmount = 8 + _random.nextDouble() * 14;
  double _time = 0;

  /// Set once popping starts, so a child mashing the same balloon can't score
  /// it twice while the pop animation plays.
  bool _isPopping = false;

  @override
  void update(double dt) {
    super.update(dt);
    if (_isPopping) return;

    _time += dt;
    position.y -= riseSpeed * dt;
    // Gentle sine sway. Small amplitude — it should read as floating, not
    // as the balloon dodging the child's finger.
    position.x += sin(_time * 1.2 + _driftPhase) * _driftAmount * dt;
  }

  @override
  void render(Canvas canvas) {
    final centre = Offset(size.x / 2, size.y / 2);

    // String.
    final stringPaint = Paint()
      ..color = KidPalette.ink.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(centre.dx, centre.dy + _radius)
      ..quadraticBezierTo(
        centre.dx + _radius * 0.4,
        centre.dy + _radius * 1.5,
        centre.dx,
        centre.dy + _radius * 1.9,
      );
    canvas.drawPath(path, stringPaint);

    // Body. Slightly taller than wide, like a real balloon.
    canvas.drawOval(
      Rect.fromCenter(
        center: centre,
        width: _radius * 1.85,
        height: _radius * 2.1,
      ),
      Paint()..color = color,
    );

    // Knot.
    canvas.drawCircle(
      Offset(centre.dx, centre.dy + _radius),
      _radius * 0.13,
      Paint()..color = color,
    );

    // Highlight — makes it read as round and shiny rather than a flat disc.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centre.dx - _radius * 0.35, centre.dy - _radius * 0.5),
        width: _radius * 0.5,
        height: _radius * 0.7,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Pop on tap DOWN, not tap up: a five-year-old's finger often slides
    // between the two, and an ignored tap reads to them as the game being
    // broken.
    pop();
  }

  /// Pops with a quick squash-and-vanish, then removes itself.
  void pop() {
    if (_isPopping) return;
    _isPopping = true;
    onPopped(this);

    // Brief scale-up then out — the balloon "bursts" rather than blinking off.
    add(ScaleEffect.to(
      Vector2.all(1.35),
      EffectController(duration: 0.08),
      onComplete: () {
        add(ScaleEffect.to(
          Vector2.zero(),
          EffectController(duration: 0.12),
          onComplete: removeFromParent,
        ));
      },
    ));
  }

  /// A balloon that reached the top and drifted away. NOT a failure: nothing is
  /// lost, no sound plays, no counter moves (CLAUDE.md §3).
  void driftAway() => removeFromParent();
}
