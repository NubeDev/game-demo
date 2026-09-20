import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';

/// Progress toward the next celebration, as filling bread rolls.
///
/// The same rules as every other progress row in the app (CLAUDE.md §3): a
/// COUNT, not a score. It only ever rises, it is never a number, there is no
/// time limit, and **nothing can empty one** — there is no uncollected treat in
/// this game, because every treat is caught eventually (see `QuackyWorld`).
///
/// Deliberately the same shape, size and corner as Cat Run's fish and Balloon
/// Pop's stars, so a child who has played those already knows what this row
/// means — consistency across the app doing the job an instruction would.
class ProgressRolls extends PositionComponent {
  ProgressRolls({required this.total, super.position})
    : super(anchor: Anchor.topLeft);

  /// How many treats make a celebration.
  final int total;

  int _filled = 0;

  /// Seconds since each roll filled, or null while empty. Drives the pop-in.
  late final List<double?> _filledAt = List<double?>.filled(total, null);

  static const double _rollW = 34;
  static const double _rollH = 26;
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

  static double widthFor(int total) => total * _rollW + (total - 1) * _gap;

  @override
  void onMount() {
    super.onMount();
    size = Vector2(widthFor(total), _rollH);
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
    _renderTray(canvas);

    for (var i = 0; i < total; i++) {
      final centre = Offset(i * (_rollW + _gap) + _rollW / 2, _rollH / 2);
      final since = _filledAt[i];
      if (since == null) {
        // An outline, not a grey blob: "waiting for you", not "dead".
        canvas.drawOval(
          Rect.fromCenter(center: centre, width: _rollW, height: _rollH),
          Paint()..color = _bread.withValues(alpha: 0.14),
        );
        canvas.drawOval(
          Rect.fromCenter(center: centre, width: _rollW, height: _rollH),
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

  /// A tray behind the row. The park scrolls past behind this corner and the
  /// place changes colour at every celebration, so without a fixed backing the
  /// row's legibility would depend on which part of the park Quacky is in —
  /// and this row is one of only two progress signals a child who cannot read
  /// can use (the other being Quacky's own eyebrows).
  void _renderTray(Canvas canvas) {
    const pad = 8.0;
    final tray = RRect.fromRectAndRadius(
      Rect.fromLTWH(-pad, -pad, widthFor(total) + pad * 2, _rollH + pad * 2),
      const Radius.circular((_rollH + pad * 2) / 2),
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
    // Overshoot then settle — the "yes!" beat, so the child connects the roll
    // to the treat Quacky just ate.
    final scale = p >= 1 ? 1.0 : 1 + 0.55 * sin(p * pi) * (1 - p * 0.35);

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(scale);

    final r = Rect.fromCenter(
      center: Offset.zero,
      width: _rollW,
      height: _rollH,
    );
    canvas.drawOval(r, Paint()..color = _bread);
    // A slash across the top, so it reads as a bread roll rather than an egg.
    canvas.drawLine(
      Offset(-_rollW * 0.22, -_rollH * 0.1),
      Offset(_rollW * 0.22, -_rollH * 0.18),
      Paint()
        ..color = const Color(0xFFC79A5B)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      r,
      Paint()
        ..color = KidPalette.ink.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  static const _bread = Color(0xFFE8C48A);
}
