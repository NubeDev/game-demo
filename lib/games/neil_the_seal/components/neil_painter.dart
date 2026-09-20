import 'dart:math';
import 'dart:ui';

import '../town.dart';
import '../world.dart';

/// Draws Neil.
///
/// A painter rather than a component, because the whole town has to be drawn
/// back to front in one pass (see `town_layer.dart`): a seal standing in front
/// of a car must cover it, and the same seal three steps further back must
/// not. Juggling Flame priorities as he moves would be the same job done less
/// reliably.
///
/// ## Why he is drawn like this
///
/// A two-tonne wild animal is frightening if it is drawn honestly, and this one
/// has to be the opposite of frightening (the scope's *Kid-rules impact*). So:
/// **round, soft-edged, wet-eyed, wobbly and slow**. No teeth. No proboscis.
/// Nothing that uses his size as a threat. Every line here is closer to a
/// beanbag than to a predator, and the eyes are deliberately far too big for
/// his head.
///
/// Placeholder art, drawn in code (CLAUDE.md §5) — but the *rhythm* is not
/// placeholder. The heave-flump lurch, the landing wobble and the flipper kick
/// are the game, and they are meant to be felt long before there is real
/// artwork.
class NeilPainter {
  const NeilPainter._();

  /// His drawn size in town units. He is as long as a car on purpose: the child
  /// is the biggest thing in this world, which is the entire fantasy.
  static const double bodyWidth = 0.22;

  /// Long and LOW. He is a mound lying on the ground, not a ball sitting on it
  /// — an elephant seal out of the water has no legs under him at all, and
  /// drawing him tall makes him loom instead of lounge.
  static const double bodyHeight = 0.105;

  /// How close a finger has to be to count as rubbing him.
  ///
  /// Much larger than he is: at roughly a quarter of the town across, this is
  /// far past the 80×80 minimum on any screen (CLAUDE.md §3, pinned by a test)
  /// and it means a child aiming at his tummy never misses and accidentally
  /// sends him somewhere instead.
  static const double rubReach = 0.13;

  static const Color _body = Color(0xFF93A0A8);
  static const Color _belly = Color(0xFFB4BFC5);
  static const Color _flipper = Color(0xFF75828B);
  static const Color _eye = Color(0xFF33312F);

  static void paint(Canvas canvas, TownView view, NeilWorld world) {
    final spot = world.neil;
    final w = view.lengthAt(bodyWidth, spot.y);
    final h = view.lengthAt(bodyHeight, spot.y);
    if (w < 1 || h < 1) return;

    final asleep = world.state == NeilState.dozing ||
        world.state == NeilState.napping;

    // --- the shape of the moment -------------------------------------------
    //
    // Three things squash and stretch him, and they add up rather than
    // overriding each other: the heave he is mid-way through, the landing he is
    // still settling from, and the breath he is taking if he is asleep.
    var squash = 1.0;
    var stretch = 1.0;
    var lift = 0.0;
    var tilt = 0.0;

    if (world.state == NeilState.galumphing) {
      final surge = NeilWorld.surgeAt(world.cycle) / (1 + 1.6);
      // Heave: he humps his back up and shoves forward. Flump: he lands flat.
      lift = h * 0.30 * surge;
      squash = 1 - 0.14 * surge;
      stretch = 1 + 0.10 * surge;
      tilt = 0.10 * surge * world.facing;
    }

    if (world.flopT < NeilWorld.flopSeconds) {
      // The landing wobble: a big squash that rings out. This is the beat the
      // whole control rests on — every tap ends in it, including the ones that
      // land on bare ground.
      final p = world.flopT / NeilWorld.flopSeconds;
      final ring = cos(p * pi * 3.2) * exp(-p * 4.5);
      squash *= 1 - 0.30 * ring;
      stretch *= 1 + 0.22 * ring;
    }

    if (asleep) {
      final t = (world.napT ?? world.dozeT ?? 0);
      final breath = sin(t * 1.5);
      squash *= 1 + 0.035 * breath;
      stretch *= 1 - 0.02 * breath;
    }

    if (world.wriggle > 0) {
      // Being rubbed: he goes completely floppy and rolls about. Deliberately
      // sloppier than anything else he does.
      final t = world.wriggle;
      tilt += sin(t * 22) * 0.16 * t;
      squash *= 1 + 0.06 * sin(t * 17);
    }

    // He sits ON whatever he landed on, not through it. Without this the seal
    // covers the car completely and the signature move of the whole game — the
    // car going down on its springs — happens somewhere the child cannot see.
    // The lift follows the prop's *squashed* height, so he sinks with it.
    final sitting = world.sittingOn;
    if (sitting != null) {
      lift += view.lengthAt(
        sitting.kind.height * sitting.heightFactor,
        spot.y,
      );
    }

    final centre = view.offsetAt(spot);
    final bodyW = w * stretch;
    final bodyH = h * squash;

    _shadow(canvas, centre, w, h, lift);

    canvas.save();
    canvas.translate(centre.dx, centre.dy - lift);
    canvas.rotate(tilt);
    canvas.scale(world.facing, 1);

    _flippers(canvas, bodyW, bodyH, world);
    _bodyShape(canvas, bodyW, bodyH);
    _head(canvas, bodyW, bodyH, world, asleep: asleep);

    canvas.restore();

    if (asleep) _sleepMarks(canvas, centre, w, h, world);
  }

  /// A soft pool of shade. It shrinks as he lifts, which is most of what sells
  /// the heave as weight rather than as a hop.
  static void _shadow(
    Canvas canvas,
    Offset centre,
    double w,
    double h,
    double lift,
  ) {
    final shrink = 1 - (lift / max(h, 1)) * 0.22;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centre.dx, centre.dy + h * 0.06),
        width: w * 0.94 * shrink,
        height: h * 0.34 * shrink,
      ),
      Paint()..color = const Color(0x2A000000),
    );
  }

  static void _bodyShape(Canvas canvas, double w, double h) {
    // One fat rounded mound with its belly on the ground. No neck, no
    // shoulders, no waist — an elephant seal out of the water is a shape with
    // no corners in it anywhere.
    final body = Rect.fromLTWH(-w / 2, -h, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(h * 0.5)),
      Paint()..color = _body,
    );
    // A paler tummy where he spreads out against the ground, so he reads as
    // something heavy resting rather than as a flat grey pill.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-w * 0.04, -h * 0.26),
        width: w * 0.70,
        height: h * 0.52,
      ),
      Paint()..color = _belly,
    );
  }

  static void _flippers(Canvas canvas, double w, double h, NeilWorld world) {
    final paint = Paint()..color = _flipper;

    // The back flipper, at the tail end. It kicks when he is rubbed — the one
    // bit of him that moves for no reason at all.
    var kick = 0.0;
    if (world.wriggle > 0) kick = sin(world.wriggle * 19) * 0.5 * world.wriggle;
    if (world.state == NeilState.galumphing) {
      kick = sin(world.cycle * pi * 2) * 0.18;
    }
    canvas.save();
    canvas.translate(-w * 0.40, -h * 0.45);
    canvas.rotate(kick * 0.6);
    // A soft rounded fan tucked against his tail end — drawn before the body so
    // it sits behind it, and kept inside his own height so it reads as part of
    // him. A pointed triangle standing off his back reads as a shark's fin,
    // which is the one animal this game must not remind anybody of.
    canvas.drawPath(
      Path()
        ..moveTo(0, -h * 0.05)
        ..quadraticBezierTo(-w * 0.10, -h * 0.40, -w * 0.19, -h * 0.30)
        ..quadraticBezierTo(-w * 0.24, -h * 0.05, -w * 0.16, h * 0.16)
        ..quadraticBezierTo(-w * 0.08, h * 0.20, 0, h * 0.08)
        ..close(),
      paint,
    );
    canvas.restore();

    // A front flipper, which is what he heaves himself along on.
    var reach = 0.0;
    if (world.state == NeilState.galumphing) {
      reach = sin(world.cycle * pi * 2) * h * 0.35;
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.16 + reach, -h * 0.12),
        width: w * 0.28,
        height: h * 0.34,
      ),
      paint,
    );
  }

  static void _head(
    Canvas canvas,
    double w,
    double h,
    NeilWorld world, {
    required bool asleep,
  }) {
    final r = h * 0.62;
    // On the front of the mound, raised just enough to be looking at the town.
    final centre = Offset(w * 0.34, -h * 1.02);

    // A yawn, once, at the top of the nap — the thing that telegraphs the snore
    // so the biggest noise in the game never arrives as a surprise.
    final napT = world.napT;
    final yawning = napT != null && napT < 1.2;
    final open = yawning ? sin(napT.clamp(0.0, 1.2) / 1.2 * pi) : 0.0;

    paintHead(
      canvas,
      centre,
      r,
      open: open,
      asleep: asleep && !yawning,
      happy: world.rubbing > 0.2,
    );
  }

  /// Neil's face on its own.
  ///
  /// Shared with the bellow button, which wears his face rather than an icon:
  /// a child who cannot read can only be told what a button does by showing
  /// them the thing that does it (CLAUDE.md §3).
  static void paintHead(
    Canvas canvas,
    Offset centre,
    double r, {
    double open = 0,
    bool asleep = false,
    bool happy = false,
  }) {
    canvas.drawCircle(centre, r, Paint()..color = _body);

    // The snout: a blunt rounded muzzle, no jaw and no teeth anywhere.
    final snout = Rect.fromCenter(
      center: centre + Offset(r * 0.62, r * 0.28),
      width: r * 1.05,
      height: r * 0.78 + r * 0.5 * open,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(snout, Radius.circular(r * 0.4)),
      Paint()..color = _belly,
    );
    if (open > 0.05) {
      // The inside of a yawn. Soft and dark, and over in a second.
      canvas.drawOval(
        Rect.fromCenter(
          center: snout.center + Offset(r * 0.12, r * 0.06),
          width: r * 0.5,
          height: r * 0.62 * open,
        ),
        Paint()..color = const Color(0xFF7A5A5E),
      );
    }
    canvas.drawCircle(
      centre + Offset(r * 1.02, r * 0.16),
      r * 0.16,
      Paint()..color = _eye,
    );

    // The eyes. Enormous, wet and dark — this is the single biggest reason he
    // reads as gentle rather than as two tonnes of wild animal.
    final eyeAt = centre + Offset(r * 0.18, -r * 0.16);
    if (asleep) {
      canvas.drawArc(
        Rect.fromCenter(center: eyeAt, width: r * 0.62, height: r * 0.5),
        pi * 0.15,
        pi * 0.7,
        false,
        Paint()
          ..color = _eye
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.2, r * 0.12)
          ..strokeCap = StrokeCap.round,
      );
    } else {
      final squint = happy ? 0.55 : 1.0;
      canvas.drawOval(
        Rect.fromCenter(
          center: eyeAt,
          width: r * 0.46,
          height: r * 0.46 * squint,
        ),
        Paint()..color = _eye,
      );
      // A glint, which is what makes an eye read as wet rather than as a hole.
      canvas.drawCircle(
        eyeAt + Offset(-r * 0.10, -r * 0.10),
        r * 0.09,
        Paint()..color = const Color(0xCCFFFFFF),
      );
    }

    // Whiskers: three light strokes, no more. They say "seal" and nothing else.
    final whisker = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = max(1, r * 0.06)
      ..strokeCap = StrokeCap.round;
    for (var i = -1; i <= 1; i++) {
      canvas.drawLine(
        centre + Offset(r * 0.95, r * 0.3 + i * r * 0.18),
        centre + Offset(r * 1.55, r * 0.22 + i * r * 0.30),
        whisker,
      );
    }
  }

  /// Z's drifting up off a sleeping seal. The only thing in the app that says
  /// "the game is waiting for you" — and it says it by looking like something
  /// rather than by stopping.
  static void _sleepMarks(
    Canvas canvas,
    Offset centre,
    double w,
    double h,
    NeilWorld world,
  ) {
    final t = world.napT ?? world.dozeT ?? 0;
    final paint = Paint()..color = const Color(0x99FFFFFF);
    for (var i = 0; i < 3; i++) {
      final p = ((t * 0.5) + i * 0.33) % 1.0;
      final size = h * (0.35 + p * 0.45);
      final at = Offset(
        centre.dx + w * 0.34 + sin(p * pi * 2) * w * 0.06,
        centre.dy - h * 1.9 - p * h * 2.2,
      );
      final fade = (1 - p) * 0.8;
      paint.color = Color.fromRGBO(255, 255, 255, fade.clamp(0.0, 1.0));
      canvas.drawPath(
        Path()
          ..moveTo(at.dx - size / 2, at.dy - size / 2)
          ..lineTo(at.dx + size / 2, at.dy - size / 2)
          ..lineTo(at.dx - size / 2, at.dy + size / 2)
          ..lineTo(at.dx + size / 2, at.dy + size / 2),
        Paint()
          ..color = paint.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.4, size * 0.16)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }
}
