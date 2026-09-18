import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../../../shared/kid_shapes.dart';

/// Progress toward the next celebration, as filling stars.
///
/// This is a COUNT, not a score (CLAUDE.md §3). It only ever rises, it is never
/// shown as a number, there is no time limit on filling it, and a balloon that
/// drifts away never empties one. It exists to build anticipation — "nearly
/// there" — not to be something the child can be bad at.
///
/// The anticipation is doing real work here, so it is animated rather than
/// merely recoloured:
///
///  * a star that fills **pops in** with an overshoot, so the child sees *this
///    one, now* and connects it to the balloon they just hit;
///  * the empty stars ahead **lean brighter as the row fills**, so the row
///    itself says "nearly" without a number;
///  * the whole row **rises and settles** when it completes, handing over to
///    the confetti.
class ProgressStars extends PositionComponent {
  ProgressStars({
    required this.total,
    super.position,
  }) : super(anchor: Anchor.topLeft);

  /// How many pops make a celebration.
  final int total;

  int _filled = 0;

  /// Seconds since each star was filled, or null if it is still empty. Drives
  /// the pop-in; null means "draw it at rest".
  late final List<double?> _filledAt = List<double?>.filled(total, null);

  /// Seconds since the row completed, or null. Drives the hand-off flourish.
  double? _completedAt;

  static const double _starSize = 34;
  static const double _gap = 10;

  /// How long a newly filled star takes to settle.
  static const _popIn = 0.42;

  set filled(int value) {
    final next = value.clamp(0, total);

    // Mark the stars that just became filled, so each animates from the moment
    // it was earned rather than all of them animating together.
    for (var i = _filled; i < next; i++) {
      _filledAt[i] = 0;
    }
    // Reset (after a celebration) clears the animations rather than replaying
    // them backwards — progress is never shown draining away.
    if (next < _filled) {
      for (var i = next; i < total; i++) {
        _filledAt[i] = null;
      }
      _completedAt = null;
    }
    if (next >= total && _filled < total) {
      _completedAt = 0;
    }

    _filled = next;
  }

  int get filled => _filled;

  /// The row's own size, so a caller can place it without guessing.
  static double widthFor(int total) => total * _starSize + (total - 1) * _gap;

  @override
  void onMount() {
    super.onMount();
    size = Vector2(widthFor(total), _starSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (var i = 0; i < total; i++) {
      final t = _filledAt[i];
      if (t != null && t < _popIn) _filledAt[i] = t + dt;
    }
    final completed = _completedAt;
    if (completed != null && completed < 1) _completedAt = completed + dt;
  }

  @override
  void render(Canvas canvas) {
    // The row lifts a little as it completes, then settles back.
    final lift = _completedAt == null
        ? 0.0
        : -8 * sin((_completedAt!.clamp(0.0, 0.6) / 0.6) * pi);
    // How close the child is, 0..1 — used to warm the stars still to come.
    final closeness = total == 0 ? 0.0 : _filled / total;

    _renderTray(canvas, lift);

    for (var i = 0; i < total; i++) {
      final centre = Offset(
        i * (_starSize + _gap) + _starSize / 2,
        _starSize / 2 + lift,
      );
      final since = _filledAt[i];
      if (since == null) {
        _renderEmpty(canvas, centre, closeness);
      } else {
        _renderFilled(canvas, centre, since);
      }
    }
  }

  /// A soft tray behind the row.
  ///
  /// Not decoration: clouds drift through this corner, and an empty star on
  /// white cloud loses almost all its contrast. The tray guarantees the row
  /// always sits on the same background, so "how many have I filled" is
  /// readable at every moment — which matters more here than usual, because it
  /// is the only progress signal a child who cannot read can use.
  void _renderTray(Canvas canvas, double lift) {
    const pad = 9.0;
    final tray = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        -pad,
        -pad + lift,
        widthFor(total) + pad * 2,
        _starSize + pad * 2,
      ),
      const Radius.circular((_starSize + pad * 2) / 2),
    );
    canvas.drawRRect(
      tray,
      Paint()..color = KidPalette.skyTop.withValues(alpha: 0.75),
    );
    canvas.drawRRect(
      tray,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _renderEmpty(Canvas canvas, Offset centre, double closeness) {
    // Empty stars are outlines, not grey blobs: an outline reads as "this one
    // is waiting for you", a filled grey shape reads as "this one is dead".
    final path = KidShapes.star(centre, _starSize / 2);
    canvas.drawPath(
      path,
      // Warms up as the row fills, so the gaps themselves say "nearly there".
      Paint()..color = KidPalette.star.withValues(alpha: 0.10 + closeness * 0.2),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = KidPalette.starEmpty
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _renderFilled(Canvas canvas, Offset centre, double since) {
    final p = (since / _popIn).clamp(0.0, 1.0);
    // Overshoot then settle — a spring, not a fade. This is the "yes!" beat.
    final scale = p >= 1 ? 1.0 : 1 + 0.55 * sin(p * pi) * (1 - p * 0.35);
    final spin = p >= 1 ? 0.0 : (1 - p) * 0.5;

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(spin);
    canvas.scale(scale);

    final path = KidShapes.star(Offset.zero, _starSize / 2);
    canvas.drawPath(path, Paint()..color = KidPalette.star);
    // A brighter core, biggest at the moment of filling, so the newest star is
    // the one the eye goes to.
    canvas.drawPath(
      KidShapes.star(Offset.zero, _starSize / 2 * (0.5 + 0.2 * (1 - p))),
      Paint()..color = KidPalette.starBright.withValues(alpha: 0.85),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = KidPalette.ink.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }
}
