import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../../../shared/kid_shapes.dart';

/// Progress toward the next celebration, as filling stars.
///
/// The same rules as Balloon Pop's row (CLAUDE.md §3): a COUNT, not a score. It
/// only ever rises, it is never a number, there is no time limit, and a fish
/// that scrolled past uncollected never empties one.
///
/// Deliberately the same shape and place as Balloon Pop's, so a child who has
/// played that game already knows what this row means — consistency across the
/// app is doing the job an instruction would.
class ProgressFish extends PositionComponent {
  ProgressFish({required this.total, super.position})
    : super(anchor: Anchor.topLeft);

  /// How many fish make a celebration.
  final int total;

  int _filled = 0;

  /// Seconds since each star filled, or null while empty. Drives the pop-in.
  late final List<double?> _filledAt = List<double?>.filled(total, null);

  static const double _starSize = 30;
  static const double _gap = 9;
  static const _popIn = 0.42;

  set filled(int value) {
    final next = value.clamp(0, total);
    for (var i = _filled; i < next; i++) {
      _filledAt[i] = 0;
    }
    // A reset clears the animations rather than replaying them backwards —
    // progress is never shown draining away.
    if (next < _filled) {
      for (var i = next; i < total; i++) {
        _filledAt[i] = null;
      }
    }
    _filled = next;
  }

  int get filled => _filled;

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
  }

  @override
  void render(Canvas canvas) {
    final closeness = total == 0 ? 0.0 : _filled / total;
    _renderTray(canvas);

    for (var i = 0; i < total; i++) {
      final centre = Offset(
        i * (_starSize + _gap) + _starSize / 2,
        _starSize / 2,
      );
      final since = _filledAt[i];
      if (since == null) {
        // An outline, not a grey blob: "waiting for you", not "dead".
        final path = KidShapes.star(centre, _starSize / 2);
        canvas.drawPath(
          path,
          Paint()
            ..color = KidPalette.star.withValues(alpha: 0.10 + closeness * 0.2),
        );
        canvas.drawPath(
          path,
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

  /// A tray behind the row. The scenery scrolls past behind this corner and the
  /// scene changes colour at every celebration, so without a fixed backing the
  /// row's legibility would depend on which place the cat is in — and this row
  /// is the only progress signal a child who cannot read can use.
  void _renderTray(Canvas canvas) {
    const pad = 8.0;
    final tray = RRect.fromRectAndRadius(
      Rect.fromLTWH(-pad, -pad, widthFor(total) + pad * 2, _starSize + pad * 2),
      const Radius.circular((_starSize + pad * 2) / 2),
    );
    canvas.drawRRect(
      tray,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
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
    // Overshoot then settle — the "yes!" beat, so the child connects the star
    // to the fish they just swam through.
    final scale = p >= 1 ? 1.0 : 1 + 0.55 * sin(p * pi) * (1 - p * 0.35);

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(scale);

    final path = KidShapes.star(Offset.zero, _starSize / 2);
    canvas.drawPath(path, Paint()..color = KidPalette.star);
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
