import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../park.dart';

/// One thing on the path: a bench to skid under, or a bin to rattle.
///
/// Placeholder art, drawn in code. The shapes are the real outlines rather than
/// coloured boxes, because a bench that is a rectangle teaches the child
/// nothing about what to do with it (CLAUDE.md §5).
class Hazard extends PositionComponent {
  Hazard({required this.kind, required super.position})
    : super(size: Vector2(kind.size.width, kind.size.height),
            anchor: Anchor.bottomLeft);

  final HazardKind kind;

  /// Already dealt with — cleared, or bonked into. Never collides twice.
  bool _spent = false;
  bool get isSpent => _spent;

  /// Whether it was got past cleanly. Only ever used for the chime.
  bool _cleared = false;
  bool get wasCleared => _cleared;

  /// Seconds since it reacted, for the wobble.
  double _reactedAt = -1;

  void markSpent({required bool cleared}) {
    _spent = true;
    _cleared = cleared;
  }

  /// It got bumped or bonked: wobble, rattle, scatter.
  void react() => _reactedAt = 0;

  /// The collidable box. Hangs from the TOP of the art — see [HazardKind].
  Rect get hitBox {
    final box = kind.hitBox;
    return Rect.fromLTWH(
      position.x + (size.x - box.width) / 2,
      position.y - size.y,
      box.width,
      box.height,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_reactedAt >= 0) _reactedAt += dt;
  }

  @override
  void render(Canvas canvas) {
    // A wobble after being hit, decaying to nothing. Nothing here ever breaks,
    // falls over or vanishes — it rocks and settles (CLAUDE.md §3).
    final since = _reactedAt;
    final wobble = since < 0 || since > 0.7
        ? 0.0
        : sin(since * 26) * (1 - since / 0.7) * 0.12;

    canvas.save();
    canvas.translate(size.x / 2, size.y);
    canvas.rotate(wobble);
    canvas.translate(-size.x / 2, -size.y);

    final fill = Paint()..color = kind.color;
    final ink = Paint()
      ..color = KidPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    switch (kind.id) {
      case 'bench':
        _bench(canvas, fill, ink);
      case 'gate':
        _gate(canvas, fill, ink);
      case 'washing_line':
        _washingLine(canvas, fill, ink);
      case 'picnic_rug':
        _picnicRug(canvas, fill, ink);
      case 'sprinkler':
        _sprinkler(canvas, fill, ink);
      case 'dog_lead':
        _dogLead(canvas, fill, ink);
      case 'bin':
        _bin(canvas, fill, ink);
      case 'puddle':
        _puddle(canvas, fill);
      case 'pigeons':
        _pigeons(canvas, fill, ink, since);
      case 'deckchair':
        _deckchair(canvas, fill, ink);
      default:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.x, size.y),
            const Radius.circular(8),
          ),
          fill,
        );
    }

    canvas.restore();
  }

  // --- the things to duck under -------------------------------------------
  //
  // Every one of these is drawn so the GAP UNDERNEATH is obvious: the child has
  // to be able to see that there is a way through before the duck button means
  // anything to them.

  void _bench(Canvas canvas, Paint fill, Paint ink) {
    final seat = Rect.fromLTWH(0, size.y * 0.1, size.x, size.y * 0.24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(seat, const Radius.circular(6)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(seat, const Radius.circular(6)),
      ink,
    );
    // A back rail, so it reads as a bench and not a table.
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y * 0.07), fill);
    // Legs at the very ends only — the gap between them is the way through.
    for (final dx in [size.x * 0.06, size.x * 0.88]) {
      canvas.drawRect(
        Rect.fromLTWH(dx, size.y * 0.34, size.x * 0.06, size.y * 0.66),
        fill,
      );
    }
  }

  void _gate(Canvas canvas, Paint fill, Paint ink) {
    final bar = Rect.fromLTWH(0, size.y * 0.05, size.x, size.y * 0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, const Radius.circular(8)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, const Radius.circular(8)),
      ink,
    );
    for (final dx in [size.x * 0.08, size.x * 0.84]) {
      canvas.drawRect(
        Rect.fromLTWH(dx, 0, size.x * 0.08, size.y),
        fill,
      );
    }
  }

  void _washingLine(Canvas canvas, Paint fill, Paint ink) {
    // The line itself.
    canvas.drawLine(
      Offset(0, size.y * 0.1),
      Offset(size.x, size.y * 0.06),
      Paint()
        ..color = KidPalette.ink
        ..strokeWidth = 3,
    );
    // Towels hanging down. They stop well short of the ground.
    for (var i = 0; i < 4; i++) {
      final x = size.x * (0.08 + i * 0.23);
      final r = Rect.fromLTWH(x, size.y * 0.08, size.x * 0.16, size.y * 0.72);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(5)),
        Paint()..color = i.isEven ? kind.color : const Color(0xFFBFE3FF),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(5)),
        ink,
      );
    }
  }

  void _picnicRug(Canvas canvas, Paint fill, Paint ink) {
    // A rug mid-shake: a wavy sheet held up at both corners.
    final path = Path()..moveTo(0, size.y * 0.2);
    for (var i = 0; i <= 6; i++) {
      final x = size.x * i / 6;
      path.lineTo(x, size.y * (0.2 + (i.isEven ? 0.08 : -0.06)));
    }
    path
      ..lineTo(size.x, size.y * 0.8)
      ..lineTo(0, size.y * 0.8)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, ink);
  }

  void _sprinkler(Canvas canvas, Paint fill, Paint ink) {
    // An arc of water. Soft and round — nothing in a five-year-old's park has
    // a spike on it.
    for (var i = 0; i < 5; i++) {
      final t = i / 4;
      canvas.drawCircle(
        Offset(size.x * t, size.y * (0.85 - sin(t * pi) * 0.72)),
        9,
        Paint()..color = kind.color.withValues(alpha: 0.75),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.44, size.y * 0.8, size.x * 0.12, size.y * 0.2),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF7FB77E),
    );
  }

  void _dogLead(Canvas canvas, Paint fill, Paint ink) {
    // A lead stretched from a post to a very pleased dog.
    //
    // The POST matters: without it the first version was a stick floating at
    // head height with nothing holding it up, which in the browser read as a
    // glitch rather than as a thing to duck under. Everything overhead in this
    // game has to be visibly attached to something.
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.02, size.y * 0.2, size.x * 0.05, size.y * 1.6),
      Paint()..color = const Color(0xFF9B7A50),
    );
    canvas.drawLine(
      Offset(size.x * 0.04, size.y * 0.3),
      Offset(size.x * 0.74, size.y * 0.5),
      Paint()
        ..color = kind.color
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    // The dog, sitting on the ground at the far end and holding the lead taut.
    final dog = Rect.fromLTWH(
      size.x * 0.7,
      size.y * 0.42,
      size.x * 0.28,
      size.y * 1.35,
    );
    canvas.drawOval(dog, Paint()..color = const Color(0xFFD8A657));
    canvas.drawOval(dog, ink);
    canvas.drawCircle(
      Offset(size.x * 0.84, size.y * 0.55),
      3.4,
      Paint()..color = KidPalette.ink,
    );
  }

  // --- the things to bump into --------------------------------------------

  void _bin(Canvas canvas, Paint fill, Paint ink) {
    final body = Rect.fromLTWH(
      size.x * 0.1,
      size.y * 0.16,
      size.x * 0.8,
      size.y * 0.84,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(8)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(8)),
      ink,
    );
    final lid = Rect.fromLTWH(0, 0, size.x, size.y * 0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(lid, const Radius.circular(6)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lid, const Radius.circular(6)),
      ink,
    );
  }

  void _puddle(Canvas canvas, Paint fill) {
    canvas.drawOval(
      Rect.fromLTWH(0, size.y * 0.2, size.x, size.y * 0.8),
      Paint()..color = kind.color.withValues(alpha: 0.8),
    );
  }

  void _pigeons(Canvas canvas, Paint fill, Paint ink, double since) {
    // A little flock. Bumped, they explode upwards — and settle again. Nothing
    // is ever squashed or driven off for good (the scope's *Not this*).
    final lift = since < 0 ? 0.0 : min(1.0, since / 0.5) * (since > 1 ? 0 : 1);
    for (var i = 0; i < 3; i++) {
      final up = lift * (18 + i * 9);
      final c = Offset(size.x * (0.2 + i * 0.3), size.y * 0.72 - up);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: size.x * 0.3, height: size.y * 0.42),
        fill,
      );
      canvas.drawOval(
        Rect.fromCenter(center: c, width: size.x * 0.3, height: size.y * 0.42),
        ink,
      );
    }
  }

  void _deckchair(Canvas canvas, Paint fill, Paint ink) {
    // A striped canvas sling on a wooden frame. The first version was a bare
    // parallelogram, which on screen read as a purple slab leaning on nothing —
    // running the game is the only way that showed up.
    final frame = Paint()
      ..color = const Color(0xFF9B7A50)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    // Back leg and front leg, making a shallow A.
    canvas.drawLine(
      Offset(size.x * 0.12, size.y),
      Offset(size.x * 0.62, size.y * 0.1),
      frame,
    );
    canvas.drawLine(
      Offset(size.x * 0.88, size.y),
      Offset(size.x * 0.42, size.y * 0.46),
      frame,
    );
    // The sling between them.
    final sling = Path()
      ..moveTo(size.x * 0.56, size.y * 0.16)
      ..lineTo(size.x * 0.86, size.y * 0.94)
      ..lineTo(size.x * 0.58, size.y * 0.94)
      ..lineTo(size.x * 0.34, size.y * 0.52)
      ..close();
    canvas.drawPath(sling, fill);
    canvas.drawPath(sling, ink);
  }
}
