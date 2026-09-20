import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../world.dart';

/// A pine, a stack of rocks, a stone arch, a washing line.
///
/// **Keep the obstacle, delete the loss** (the same resolution Cat Run uses for
/// its fences, CLAUDE.md §3). Clipping one scatters leaves, wobbles her and
/// plays a soft boing. It does not stop her, take height, take a crystal, or
/// get counted anywhere. The reason to fly well lives entirely in the chime
/// ladder and the crystals.
class Prop extends PositionComponent {
  Prop({required this.kind, required super.position})
    : super(
        size: Vector2(kind.width, kind.height),
        anchor: Anchor.bottomLeft,
      );

  final PropKind kind;

  /// Already clipped this pass, so one pine cannot wobble her twice.
  bool _spent = false;
  bool get isSpent => _spent;
  void markSpent() => _spent = true;

  /// How much the last clip shook it. Cosmetic, decays on its own.
  double _shake = 0;
  double _time = 0;

  void react() => _shake = 0.5;

  /// The collidable box, **inset from the art**. A clip that looked like a
  /// clear miss is the same injustice as an ignored tap, so the solid part is
  /// well inside the leaves.
  Rect get hitBox {
    const inset = 0.26;
    return Rect.fromLTWH(
      position.x + size.x * inset,
      position.y - size.y,
      size.x * (1 - inset * 2),
      size.y * (1 - inset * 0.5),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_shake > 0) _shake = max(0, _shake - dt);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    if (_shake > 0) {
      canvas.translate(sin(_time * 30) * _shake * 4, 0);
    }
    // Local space: the component's anchor is bottom-left, so y grows downward
    // from the top of the art and size.y is the base.
    switch (kind) {
      case PropKind.pine:
        _pine(canvas);
      case PropKind.rocks:
        _rocks(canvas);
      case PropKind.stoneArch:
        _stoneArch(canvas);
      case PropKind.washingLine:
        _washingLine(canvas);
    }
    canvas.restore();
  }

  void _pine(Canvas canvas) {
    final trunk = Paint()..color = const Color(0xFFB07C4F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.4, size.y * 0.72, size.x * 0.2, size.y * 0.28),
        const Radius.circular(5),
      ),
      trunk,
    );
    // Three tiers, darkest at the bottom.
    for (var i = 0; i < 3; i++) {
      final t = i / 2;
      final top = size.y * (0.02 + t * 0.26);
      final halfWidth = size.x * (0.22 + t * 0.26);
      canvas.drawPath(
        Path()
          ..moveTo(size.x * 0.5, top)
          ..lineTo(size.x * 0.5 + halfWidth, top + size.y * 0.32)
          ..lineTo(size.x * 0.5 - halfWidth, top + size.y * 0.32)
          ..close(),
        Paint()..color = Color.lerp(
          const Color(0xFF7FCB8A),
          const Color(0xFF4FA463),
          t,
        )!,
      );
    }
  }

  void _rocks(Canvas canvas) {
    const colours = [Color(0xFFB9B2AA), Color(0xFFCFC7BE), Color(0xFFA8A099)];
    for (var i = 0; i < 3; i++) {
      final w = size.x * (0.68 - i * 0.16);
      final h = size.y * (0.4 - i * 0.07);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.x * (0.5 + (i.isEven ? -0.05 : 0.08)),
                size.y - h / 2 - i * h * 0.78),
            width: w,
            height: h,
          ),
          Radius.circular(h * 0.42),
        ),
        Paint()..color = colours[i],
      );
    }
  }

  void _stoneArch(Canvas canvas) {
    final stone = Paint()..color = const Color(0xFFC3BAB0);
    final legWidth = size.x * 0.2;
    // Two legs and a curved top — the gap she drops under is the middle.
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.3, legWidth, size.y * 0.7),
      stone,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x - legWidth, size.y * 0.3, legWidth, size.y * 0.7),
      stone,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.y * 0.36)
        ..quadraticBezierTo(size.x * 0.5, -size.y * 0.16, size.x, size.y * 0.36)
        ..lineTo(size.x, size.y * 0.04)
        ..quadraticBezierTo(
            size.x * 0.5, -size.y * 0.44, 0, size.y * 0.04)
        ..close(),
      stone,
    );
  }

  void _washingLine(Canvas canvas) {
    // The line, with a sag in it.
    canvas.drawPath(
      Path()
        ..moveTo(0, size.y * 0.1)
        ..quadraticBezierTo(size.x * 0.5, size.y * 0.5, size.x, size.y * 0.1),
      Paint()
        ..color = const Color(0xFF9A8F84)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    // Washing. Bright and friendly — this is a thing in a garden, not a hazard.
    const shirts = [Color(0xFFFFB3C7), Color(0xFFA9D8FF), Color(0xFFFFE08A)];
    for (var i = 0; i < 3; i++) {
      final t = (i + 1) / 4;
      final x = size.x * t;
      // Hangs from the sagging line, so the washing follows the curve.
      final y = size.y * (0.1 + 0.4 * (1 - pow(2 * t - 1, 2).toDouble()));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - size.x * 0.08, y, size.x * 0.16, size.y * 0.5),
          const Radius.circular(4),
        ),
        Paint()..color = shirts[i],
      );
    }
  }
}
