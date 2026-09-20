import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../world.dart';

/// How many new things Neil has flopped on, as filling shells.
///
/// The "progress dots" the scope asks for, drawn as scallop shells because this
/// is a beach. Same rule as every other progress row in this app (CLAUDE.md
/// §3): a **count, not a score**. It only ever rises, it is never a number,
/// nothing empties it, and there is no time limit on filling it.
///
/// Each game has its own row rather than sharing one, because what the row
/// stands for differs every time — seats in Car Trip, fish in Cat Run, shells
/// here — and a child reads the picture, not the mechanism.
///
/// Note what is deliberately absent: nothing anywhere marks a prop as "already
/// done". Flopping on the same car twice is exactly as much fun, it just does
/// not fill a shell, and nothing tells the child off for it.
class ProgressShells extends PositionComponent {
  ProgressShells({this.total = NeilWorld.dotsPerNap, super.position})
      : super(anchor: Anchor.topLeft);

  final int total;

  int _filled = 0;

  /// Seconds since each shell filled, or null while empty. Drives the pop-in.
  late final List<double?> _filledAt = List<double?>.filled(total, null);

  static const double _shell = 30;
  static const double _gap = 11;
  static const double _popIn = 0.42;

  set filled(int value) {
    final next = value.clamp(0, total);
    for (var i = _filled; i < next; i++) {
      _filledAt[i] = 0;
    }
    // A reset clears the animations rather than playing them backwards.
    // Progress is never shown draining away.
    if (next < _filled) {
      for (var i = next; i < total; i++) {
        _filledAt[i] = null;
      }
    }
    _filled = next;
  }

  int get filled => _filled;

  static double widthFor(int total) => total * _shell + (total - 1) * _gap;

  @override
  void onMount() {
    super.onMount();
    size = Vector2(widthFor(total), _shell);
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
    _tray(canvas);
    final closeness = total == 0 ? 0.0 : _filled / total;

    for (var i = 0; i < total; i++) {
      final centre = Offset(i * (_shell + _gap) + _shell / 2, _shell / 2);
      final since = _filledAt[i];
      if (since == null) {
        // An empty shell: an outline that warms as the row fills, so the row
        // itself says "nearly there" without ever being a number.
        canvas.drawPath(
          _shellPath(centre, _shell / 2),
          Paint()
            ..color = KidPalette.star.withValues(alpha: 0.10 + closeness * 0.2),
        );
        canvas.drawPath(
          _shellPath(centre, _shell / 2),
          Paint()
            ..color = KidPalette.starEmpty
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      } else {
        _filledShell(canvas, centre, since);
      }
    }
  }

  /// A tray behind the row. The ground under it changes colour at every
  /// location, so without a fixed backing the row's legibility would depend on
  /// where Neil happened to be — and this row is the only progress signal a
  /// child who cannot read can use.
  void _tray(Canvas canvas) {
    const pad = 8.0;
    final tray = RRect.fromRectAndRadius(
      Rect.fromLTWH(-pad, -pad, widthFor(total) + pad * 2, _shell + pad * 2),
      const Radius.circular((_shell + pad * 2) / 2),
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

  void _filledShell(Canvas canvas, Offset centre, double since) {
    final p = (since / _popIn).clamp(0.0, 1.0);
    // Overshoot then settle — the "yes!" beat, so the child connects the shell
    // to the thing Neil just sat on.
    final scale = p >= 1 ? 1.0 : 1 + 0.55 * sin(p * pi) * (1 - p * 0.35);

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(scale);
    canvas.drawPath(
      _shellPath(Offset.zero, _shell / 2),
      Paint()..color = KidPalette.star,
    );
    canvas.drawPath(
      _shellPath(Offset.zero, _shell / 2 * (0.55 + 0.2 * (1 - p))),
      Paint()..color = KidPalette.starBright.withValues(alpha: 0.85),
    );
    canvas.drawPath(
      _shellPath(Offset.zero, _shell / 2),
      Paint()
        ..color = KidPalette.ink.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  /// A scallop: a fan with a flat hinge at the bottom. Drawn properly rather
  /// than as a circle, for the same reason `KidShapes.star` is a real star — a
  /// shell that is actually a dot teaches the child nothing.
  static Path _shellPath(Offset centre, double r) {
    final path = Path()..moveTo(centre.dx, centre.dy + r * 0.72);
    const ribs = 5;
    for (var i = 0; i <= ribs; i++) {
      final a = pi + (i / ribs) * pi;
      final out = r * (i.isEven ? 1.0 : 0.88);
      path.lineTo(centre.dx + cos(a) * out, centre.dy + sin(a) * out * 0.95);
    }
    return path..close();
  }
}
