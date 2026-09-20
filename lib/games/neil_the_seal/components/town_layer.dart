import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../town.dart';
import '../world.dart';
import 'neil_painter.dart';

/// Draws the town and Neil in it, back to front.
///
/// One component owns the whole depth-sorted pass, for the same reason Car
/// Trip's `Traffic` does: a cone at the back of the town must not paint over
/// the seal standing in front of it, and sorting one list per frame does that
/// exactly. Neil is drawn *in* the sort rather than on top of it, so he goes
/// behind the things that are nearer the camera than he is.
///
/// Everything here is placeholder art drawn in code (CLAUDE.md §5). The squash
/// and the springback are not placeholder: they are the game, and
/// `world.dart` decides them — this file only shows them.
class TownLayer extends PositionComponent with HasGameReference<FlameGame> {
  TownLayer({required this.world}) : super(priority: -50);

  final NeilWorld world;

  TownView get view => TownView(width: size.x, height: size.y);

  @override
  void onMount() {
    super.onMount();
    size = game.size;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x > 0 && size.y > 0) this.size = size;
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    final v = view;

    // Back to front. Neil is sorted in with everything else by his own depth.
    final order = [...world.props]..sort((a, b) => a.spot.y.compareTo(b.spot.y));
    var drewNeil = false;
    for (final prop in order) {
      if (!drewNeil && prop.spot.y > world.neil.y) {
        NeilPainter.paint(canvas, v, world);
        drewNeil = true;
      }
      _paintProp(canvas, v, prop);
    }
    if (!drewNeil) NeilPainter.paint(canvas, v, world);

    _paintDust(canvas, v);
    _paintFish(canvas, v);
  }

  // --- the props -----------------------------------------------------------

  void _paintProp(Canvas canvas, TownView v, Prop prop) {
    final kind = prop.kind;
    final spot = prop.spot;
    final w = v.lengthAt(kind.width, spot.y);
    final h = v.lengthAt(kind.height, spot.y);
    if (w < 1 || h < 1) return;

    final at = v.offsetAt(spot);

    // Answering the bellow, or bumped during the nap: a small bounce that
    // settles. Nothing here is ever reached by Neil — it is pure answer.
    var bounce = 0.0;
    final answered = prop.answeredAt;
    if (answered != null && answered < 1.2) {
      bounce = sin(answered * pi * 3) * h * 0.30 * (1 - answered / 1.2);
    }

    canvas.save();
    canvas.translate(at.dx, at.dy - bounce);

    // A soft pool of shade under everything, so nothing floats.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, h * 0.04),
        width: w * 0.9,
        height: h * 0.22,
      ),
      Paint()..color = const Color(0x22000000),
    );

    // The squash. Scaled about the base, so a squashed thing settles onto the
    // ground rather than shrinking toward its own middle — and a value above 1
    // (the springback overshooting) stretches it taller, which is what makes
    // the bounce read as elastic.
    canvas.scale(1, prop.heightFactor);

    switch (kind.id) {
      case 'car':
        _car(canvas, kind, w, h, prop.heightFactor);
      case 'cone':
        _cone(canvas, kind, w, h);
      case 'jetty':
        _jetty(canvas, kind, w, h, prop);
      case 'kelp':
        _kelp(canvas, kind, w, h);
      case 'bin':
        _bin(canvas, kind, w, h, prop);
      case 'hose':
        _hose(canvas, kind, w, h);
      case 'trampoline':
        _trampoline(canvas, kind, w, h);
      case 'sand':
        _sand(canvas, kind, w, h, prop);
      case 'boat':
        _boat(canvas, kind, w, h);
      case 'ute':
        _ute(canvas, kind, w, h, 1);
      case 'shack':
        _shack(canvas, kind, w, h, prop);
      case 'cow':
        _cow(canvas, kind, w, h);
      default:
        _creature(canvas, kind, w, h, prop);
    }
    canvas.restore();

    // Things that come OUT of a prop are drawn unscaled, outside the squash —
    // seagulls out of a bin do not squash with the bin.
    if (kind.reaction == FlopReaction.tipOver) _binGulls(canvas, at, w, h, prop);
    if (kind.reaction == FlopReaction.spray) _spray(canvas, at, w, h, prop);
  }

  /// A car, and the single most important drawing in this game.
  ///
  /// The wheels are drawn OUTSIDE the squash: they stay exactly where they are
  /// while the body comes down onto them. That is what a car on its springs
  /// does, and it is the whole difference between "an enormous seal is sitting
  /// on the car" and "the car has been flattened". A five-year-old can tell
  /// those apart, and the difference is entirely in what springs back.
  void _car(Canvas canvas, PropKind kind, double w, double h, double squash) {
    final body = Rect.fromLTWH(-w / 2, -h, w, h * 0.66);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(h * 0.30)),
      Paint()..color = kind.color,
    );
    // The cabin. Rounded, like everything else here — nothing in this town has
    // a corner a child could read as sharp.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.22, -h * 1.34, w * 0.5, h * 0.48),
        Radius.circular(h * 0.22),
      ),
      Paint()..color = kind.color.withValues(alpha: 0.85),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.17, -h * 1.26, w * 0.4, h * 0.32),
        Radius.circular(h * 0.14),
      ),
      Paint()..color = const Color(0xFFD9EEF7),
    );
    final wheel = Paint()..color = kind.secondColor ?? Colors.black;
    // Undo the caller's vertical squash for the wheels only. Guarded, because
    // the springback overshoot can take the factor past 1 and a zero would
    // divide.
    canvas.save();
    canvas.scale(1, 1 / squash.clamp(0.05, 1.6));
    canvas.drawCircle(Offset(-w * 0.28, -h * 0.30), h * 0.30, wheel);
    canvas.drawCircle(Offset(w * 0.28, -h * 0.30), h * 0.30, wheel);
    canvas.restore();
  }

  void _cone(Canvas canvas, PropKind kind, double w, double h) {
    canvas.drawPath(
      Path()
        ..moveTo(0, -h)
        ..lineTo(w * 0.5, 0)
        ..lineTo(-w * 0.5, 0)
        ..close(),
      Paint()..color = kind.color,
    );
    canvas.drawRect(
      Rect.fromLTWH(-w * 0.28, -h * 0.55, w * 0.56, h * 0.18),
      Paint()..color = kind.secondColor ?? Colors.white,
    );
  }

  void _jetty(Canvas canvas, PropKind kind, double w, double h, Prop prop) {
    // Planks. When he lands they ripple along their length — the doing-oing.
    final since = prop.floppedAt;
    const planks = 6;
    for (var i = 0; i < planks; i++) {
      final p = i / (planks - 1);
      var ripple = 0.0;
      if (since != null && since < 1.0) {
        ripple = sin(since * 16 - p * 3) * h * 0.5 * (1 - since);
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            -w / 2 + p * w * 0.9,
            -h + ripple,
            w * 0.12,
            h,
          ),
          Radius.circular(h * 0.2),
        ),
        Paint()..color = i.isEven ? kind.color : (kind.secondColor ?? kind.color),
      );
    }
  }

  void _kelp(Canvas canvas, PropKind kind, double w, double h) {
    for (var i = 0; i < 4; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-w * 0.3 + i * w * 0.2, -h * 0.45 + (i.isEven ? 0 : h * 0.2)),
          width: w * 0.46,
          height: h * 0.9,
        ),
        Paint()..color = i.isEven ? kind.color : (kind.secondColor ?? kind.color),
      );
    }
  }

  void _bin(Canvas canvas, PropKind kind, double w, double h, Prop prop) {
    // Over it goes. The tip is part of the squash, so it rights itself on the
    // way back up like everything else.
    canvas.save();
    canvas.rotate(prop.squash.clamp(0.0, 1.0) * 1.1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w / 2, -h, w, h),
        Radius.circular(w * 0.2),
      ),
      Paint()..color = kind.color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.58, -h * 1.08, w * 1.16, h * 0.18),
        Radius.circular(w * 0.1),
      ),
      Paint()..color = kind.secondColor ?? kind.color,
    );
    canvas.restore();
  }

  void _hose(Canvas canvas, PropKind kind, double w, double h) {
    // A coil lying flat on the ground with the nozzle poking out. Drawn as a
    // coil rather than as an arc, because an arc of green reads as a worm.
    final coil = Paint()
      ..color = kind.secondColor ?? kind.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, h * 0.55)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 2; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-w * 0.08, -h * 0.5),
          width: w * (0.82 - i * 0.30),
          height: h * (1.7 - i * 0.6),
        ),
        coil,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.24, -h * 0.85, w * 0.30, h * 0.5),
        Radius.circular(h * 0.22),
      ),
      Paint()..color = kind.color,
    );
  }

  void _trampoline(Canvas canvas, PropKind kind, double w, double h) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -h * 0.7), width: w, height: h * 1.0),
      Paint()..color = kind.color,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -h * 0.7), width: w * 0.78, height: h * 0.72),
      Paint()..color = kind.secondColor ?? kind.color,
    );
    final leg = Paint()
      ..color = kind.secondColor ?? kind.color
      ..strokeWidth = max(1.2, h * 0.16);
    canvas.drawLine(Offset(-w * 0.38, -h * 0.5), Offset(-w * 0.42, 0), leg);
    canvas.drawLine(Offset(w * 0.38, -h * 0.5), Offset(w * 0.42, 0), leg);
  }

  void _sand(Canvas canvas, PropKind kind, double w, double h, Prop prop) {
    final patch =
        Rect.fromCenter(center: Offset(0, -h * 0.4), width: w, height: h * 1.1);
    canvas.drawOval(patch, Paint()..color = kind.color);
    // A rim and a couple of ripples. Without them a patch of dry sand is
    // invisible on a beach — and a thing a child cannot see is a thing they
    // cannot choose to sit on.
    canvas.drawOval(
      patch,
      Paint()
        ..color = kind.secondColor ?? kind.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, h * 0.22),
    );
    for (var i = 0; i < 2; i++) {
      canvas.drawArc(
        patch.deflate(w * (0.14 + i * 0.12)),
        pi * 0.15,
        pi * 0.7,
        false,
        Paint()
          ..color = (kind.secondColor ?? kind.color).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1, h * 0.12),
      );
    }
    // The dent. It deepens as he settles and smooths over as the sand springs
    // back — nothing in this town is left marked.
    final dent = prop.squash.clamp(0.0, 1.0);
    if (dent > 0.02) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -h * 0.35),
          width: w * 0.66 * dent,
          height: h * 0.6 * dent,
        ),
        Paint()..color = kind.secondColor ?? kind.color,
      );
    }
  }

  void _boat(Canvas canvas, PropKind kind, double w, double h) {
    canvas.drawPath(
      Path()
        ..moveTo(-w / 2, -h)
        ..lineTo(w / 2, -h)
        ..quadraticBezierTo(w * 0.28, 0, 0, 0)
        ..quadraticBezierTo(-w * 0.28, 0, -w / 2, -h)
        ..close(),
      Paint()..color = kind.color,
    );
    // A gunwale along the top and a seat across the middle, so the hull reads
    // as a dinghy pulled up the beach rather than as a bowl.
    canvas.drawRect(
      Rect.fromLTWH(-w / 2, -h, w, h * 0.16),
      Paint()..color = kind.secondColor ?? Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(-w * 0.12, -h * 0.84, w * 0.24, h * 0.5),
      Paint()..color = (kind.secondColor ?? Colors.white).withValues(alpha: 0.8),
    );
  }

  void _ute(Canvas canvas, PropKind kind, double w, double h, double squash) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w / 2, -h * 0.72, w, h * 0.5),
        Radius.circular(h * 0.16),
      ),
      Paint()..color = kind.color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.44, -h * 1.12, w * 0.46, h * 0.44),
        Radius.circular(h * 0.14),
      ),
      Paint()..color = kind.color.withValues(alpha: 0.9),
    );
    final wheel = Paint()..color = kind.secondColor ?? Colors.black;
    canvas.drawCircle(Offset(-w * 0.28, -h * 0.20), h * 0.24, wheel);
    canvas.drawCircle(Offset(w * 0.30, -h * 0.20), h * 0.24, wheel);
  }

  void _shack(Canvas canvas, PropKind kind, double w, double h, Prop prop) {
    canvas.drawRect(
      Rect.fromLTWH(-w / 2, -h * 0.78, w, h * 0.78),
      Paint()..color = kind.color,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-w * 0.58, -h * 0.74)
        ..lineTo(0, -h * 1.12)
        ..lineTo(w * 0.58, -h * 0.74)
        ..close(),
      Paint()..color = kind.secondColor ?? kind.color,
    );
    // The window, and the curtain that twitches when Neil bellows. It is the
    // one voice in the round that answers silently.
    final twitch = prop.answeredAt;
    final open = twitch != null && twitch < 0.9
        ? sin(twitch / 0.9 * pi) * w * 0.10
        : 0.0;
    final window = Rect.fromLTWH(-w * 0.16, -h * 0.60, w * 0.32, h * 0.3);
    canvas.drawRect(window, Paint()..color = const Color(0xFF6E8A99));
    canvas.drawRect(
      Rect.fromLTWH(window.left - open, window.top, w * 0.14, h * 0.3),
      Paint()..color = const Color(0xFFF7EFE2),
    );
  }

  void _cow(Canvas canvas, PropKind kind, double w, double h) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w / 2, -h * 0.9, w, h * 0.6),
        Radius.circular(h * 0.22),
      ),
      Paint()..color = kind.color,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-w * 0.14, -h * 0.66), width: w * 0.3, height: h * 0.22),
      Paint()..color = kind.secondColor ?? Colors.black,
    );
    canvas.drawCircle(Offset(w * 0.42, -h * 0.82), w * 0.17, Paint()..color = kind.color);
    final leg = Paint()..color = kind.secondColor ?? Colors.black;
    canvas.drawRect(Rect.fromLTWH(-w * 0.34, -h * 0.32, w * 0.12, h * 0.32), leg);
    canvas.drawRect(Rect.fromLTWH(w * 0.2, -h * 0.32, w * 0.12, h * 0.32), leg);
  }

  /// Everything alive, drawn the same way with different proportions.
  ///
  /// A child should read "that is an animal, it is watching Neil" and never
  /// have to work out which animal before deciding what to do — because there
  /// is nothing to decide: they all get out of the way by themselves.
  void _creature(Canvas canvas, PropKind kind, double w, double h, Prop prop) {
    // They all stop what they are doing to look at him, and they are delighted
    // he is here. A small hop when he is near is the whole of it.
    final hop = prop.answeredAt != null && prop.answeredAt! < 0.8
        ? sin(prop.answeredAt! / 0.8 * pi) * h * 0.5
        : 0.0;
    canvas.translate(0, -hop);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w / 2, -h * 0.82, w, h * 0.62),
        Radius.circular(h * 0.28),
      ),
      Paint()..color = kind.color,
    );
    canvas.drawCircle(
      Offset(w * 0.24, -h * 0.86),
      w * 0.30,
      Paint()..color = kind.color,
    );
    final ink = Paint()..color = kind.secondColor ?? const Color(0xFF4A3B33);
    canvas.drawCircle(Offset(w * 0.32, -h * 0.92), max(0.8, w * 0.07), ink);
    canvas.drawRect(Rect.fromLTWH(-w * 0.3, -h * 0.22, w * 0.14, h * 0.22), ink);
    canvas.drawRect(Rect.fromLTWH(w * 0.14, -h * 0.22, w * 0.14, h * 0.22), ink);
  }

  // --- things that come out of things --------------------------------------

  /// Seagulls exploding out of a tipped bin. They are gone in a second and
  /// nothing about it is alarming — no shriek, no scatter toward the child.
  void _binGulls(Canvas canvas, Offset at, double w, double h, Prop prop) {
    final since = prop.floppedAt;
    if (since == null || since > 1.4) return;
    final fade = (1 - since / 1.4).clamp(0.0, 1.0);
    for (var i = 0; i < 3; i++) {
      final a = -pi * 0.75 + i * pi * 0.25;
      final d = since * w * 3.2;
      final p = at + Offset(cos(a) * d, sin(a) * d - since * h);
      final s = w * 0.42;
      canvas.drawPath(
        Path()
          ..moveTo(p.dx - s, p.dy)
          ..quadraticBezierTo(p.dx - s * 0.4, p.dy - s * 0.55, p.dx, p.dy)
          ..quadraticBezierTo(p.dx + s * 0.4, p.dy - s * 0.55, p.dx + s, p.dy),
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.2, s * 0.22)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// The hose, spraying. It starts when he lands on it and keeps going while he
  /// is there, which is the joke.
  void _spray(Canvas canvas, Offset at, double w, double h, Prop prop) {
    if (prop.squash < 0.25) return;
    final t = (prop.floppedAt ?? 0) * 6;
    for (var i = 0; i < 9; i++) {
      final p = (i / 9 + t * 0.12) % 1.0;
      final a = -pi * 0.72 + p * pi * 0.5;
      final d = p * w * 2.4;
      canvas.drawCircle(
        at + Offset(cos(a) * d + w * 0.3, sin(a) * d - h),
        max(1, w * 0.07 * (1 - p)),
        Paint()..color = Color.fromRGBO(120, 200, 240, 0.7 * (1 - p)),
      );
    }
  }

  /// The puff of dust a landing throws up — including a landing on bare
  /// ground, which is exactly as worth a puff as any other.
  void _paintDust(Canvas canvas, TownView v) {
    final t = world.flopT;
    if (t > 0.6) return;
    final at = v.offsetAt(world.neil);
    final w = v.lengthAt(NeilPainter.bodyWidth, world.neil.y);
    final fade = (1 - t / 0.6).clamp(0.0, 1.0);
    for (var i = 0; i < 7; i++) {
      final a = pi + i * pi / 6;
      final d = t * w * 1.6;
      canvas.drawCircle(
        at + Offset(cos(a) * d, sin(a) * d * 0.35),
        max(1, w * 0.07 * fade),
        Paint()..color = Color.fromRGBO(255, 252, 240, 0.55 * fade),
      );
    }
  }

  /// The bucket of fish somebody sets down beside him while he sleeps.
  ///
  /// A gift, not a refill: nothing about Neil ever goes down, so there is
  /// nothing for it to top up (the scope: *no hunger, no health, no pet-care
  /// loop*).
  void _paintFish(Canvas canvas, TownView v) {
    final napT = world.napT;
    if (napT == null || napT < NeilWorld.fishAt) return;
    final p = ((napT - NeilWorld.fishAt) / 0.5).clamp(0.0, 1.0);
    final at = v.offsetAt(world.neil);
    final w = v.lengthAt(NeilPainter.bodyWidth, world.neil.y);
    final size = w * 0.30 * p;
    final centre = at + Offset(-w * 0.75, -size * 0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: centre, width: size, height: size * 0.9),
        Radius.circular(size * 0.16),
      ),
      Paint()..color = const Color(0xFF9FB8C4),
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: centre + Offset((i - 1) * size * 0.24, -size * 0.5),
          width: size * 0.34,
          height: size * 0.22,
        ),
        Paint()..color = const Color(0xFFB0C4D0),
      );
    }
  }
}
