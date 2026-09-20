import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../countdown.dart';

/// The number itself, popping in each time it changes.
///
/// It is the only text-shaped thing a child sees in this app, and it is
/// deliberately *not* required: the jar beside it says the same thing as a
/// quantity, and the sound ladder says it again as a pitch. A child who does
/// not know digits can play this game completely (CLAUDE.md §3).
///
/// Each number squashes in, settles, and the last three arrive bigger — that
/// swell is the visual half of "three… two… one…".
class BigNumber extends PositionComponent {
  BigNumber({required this.countdown, required super.position})
    : super(anchor: Anchor.center);

  final Countdown countdown;

  /// 0 just as a number lands, growing to 1 as it settles.
  double _age = 1;
  int _shown = 0;

  /// Called when the displayed number changes, so it pops.
  void bump() => _age = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _age = min(1, _age + dt * 3.4);
    if (countdown.phase == CountdownPhase.counting) {
      if (countdown.secondsLeft != _shown) {
        _shown = countdown.secondsLeft;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (countdown.phase != CountdownPhase.counting) return;

    // Overshoot then settle: the number arrives with a bounce rather than
    // appearing, which is what makes it feel like an event.
    final settle = Curves.easeOutBack.transform(_age);
    final base = countdown.isFinalStretch ? 1.35 : 1.0;
    final scale = base * (0.45 + settle * 0.55);

    final painter = TextPainter(
      text: TextSpan(
        text: '$_shown',
        style: TextStyle(
          fontSize: 150,
          fontWeight: FontWeight.w900,
          color: KidPalette.ink,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.scale(scale);
    // A soft halo, so the digit stays readable over the sky and the smoke
    // without an outline that would make it look like a warning sign.
    canvas.drawCircle(
      Offset.zero,
      painter.height * 0.52,
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }
}
