import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../shared/lantern_cast.dart';
import '../surf.dart';
import '../surfs_up_game.dart';
import 'draw.dart';

/// The sky, the sun, slow clouds, and the far sea with an island on it.
///
/// The island with the lighthouse is the horizon goal: it sits on the right
/// and grows a little nearer with every wave ridden, so a child who cannot
/// read a progress bar can still see the beach getting closer.
class Sky extends Component with HasGameReference<SurfsUpGame> {
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final beach = game.beach;
    final unit = game.unit;
    final horizon = game.horizonY;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, horizon + 2),
      Paint()
        ..shader = Gradient.linear(Offset.zero, Offset(0, horizon), [
          beach.skyTop,
          beach.skyBottom,
        ]),
    );

    // The sun: a soft halo and a plain disc. No rays that could flicker.
    final sun = Offset(
      size.x * 0.8,
      horizon - (0.08 + 0.3 * beach.sunHeight) * unit,
    );
    canvas.drawCircle(
      sun,
      0.12 * unit,
      Paint()..color = beach.sun.withValues(alpha: 0.35),
    );
    canvas.drawCircle(sun, 0.075 * unit, Paint()..color = beach.sun);

    // Clouds drift very slowly, independent of Koko — calm, not busy.
    for (var i = 0; i < 3; i++) {
      final span = size.x + 0.6 * unit;
      final x =
          (i * span / 3 - _t * 0.012 * unit * (1 + i * 0.3)) % span -
          0.3 * unit;
      final y = horizon * (0.25 + 0.18 * i);
      _cloud(canvas, Offset(x, y), unit * (0.09 + 0.02 * i));
    }

    // The island, nearer with every wave this trip.
    final progress =
        (game.surf.wavesCaught + _rideFraction()) / Surf.wavesPerTrip;
    _island(canvas, Offset(size.x * 0.97, horizon), unit * (0.5 + 0.4 * progress));

    // The far sea, lightly lined, under everything that moves.
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, size.x, size.y - horizon),
      Paint()
        ..shader = Gradient.linear(Offset(0, horizon), Offset(0, game.seaY), [
          beach.seaFar,
          beach.sea,
        ]),
    );
    final line = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = max(2, 0.006 * unit)
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row < 3; row++) {
      final y = horizon + (game.seaY - horizon) * (0.2 + 0.25 * row);
      final step = 0.5 * unit;
      // Parallax: nearer rows slide by faster as Koko moves.
      final drift = (game.surf.kokoX * unit * (0.15 + 0.15 * row)) % step;
      for (var x = -drift + row * step / 3; x < size.x; x += step) {
        canvas.drawLine(Offset(x, y), Offset(x + 0.12 * unit, y), line);
      }
    }
  }

  double _rideFraction() {
    final surf = game.surf;
    return surf.phase == SurfPhase.riding
        ? (surf.phaseTime / Surf.rideTime).clamp(0.0, 1.0)
        : 0;
  }

  void _cloud(Canvas canvas, Offset at, double r) {
    Path puff(Offset c, double radius) =>
        Path()..addOval(Rect.fromCircle(center: c, radius: radius));
    final cloud = Path.combine(
      PathOperation.union,
      Path.combine(
        PathOperation.union,
        puff(at, r),
        puff(at + Offset(r * 1.1, r * 0.25), r * 0.8),
      ),
      puff(at + Offset(-r * 1.1, r * 0.3), r * 0.7),
    );
    canvas.drawPath(cloud, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawPath(cloud, outlinePaint(r * 0.06, alpha: 0.35));
  }

  /// A green hump of island with a little striped lighthouse, sitting on the
  /// horizon with its right edge off-screen.
  void _island(Canvas canvas, Offset right, double w) {
    final h = w * 0.22;
    final hill = Path()
      ..moveTo(right.dx - w, right.dy + 1)
      ..quadraticBezierTo(right.dx - w * 0.75, right.dy - h, right.dx - w * 0.4, right.dy - h * 0.9)
      ..quadraticBezierTo(right.dx - w * 0.1, right.dy - h * 1.3, right.dx + w * 0.2, right.dy - h)
      ..lineTo(right.dx + w * 0.2, right.dy + 1)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFF9CCB7E));
    canvas.drawPath(hill, outlinePaint(w * 0.012));

    // Lighthouse: white with coral bands, on the hilltop.
    final lw = w * 0.06;
    final lh = w * 0.2;
    final base = Offset(right.dx - w * 0.4, right.dy - h * 0.88);
    final tower = Path()
      ..moveTo(base.dx - lw / 2, base.dy)
      ..lineTo(base.dx - lw * 0.35, base.dy - lh)
      ..lineTo(base.dx + lw * 0.35, base.dy - lh)
      ..lineTo(base.dx + lw / 2, base.dy)
      ..close();
    canvas.drawPath(tower, Paint()..color = const Color(0xFFFBF3E4));
    canvas.save();
    canvas.clipPath(tower);
    final band = Paint()..color = const Color(0xFFF08A6E);
    for (var i = 0; i < 2; i++) {
      canvas.drawRect(
        Rect.fromLTWH(base.dx - lw, base.dy - lh * (0.3 + 0.35 * i), lw * 2, lh * 0.15),
        band,
      );
    }
    canvas.restore();
    canvas.drawPath(tower, outlinePaint(w * 0.01));
    final lamp = Rect.fromCenter(
      center: Offset(base.dx, base.dy - lh - lw * 0.35),
      width: lw * 0.8,
      height: lw * 0.7,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lamp, Radius.circular(lw * 0.2)),
      Paint()..color = const Color(0xFFF4C95D),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lamp, Radius.circular(lw * 0.2)),
      outlinePaint(w * 0.01),
    );
  }
}

/// The near sea: the moving surface with its swells, filled to the bottom.
class Sea extends Component with HasGameReference<SurfsUpGame> {
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  /// The surface's screen y at screen x [sx] — swells plus a small ripple.
  double surfaceY(double sx) {
    final x = game.worldX(sx);
    final ripple = 0.006 * sin(x * 9 + _t * 1.6) + 0.004 * sin(x * 23 - _t);
    return game.screenY(game.surf.seaHeight(x) + ripple);
  }

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final unit = game.unit;
    final beach = game.beach;
    final step = max(4.0, size.x / 160);

    final surface = Path()..moveTo(0, surfaceY(0));
    for (var sx = step; sx <= size.x + step; sx += step) {
      surface.lineTo(sx, surfaceY(sx));
    }
    final body = Path.from(surface)
      ..lineTo(size.x + step, size.y)
      ..lineTo(0, size.y)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, game.seaY - 0.2 * unit),
          Offset(0, size.y),
          [beach.sea, beach.seaDeep],
        ),
    );

    // A deeper line under the foam, so the water has an edge like the cast.
    canvas.drawPath(
      surface,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = beach.seaDeep
        ..strokeWidth = 0.014 * unit
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      surface,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 0.008 * unit
        ..strokeJoin = StrokeJoin.round,
    );

    // White foam on each crest, thicker the bigger the swell.
    for (final s in game.surf.swells) {
      if (s.size < 0.2) continue;
      final foam = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: min(1, s.size))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.018 * unit * min(1.4, s.size);
      final from = game.screenX(s.x - 0.2);
      final to = game.screenX(s.x + 0.06);
      final crest = Path()..moveTo(from, surfaceY(from));
      for (var sx = from; sx <= to; sx += step) {
        crest.lineTo(sx, surfaceY(sx) + 0.004 * unit);
      }
      canvas.drawPath(crest, foam);
    }
  }
}

/// The beach, once it is in sight on the last wave: sand rising out of the
/// water, and friends waiting on it who bounce at the party.
class BeachAhead extends Component with HasGameReference<SurfsUpGame> {
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  /// Each friend's height in units. The cast have very different body types
  /// (the style guide makes it a rule), so one height would make Tiko, who is
  /// flat, a giant and Biggy, who is tall, a dot.
  static const friendHeight = {
    LanternFriend.biggy: 0.27,
    LanternFriend.luna: 0.22,
    LanternFriend.tobi: 0.19,
    LanternFriend.tiko: 0.14,
    LanternFriend.pacho: 0.19,
  };

  /// Where each friend stands, past the water's edge.
  static double friendX(double shore, int i) => shore + 1.15 + i * 0.3;

  @override
  void render(Canvas canvas) {
    final surf = game.surf;
    final shore = surf.shoreX;
    if (shore == null) return;
    final size = game.size;
    final unit = game.unit;
    if (game.screenX(shore - 0.5) > size.x) return;

    final step = max(4.0, size.x / 160);

    // The beach going back to the horizon, behind the friends — without it
    // they seem to stand in the far sea.
    final backFrom = game.screenX(shore + 0.3);
    final backTop = game.horizonY - 0.03 * unit;
    // Only its top edge is outlined, and it stops at sea level: the near
    // sand covers everything below that. (Closed down to the bottom of the
    // screen, it showed as a block of sand standing in the water as the beach
    // slid in.)
    final ridge = Path()
      ..moveTo(backFrom, game.seaY)
      ..cubicTo(
        backFrom + 0.3 * unit,
        game.seaY - 0.02 * unit,
        backFrom + 0.3 * unit,
        backTop,
        backFrom + 0.75 * unit,
        backTop,
      )
      ..lineTo(size.x + step, backTop);
    final back = Path.from(ridge)
      ..lineTo(size.x + step, game.seaY)
      ..close();
    canvas.drawPath(
      back,
      Paint()..color = Color.lerp(game.beach.sand, LanternCast.outline, 0.08)!,
    );
    canvas.drawPath(ridge, outlinePaint(0.008 * unit));
    _tufts(canvas, backFrom + 0.9 * unit, backTop, unit);

    // The near sand, with its underwater slope going down out of sight, so
    // it rises out of the sea instead of starting at a cliff.
    double profile(double x) {
      if (x >= shore) return surf.sandHeight(x);
      final d = (shore - x) / 0.5;
      return surf.sandHeight(shore) - 0.5 * d * d;
    }

    final start = game.screenX(shore - 0.5);
    final sand = Path()..moveTo(start, size.y);
    for (var sx = start; sx <= size.x + step; sx += step) {
      sand.lineTo(sx, game.screenY(profile(game.worldX(sx))));
    }
    sand
      ..lineTo(size.x + step, size.y)
      ..close();
    canvas.drawPath(sand, Paint()..color = game.beach.sand);
    canvas.drawPath(sand, outlinePaint(0.008 * unit));
    // Seen through the water where it is under the sea: tinted, fading out
    // to dry sand at the waterline, where the profile crosses sea level.
    final waterline = game.screenX(shore + 0.135);
    final sea = game.beach.sea;
    canvas.save();
    canvas.clipPath(sand);
    canvas.drawRect(
      Rect.fromLTRB(0, game.seaY + 0.004 * unit, waterline, size.y),
      Paint()
        ..shader = Gradient.linear(
          Offset(waterline - 0.3 * unit, 0),
          Offset(waterline, 0),
          [sea.withValues(alpha: 0.65), sea.withValues(alpha: 0)],
        ),
    );
    canvas.restore();

    // Foam where the water laps the sand.
    final edge = game.screenX(shore + 0.15);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(edge, game.screenY(0.005)),
        width: 0.35 * unit,
        height: 0.03 * unit,
      ),
      Paint()..color = const Color(0xDDFFFFFF),
    );

    final party = surf.phase == SurfPhase.party;
    final friends = game.beach.friends;
    for (var i = 0; i < friends.length; i++) {
      final friend = friends[i];
      final image = game.friendImages[friend]!;
      final x = friendX(shore, i);
      final h = friendHeight[friend]! * unit;
      // At the party they bounce in turn; before it, a gentle sway of
      // waiting. Neither is fast — bouncy, not frantic.
      final bounce = party
          ? (sin(_t * 6 + i * 1.3)).abs() * 0.05 * unit
          : (sin(_t * 2 + i)).abs() * 0.008 * unit;
      final groundY = game.screenY(surf.sandHeight(x));
      final sx = game.screenX(x);
      // Everyone faces left, towards Koko arriving. The art faces right.
      final w = h * image.width / image.height;
      canvas.save();
      canvas.translate(sx, groundY - bounce);
      canvas.scale(-1, 1);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(-w / 2, -h, w, h),
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    }
  }

  /// A few tufts of dune grass along the back of the beach.
  void _tufts(Canvas canvas, double fromX, double y, double unit) {
    final grass = Paint()
      ..color = const Color(0xFF7FB069)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.008 * unit
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final x = fromX + i * 0.22 * unit;
      if (x > game.size.x) break;
      for (var b = -1; b <= 1; b++) {
        canvas.drawLine(
          Offset(x, y + 0.005 * unit),
          Offset(x + b * 0.018 * unit, y - (0.035 - b.abs() * 0.01) * unit),
          grass,
        );
      }
    }
  }
}
