import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../wardrobe.dart';

/// The dog, drawn in code.
///
/// Placeholder art (CLAUDE.md §5): flat shapes standing in for the Rive dog.
/// The *reactions* are real though — the whole game is what the dog does about
/// what it is wearing, so they are tweened here rather than left as a TODO,
/// otherwise there is nothing to judge by playing.
///
/// When the Rive dog arrives this widget is replaced by `RiveCharacter` driven
/// through data binding; [feeling] and [outfit] become bound properties and
/// nothing else in the game changes.
///
/// **The dog is ALWAYS visibly happy** — see the scope's Kid-rules impact.
/// Shivering and panting are slapstick: the tail never stops wagging, the mouth
/// stays smiling, and nothing whimpers. A five-year-old reads a distressed
/// animal as real, and a game about making a dog miserable is not this game.
class Dog extends StatelessWidget {
  const Dog({
    super.key,
    required this.outfit,
    required this.feeling,
    required this.t,
    this.reaching = false,
  });

  final Outfit outfit;
  final DogFeeling feeling;

  /// True while the child is dragging something. The dog perks up — ears lift
  /// and it bounces gently — so it is obvious where clothes are meant to go
  /// without a single word of instruction (CLAUDE.md §3).
  final bool reaching;

  /// Free-running animation clock in seconds, driven by the screen's ticker.
  final double t;

  @override
  Widget build(BuildContext context) {
    // Each feeling gets its own idle motion. This is the payoff, so it is
    // exaggerated: a five-year-old should read it across the room.
    final shiver = feeling == DogFeeling.tooCold
        ? sin(t * 26) * 3.2 // fast, small — teeth-chattering, not thrashing
        : 0.0;
    final pant = feeling == DogFeeling.tooHot
        ? sin(t * 5) * 2.0 // slow heave, tongue out below
        : 0.0;
    final drip = feeling == DogFeeling.tooWet ? sin(t * 3) * 1.5 : 0.0;
    // Just-right is a proud, bouncy little hop.
    final hop = feeling == DogFeeling.justRight
        ? -(sin(t * 4).abs() * 7)
        : 0.0;
    final breathe = sin(t * 2) * 1.5;
    // An eager little bounce while something is being carried toward it.
    final eager = reaching ? -(sin(t * 7).abs() * 5) : 0.0;

    return Transform.translate(
      offset: Offset(shiver + drip, hop + pant + breathe + eager),
      child: CustomPaint(
        size: const Size(280, 292),
        painter: _DogPainter(
          outfit: outfit,
          feeling: feeling,
          t: t,
          reaching: reaching,
        ),
      ),
    );
  }
}

class _DogPainter extends CustomPainter {
  _DogPainter({
    required this.outfit,
    required this.feeling,
    required this.t,
    this.reaching = false,
  });

  final Outfit outfit;
  final DogFeeling feeling;
  final double t;
  final bool reaching;

  static const _fur = Color(0xFFD9A05B);
  static const _furDark = Color(0xFFBE8443);
  // A cold dog goes a *little* blue. Kept subtle: a vivid blue dog reads as
  // ill rather than as the cartoon shorthand for chilly.
  static const _furCold = Color(0xFFC6B49B);

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()
      ..color = feeling == DogFeeling.tooCold ? _furCold : _fur;
    final ink = Paint()
      ..color = KidPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;

    // Tail — ALWAYS wagging, in every feeling. This is the single clearest
    // signal that the dog is fine, and it is why a shivering dog stays funny.
    final wag = sin(t * 9) * 0.5;
    canvas.save();
    canvas.translate(cx + 78, 170);
    canvas.rotate(-0.5 + wag);
    // Tapered and curved, anchored on the BODY. A straight bar up at head
    // height reads as a stick, not a tail.
    final tail = Path()
      ..moveTo(0, 6)
      ..quadraticBezierTo(34, 2, 46, -22)
      ..quadraticBezierTo(34, 14, 0, -8)
      ..close();
    canvas.drawPath(tail, Paint()..color = _furDark);
    canvas.restore();

    // Legs. They run to the bottom of the canvas so the dog STANDS on the
    // ground rather than hovering above it — a floating dog reads as broken.
    for (final dx in [-46.0, -14.0, 16.0, 48.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + dx - 12, 196, 24, 86),
          const Radius.circular(12),
        ),
        Paint()..color = _furDark,
      );
      // A paw, so the leg ends in something rather than just stopping.
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + dx, 280), width: 30, height: 20),
        Paint()..color = _fur,
      );
    }

    // Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 176), width: 176, height: 108),
      const Radius.circular(54),
    );
    canvas.drawRRect(bodyRect, body);
    canvas.drawRRect(bodyRect, ink);

    _paintBody(canvas, cx);
    _paintFeet(canvas, cx);

    // Head
    final headCenter = Offset(cx, 92);
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: headCenter, width: 150, height: 130),
      const Radius.circular(62),
    );

    // Ears: long and floppy, hanging DOWN the sides of the head. Round ears set
    // behind the head read as a bear; the flop is what says "dog" at a glance.
    // Ears lift and shorten while the dog is waiting to catch something —
    // the cartoon shorthand for "perked up".
    final earLift = reaching ? 14.0 : 0.0;
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + 72 * side, 104 - earLift),
          width: 42,
          height: 96 - earLift,
        ),
        Paint()..color = _furDark,
      );
    }

    canvas.drawRRect(headRect, body);
    canvas.drawRRect(headRect, ink);

    // Muzzle + nose + the permanent smile.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 122), width: 78, height: 54),
      Paint()..color = const Color(0xFFF0DCC0),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 106), width: 26, height: 20),
      Paint()..color = KidPalette.ink,
    );
    final smile = Path()
      ..moveTo(cx - 18, 128)
      ..quadraticBezierTo(cx, 142, cx + 18, 128);
    canvas.drawPath(smile, ink);

    // Panting tongue — only when too hot, and it is comic, not laboured.
    if (feeling == DogFeeling.tooHot) {
      final loll = 14 + sin(t * 5).abs() * 10;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, 134 + loll / 2), width: 24, height: loll),
          const Radius.circular(11),
        ),
        Paint()..color = const Color(0xFFFF8FA8),
      );
    }

    _paintEyes(canvas, cx);
    _paintFace(canvas, cx);
    _paintHead(canvas, cx);
    _paintWeatherFeeling(canvas, size, cx);
  }

  /// Eyes: two happy arcs, closed to a contented squint when just right.
  void _paintEyes(Canvas canvas, double cx) {
    final ink = Paint()
      ..color = KidPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // Hidden behind sunglasses.
    if (outfit[Slot.face]?.id == 'sunglasses') return;

    for (final side in [-1.0, 1.0]) {
      final ex = cx + 30 * side;
      if (feeling == DogFeeling.justRight) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(ex, 86), width: 26, height: 22),
          pi, pi, false, ink,
        );
      } else {
        canvas.drawCircle(Offset(ex, 84), 7, Paint()..color = KidPalette.ink);
      }
    }
  }

  void _paintHead(Canvas canvas, double cx) {
    final item = outfit[Slot.head];
    if (item == null) return;
    final paint = Paint()..color = item.color;
    final ink = Paint()
      ..color = KidPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    switch (item.id) {
      case 'woolly_hat':
        final r = RRect.fromRectAndCorners(
          Rect.fromCenter(center: Offset(cx, 30), width: 130, height: 54),
          topLeft: const Radius.circular(40),
          topRight: const Radius.circular(40),
        );
        canvas.drawRRect(r, paint);
        canvas.drawRRect(r, ink);
        canvas.drawCircle(Offset(cx, 2), 16, paint);
        canvas.drawCircle(Offset(cx, 2), 16, ink);
      case 'sun_hat':
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, 40), width: 190, height: 34),
          paint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, 40), width: 190, height: 34),
          ink,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, 22), width: 96, height: 46),
          paint,
        );
      case 'party_hat':
        final p = Path()
          ..moveTo(cx, -12)
          ..lineTo(cx - 40, 46)
          ..lineTo(cx + 40, 46)
          ..close();
        canvas.drawPath(p, paint);
        canvas.drawPath(p, ink);
        canvas.drawCircle(Offset(cx, -14), 11, Paint()..color = KidPalette.star);
      case 'umbrella_hat':
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, 44), width: 210, height: 140),
          pi, pi, true, paint,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, 44), width: 210, height: 140),
          pi, pi, true, ink,
        );
    }
  }

  void _paintFace(Canvas canvas, double cx) {
    final item = outfit[Slot.face];
    if (item == null) return;
    final paint = Paint()..color = item.color;

    switch (item.id) {
      case 'sunglasses':
        for (final side in [-1.0, 1.0]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx + 31 * side, 84), width: 50, height: 34),
              const Radius.circular(12),
            ),
            paint,
          );
        }
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, 84), width: 16, height: 7), paint);
      case 'scarf':
        final ink = Paint()
          ..color = KidPalette.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        // Round the neck: an oval band that follows the neckline, so it wraps
        // rather than sticking out sideways like a plank.
        final band = Rect.fromCenter(
          center: Offset(cx, 158),
          width: 124,
          height: 34,
        );
        canvas.drawOval(band, paint);
        canvas.drawOval(band, ink);
        // One end hanging down the front, slightly tapered.
        final tailEnd = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx + 46, 186), width: 28, height: 52),
          const Radius.circular(14),
        );
        canvas.drawRRect(tailEnd, paint);
        canvas.drawRRect(tailEnd, ink);
    }
  }

  void _paintBody(Canvas canvas, double cx) {
    final item = outfit[Slot.body];
    if (item == null) return;
    final paint = Paint()..color = item.color;
    final ink = Paint()
      ..color = KidPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    switch (item.id) {
      case 'snow_coat':
      case 'raincoat':
        final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, 176), width: 182, height: 112),
          const Radius.circular(56),
        );
        canvas.drawRRect(r, paint);
        canvas.drawRRect(r, ink);
        // Quilting, so a coat reads as a coat and not a painted dog.
        for (final dy in [152.0, 182.0]) {
          canvas.drawLine(Offset(cx - 74, dy), Offset(cx + 74, dy), ink);
        }
        // Collar and cuffs: without them the coat reads as a coloured tube.
        final collar = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, 132), width: 104, height: 30),
          const Radius.circular(15),
        );
        canvas.drawRRect(collar, paint);
        canvas.drawRRect(collar, ink);
        for (final dx in [-46.0, 48.0]) {
          final cuff = RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + dx - 14, 200, 28, 22),
            const Radius.circular(9),
          );
          canvas.drawRRect(cuff, paint);
          canvas.drawRRect(cuff, ink);
        }
      case 'swimming_trunks':
        // Sit ON the body's lower half, not beside it: they are worn, not held.
        final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx + 24, 206), width: 112, height: 54),
          const Radius.circular(16),
        );
        canvas.drawRRect(r, paint);
        canvas.drawRRect(r, ink);
        // A waistband, so it reads as trunks rather than a patch of colour.
        canvas.drawLine(
          Offset(cx - 32, 190),
          Offset(cx + 80, 190),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7,
        );
    }
  }

  void _paintFeet(Canvas canvas, double cx) {
    final item = outfit[Slot.feet];
    if (item == null) return;
    final paint = Paint()..color = item.color;
    final ink = Paint()
      ..color = KidPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    for (final dx in [-46.0, -14.0, 16.0, 48.0]) {
      switch (item.id) {
        case 'wellies':
        case 'snow_boots':
          final r = RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + dx - 16, 226, 32, 62),
            const Radius.circular(10),
          );
          canvas.drawRRect(r, paint);
          canvas.drawRRect(r, ink);
        case 'flip_flops':
          final r = RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + dx - 18, 280, 36, 14),
            const Radius.circular(7),
          );
          canvas.drawRRect(r, paint);
          canvas.drawRRect(r, ink);
      }
    }
  }

  /// The little symbols that say what the dog feels — no text, so these carry
  /// the whole message (CLAUDE.md §3: the player cannot read).
  void _paintWeatherFeeling(Canvas canvas, Size size, double cx) {
    switch (feeling) {
      case DogFeeling.tooCold:
        // Chilly puffs, drifting up. Not icicles: nothing should look painful.
        for (var i = 0; i < 3; i++) {
          final phase = (t * 0.6 + i * 0.33) % 1.0;
          canvas.drawCircle(
            Offset(cx + 92 + i * 9, 96 - phase * 60),
            7 - phase * 3,
            Paint()..color = const Color(0xFF9FD4F0).withValues(alpha: 1 - phase),
          );
        }
      case DogFeeling.tooHot:
        // One comic sweat drop.
        final phase = (t * 0.9) % 1.0;
        canvas.drawCircle(
          Offset(cx - 86, 56 + phase * 40),
          8,
          Paint()..color = const Color(0xFF7FC8F0).withValues(alpha: 1 - phase),
        );
      case DogFeeling.tooWet:
        for (var i = 0; i < 4; i++) {
          final phase = (t * 1.6 + i * 0.25) % 1.0;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(cx - 60 + i * 40, 20 + phase * 150, 5, 16),
              const Radius.circular(3),
            ),
            Paint()..color = const Color(0xFF7FB4D8).withValues(alpha: 0.8),
          );
        }
      case DogFeeling.justRight:
      case DogFeeling.fine:
        break;
    }
  }

  @override
  bool shouldRepaint(_DogPainter old) =>
      old.t != t ||
      old.outfit != outfit ||
      old.feeling != feeling ||
      old.reaching != reaching;
}
