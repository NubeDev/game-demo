import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';

/// How full the car is, as filling dots — the road to the destination.
///
/// The same rule as every other progress row in this app (CLAUDE.md §3): a
/// **count, not a score**. It only ever rises, it is never a number, there is
/// no time limit on filling it, and a passenger the child drove past never
/// empties one — that animal simply waits further up the road.
///
/// Dots rather than Balloon Pop's and Cat Run's stars, because here they are
/// standing in for seats: a row of dots filling up reads as "the car is getting
/// full", which is also what the heads in the car window say.
class ProgressDots extends PositionComponent {
  ProgressDots({required this.total, super.position})
    : super(anchor: Anchor.topLeft);

  /// How many passengers make a trip.
  final int total;

  int _filled = 0;

  /// Seconds since each dot filled, or null while empty. Drives the pop-in.
  late final List<double?> _filledAt = List<double?>.filled(total, null);

  static const double _dotSize = 26;
  static const double _gap = 10;
  static const _popIn = 0.42;

  set filled(int value) {
    final next = value.clamp(0, total);
    for (var i = _filled; i < next; i++) {
      _filledAt[i] = 0;
    }
    // A reset clears the animations rather than playing them backwards —
    // progress is never shown draining away.
    if (next < _filled) {
      for (var i = next; i < total; i++) {
        _filledAt[i] = null;
      }
    }
    _filled = next;
  }

  int get filled => _filled;

  static double widthFor(int total) => total * _dotSize + (total - 1) * _gap;

  @override
  void onMount() {
    super.onMount();
    size = Vector2(widthFor(total), _dotSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (var i = 0; i < total; i++) {
      final t = _filledAt[i];
      if (t != null && t < _popIn) _filledAt[i] = t + dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final closeness = total == 0 ? 0.0 : _filled / total;
    _renderTray(canvas);

    for (var i = 0; i < total; i++) {
      final centre = Offset(i * (_dotSize + _gap) + _dotSize / 2, _dotSize / 2);
      final since = _filledAt[i];
      if (since == null) {
        // An empty seat: an outline that warms as the row fills, so the row
        // itself says "nearly there" without a number.
        canvas.drawCircle(
          centre,
          _dotSize / 2,
          Paint()
            ..color = KidPalette.star.withValues(alpha: 0.10 + closeness * 0.2),
        );
        canvas.drawCircle(
          centre,
          _dotSize / 2,
          Paint()
            ..color = KidPalette.starEmpty
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      } else {
        _renderFilled(canvas, centre, since);
      }
    }
  }

  /// A tray behind the row. The road scrolls past behind this corner and the
  /// place changes colour at every arrival, so without a fixed backing the
  /// row's legibility would depend on where the car happened to be — and this
  /// row is the only progress signal a child who cannot read can use.
  void _renderTray(Canvas canvas) {
    const pad = 8.0;
    final tray = RRect.fromRectAndRadius(
      Rect.fromLTWH(-pad, -pad, widthFor(total) + pad * 2, _dotSize + pad * 2),
      const Radius.circular((_dotSize + pad * 2) / 2),
    );
    canvas.drawRRect(tray, Paint()..color = Colors.white.withValues(alpha: 0.6));
    canvas.drawRRect(
      tray,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _renderFilled(Canvas canvas, Offset centre, double since) {
    final p = (since / _popIn).clamp(0.0, 1.0);
    // Overshoot then settle — the "yes!" beat, so the child connects the dot to
    // the animal that just got in.
    final scale = p >= 1 ? 1.0 : 1 + 0.55 * sin(p * pi) * (1 - p * 0.35);

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(scale);
    canvas.drawCircle(Offset.zero, _dotSize / 2, Paint()..color = KidPalette.star);
    canvas.drawCircle(
      Offset.zero,
      _dotSize / 2 * (0.5 + 0.2 * (1 - p)),
      Paint()..color = KidPalette.starBright.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset.zero,
      _dotSize / 2,
      Paint()
        ..color = KidPalette.ink.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }
}
