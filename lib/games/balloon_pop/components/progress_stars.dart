import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';

/// Progress toward the next celebration, as filling stars.
///
/// This is a COUNT, not a score (CLAUDE.md §3). It only ever rises, it is never
/// shown as a number, there is no time limit on filling it, and a balloon that
/// drifts away never empties one. It exists to build anticipation — "nearly
/// there" — not to be something the child can be bad at.
class ProgressStars extends PositionComponent {
  ProgressStars({
    required this.total,
    super.position,
  }) : super(anchor: Anchor.topLeft);

  /// How many pops make a celebration.
  final int total;

  int _filled = 0;

  static const double _starSize = 30;
  static const double _gap = 12;

  set filled(int value) {
    _filled = value.clamp(0, total);
  }

  int get filled => _filled;

  @override
  void render(Canvas canvas) {
    for (var i = 0; i < total; i++) {
      final isFilled = i < _filled;
      _drawStar(
        canvas,
        Offset(i * (_starSize + _gap) + _starSize / 2, _starSize / 2),
        _starSize / 2,
        isFilled ? KidPalette.star : KidPalette.starEmpty,
        isFilled,
      );
    }
  }

  void _drawStar(
    Canvas canvas,
    Offset centre,
    double radius,
    Color color,
    bool outlined,
  ) {
    canvas.drawCircle(centre, radius, Paint()..color = color);
    if (outlined) {
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..color = KidPalette.ink.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }
}
