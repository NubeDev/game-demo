import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../../../shared/kid_shapes.dart';
import '../obstacles.dart';

/// One thing in the world, scrolling right to left.
///
/// Placeholder art, drawn in code, but drawn as the thing it means: a fence has
/// palings, a flowerpot has a rim, a snail has a shell. A child who cannot read
/// has only the silhouette to go on, so a fence that was a grey rectangle would
/// teach them nothing about which button to press.
///
/// The cat does not move horizontally — the world moves past it. So an obstacle
/// only ever does two things: slide left, and react when it is hit.
class Obstacle extends PositionComponent {
  Obstacle({required this.kind, required super.position, this.prize})
    : super(
        size: Vector2(kind.size.width, kind.size.height),
        anchor: Anchor.bottomLeft,
      );

  final ObstacleKind kind;

  /// What pops out, for a block.
  final BlockPrize? prize;

  /// Whether the cat has already dealt with this one, so a single obstacle
  /// cannot bonk twice or pay out twice.
  bool _spent = false;
  bool get isSpent => _spent;

  /// Set when the child got past it cleanly — drives the chime ladder.
  bool _cleared = false;
  bool get isCleared => _cleared;

  /// Seconds since this was hit, for the squash/giggle reaction.
  double? _reactedAt;

  double _time = 0;

  /// The box the cat collides with: inset from the art (see
  /// [ObstacleKind.hitBox]) so a near miss is a clear.
  Rect get hitBox {
    final box = kind.hitBox;
    final insetX = (kind.size.width - box.width) / 2;
    switch (kind.action) {
      case ObstacleAction.duck:
        // Duck obstacles hang from above: the box is the gap-blocking part, so
        // it starts at the TOP of the art and comes down.
        return Rect.fromLTWH(
          position.x + insetX,
          position.y - kind.size.height,
          box.width,
          box.height,
        );
      case ObstacleAction.block:
        // Blocks float overhead; position.y is already their underside.
        return Rect.fromLTWH(
          position.x + insetX,
          position.y - kind.size.height,
          box.width,
          box.height,
        );
      case ObstacleAction.jump:
      case ObstacleAction.bounce:
        // Ground things: the box sits on the ground line.
        return Rect.fromLTWH(
          position.x + insetX,
          position.y - box.height,
          box.width,
          box.height,
        );
    }
  }

  /// Marks this one as dealt with. [cleared] true means the child got past it
  /// without a bonk, which is what advances the chime.
  void markSpent({required bool cleared}) {
    _spent = true;
    _cleared = cleared;
  }

  /// A bouncy thing was landed on, or a block was headbutted: react visibly.
  ///
  /// Deliberately NOT a removal. A mushroom that vanished when stood on would
  /// read as having been squashed — the scope forbids that outright, and a
  /// five-year-old reads a hurt animal as real (CLAUDE.md §3). It giggles,
  /// springs, and is still there.
  void react() => _reactedAt = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final r = _reactedAt;
    if (r != null && r < 1) _reactedAt = r + dt;
  }

  @override
  void render(Canvas canvas) {
    final r = _reactedAt;
    // Squash and spring back. A bounced mushroom and a headbutted block share
    // this: whatever the cat touched should visibly answer.
    final squash = r == null ? 0.0 : sin((r.clamp(0.0, 0.45) / 0.45) * pi);
    canvas.save();
    canvas.translate(size.x / 2, size.y);
    canvas.scale(1 + squash * 0.18, 1 - squash * 0.3);
    canvas.translate(-size.x / 2, -size.y);

    final paint = Paint()..color = kind.color;
    final ink = Paint()
      ..color = KidPalette.ink.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    switch (kind.id) {
      case 'fence':
        _paintFence(canvas, paint, ink);
      case 'flowerpot':
        _paintFlowerpot(canvas, paint, ink);
      case 'log':
        _paintLog(canvas, paint, ink);
      case 'puddle':
        _paintPuddle(canvas, paint);
      case 'pipe':
        _paintPipe(canvas, paint, ink);
      case 'branch':
        _paintBranch(canvas, paint, ink);
      case 'washing_line':
        _paintWashingLine(canvas, paint, ink);
      case 'mushroom':
        _paintMushroom(canvas, paint, ink);
      case 'snail':
        _paintSnail(canvas, paint, ink);
      case 'cushion':
        _paintCushion(canvas, paint, ink);
      case 'block':
        _paintBlock(canvas, paint, ink);
      default:
        // A new obstacle with no painter yet still shows as its own shape
        // rather than nothing at all — an invisible solid thing is the worst
        // possible failure here.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Offset.zero & size.toSize(),
            const Radius.circular(8),
          ),
          paint,
        );
    }
    canvas.restore();
  }

  void _paintFence(Canvas canvas, Paint paint, Paint ink) {
    // Three palings and two rails. Unmistakably a fence at a glance.
    for (var i = 0; i < 3; i++) {
      final x = size.x * (0.1 + i * 0.32);
      final paling = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, size.x * 0.2, size.y),
        const Radius.circular(4),
      );
      canvas.drawRRect(paling, paint);
      canvas.drawRRect(paling, ink);
    }
    for (final y in [size.y * 0.3, size.y * 0.68]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, y, size.x, size.y * 0.12),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  void _paintFlowerpot(Canvas canvas, Paint paint, Paint ink) {
    // A tapered pot, a rim, and a flower — the flower is the bit a child reads.
    final pot = Path()
      ..moveTo(size.x * 0.14, size.y * 0.32)
      ..lineTo(size.x * 0.86, size.y * 0.32)
      ..lineTo(size.x * 0.74, size.y)
      ..lineTo(size.x * 0.26, size.y)
      ..close();
    canvas.drawPath(pot, paint);
    canvas.drawPath(pot, ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.08,
          size.y * 0.22,
          size.x * 0.84,
          size.y * 0.14,
        ),
        const Radius.circular(4),
      ),
      paint,
    );
    // Petals.
    final centre = Offset(size.x * 0.5, size.y * 0.1);
    for (var i = 0; i < 5; i++) {
      final a = i * pi * 2 / 5;
      canvas.drawCircle(
        Offset(centre.dx + cos(a) * 7, centre.dy + sin(a) * 7),
        6,
        Paint()..color = KidPalette.playColors[0],
      );
    }
    canvas.drawCircle(centre, 5, Paint()..color = KidPalette.star);
  }

  void _paintLog(Canvas canvas, Paint paint, Paint ink) {
    final body = RRect.fromRectAndRadius(
      Offset.zero & size.toSize(),
      Radius.circular(size.y / 2),
    );
    canvas.drawRRect(body, paint);
    canvas.drawRRect(body, ink);
    // End rings, so it reads as a log and not a sausage.
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.72, size.y * 0.1, size.x * 0.22, size.y * 0.8),
      Paint()..color = kind.color.withValues(alpha: 0.6),
    );
  }

  void _paintPuddle(Canvas canvas, Paint paint) {
    // Flat, wide, glossy. Nothing about it should read as a hole or a drop —
    // no pits anywhere in this game (the scope's *Not this*).
    canvas.drawOval(Offset.zero & size.toSize(), paint);
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.12, size.y * 0.18, size.x * 0.4, size.y * 0.3),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    // A ripple that breathes, so it reads as water rather than a blue mat.
    final wobble = sin(_time * 2.2) * 2;
    canvas.drawOval(
      Rect.fromLTWH(
        size.x * 0.55,
        size.y * 0.45 + wobble,
        size.x * 0.3,
        size.y * 0.25,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  void _paintPipe(Canvas canvas, Paint paint, Paint ink) {
    // Hangs from above: drawn from the top of its box downward.
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(10),
    );
    canvas.drawRRect(r, paint);
    canvas.drawRRect(r, ink);
    // A collar at the open end, the Mario read without the Mario stakes.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -size.x * 0.06,
          size.y * 0.62,
          size.x * 1.12,
          size.y * 0.3,
        ),
        const Radius.circular(8),
      ),
      paint,
    );
  }

  void _paintBranch(Canvas canvas, Paint paint, Paint ink) {
    canvas.drawLine(
      Offset(0, size.y * 0.2),
      Offset(size.x, size.y * 0.32),
      Paint()
        ..color = kind.color
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    // Leaves hanging down, so the underside is visible and the gap is legible.
    for (var i = 0; i < 4; i++) {
      final x = size.x * (0.12 + i * 0.25);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, size.y * (0.55 + (i.isEven ? 0.12 : 0.0))),
          width: 22,
          height: 14,
        ),
        Paint()..color = KidPalette.hillNear,
      );
    }
    canvas.drawLine(
      Offset(0, size.y * 0.2),
      Offset(size.x, size.y * 0.32),
      ink,
    );
  }

  void _paintWashingLine(Canvas canvas, Paint paint, Paint ink) {
    // A sagging line with socks on it. The sag is what shows how low it is.
    final line = Path()
      ..moveTo(0, size.y * 0.1)
      ..quadraticBezierTo(size.x / 2, size.y * 0.35, size.x, size.y * 0.1);
    canvas.drawPath(line, ink);
    for (var i = 0; i < 4; i++) {
      final t = 0.15 + i * 0.23;
      // Follow the sag, so the socks hang off the line rather than float.
      final y = size.y * (0.1 + 0.25 * (1 - pow(2 * t - 1, 2)));
      final sway = sin(_time * 2 + i) * 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.x * t + sway, y, 18, size.y * 0.5),
          const Radius.circular(7),
        ),
        Paint()
          ..color =
              KidPalette.playColors[(i + 1) % KidPalette.playColors.length],
      );
    }
  }

  void _paintMushroom(Canvas canvas, Paint paint, Paint ink) {
    // Stalk.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.36,
          size.y * 0.45,
          size.x * 0.28,
          size.y * 0.55,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFFFF0DC),
    );
    // Cap — the springy bit, and the part that says "stand on me".
    final cap = Rect.fromLTWH(0, 0, size.x, size.y * 0.62);
    canvas.drawArc(cap, pi, pi, true, paint);
    canvas.drawArc(cap, pi, pi, false, ink);
    for (final spot in [0.28, 0.55, 0.75]) {
      canvas.drawCircle(
        Offset(size.x * spot, size.y * (spot == 0.55 ? 0.16 : 0.26)),
        5,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    }
    _paintSmile(canvas, Offset(size.x * 0.5, size.y * 0.42), 7);
  }

  void _paintSnail(Canvas canvas, Paint paint, Paint ink) {
    // Shell: a spiral, so it reads as a snail and not a rock.
    final centre = Offset(size.x * 0.42, size.y * 0.45);
    canvas.drawCircle(centre, size.y * 0.42, paint);
    final spiral = Path();
    for (var i = 0.0; i < pi * 3.2; i += 0.2) {
      final r = size.y * 0.08 + i * size.y * 0.045;
      final p = Offset(centre.dx + cos(i) * r, centre.dy + sin(i) * r);
      i == 0 ? spiral.moveTo(p.dx, p.dy) : spiral.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(spiral, ink);
    // Body and head, poking out forward.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.5,
          size.y * 0.62,
          size.x * 0.48,
          size.y * 0.32,
        ),
        Radius.circular(size.y * 0.18),
      ),
      Paint()..color = const Color(0xFFF0CE9A),
    );
    // Eye stalks. A face is what stops a creature being an obstacle.
    for (final dx in [0.82, 0.92]) {
      canvas.drawLine(
        Offset(size.x * dx, size.y * 0.66),
        Offset(size.x * dx + 2, size.y * 0.42),
        ink,
      );
      canvas.drawCircle(
        Offset(size.x * dx + 2, size.y * 0.4),
        3,
        Paint()..color = KidPalette.ink,
      );
    }
  }

  void _paintCushion(Canvas canvas, Paint paint, Paint ink) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size.toSize(),
      Radius.circular(size.y * 0.4),
    );
    canvas.drawRRect(r, paint);
    canvas.drawRRect(r, ink);
    // A tuft in the middle and corner tassels: plainly soft.
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  void _paintBlock(Canvas canvas, Paint paint, Paint ink) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size.toSize(),
      const Radius.circular(10),
    );
    canvas.drawRRect(r, paint);
    canvas.drawRRect(r, ink);
    if (_spent) {
      // A used block goes quiet and dim rather than disappearing — a thing
      // that vanished would look like it broke.
      canvas.drawRRect(
        r,
        Paint()..color = Colors.white.withValues(alpha: 0.45),
      );
      return;
    }
    // A star on the front, so it reads as "hit me" rather than as scenery.
    // It breathes, because the only way to advertise a headbutt to a
    // five-year-old is to make the thing look alive.
    final pulse = 1 + sin(_time * 3) * 0.08;
    canvas.drawPath(
      KidShapes.star(Offset(size.x / 2, size.y / 2), size.x * 0.26 * pulse),
      Paint()..color = KidPalette.star,
    );
  }

  /// A smile on the bouncy things, for the same reason the cat always smiles.
  void _paintSmile(Canvas canvas, Offset centre, double radius) {
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      0.2,
      pi - 0.4,
      false,
      Paint()
        ..color = KidPalette.ink.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }
}
