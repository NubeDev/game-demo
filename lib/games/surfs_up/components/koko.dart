import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../surf.dart';
import '../surfs_up_game.dart';
import 'draw.dart';

/// Koko on her surfboard, and the spray she throws up.
///
/// The board is drawn in code; Koko is the approved SVG. She has one pose, so
/// sitting, popping up and riding are made from it by squash and stretch:
/// crouched low while paddling, a springy overshoot on the pop-up, tall on
/// the wave.
class KokoOnBoard extends Component with HasGameReference<SurfsUpGame> {
  /// Koko's standing height, in units.
  static const height = 0.26;

  static const boardLength = 0.4;
  static const boardThickness = 0.045;

  /// Where her feet are across the picture: her body is right of centre in
  /// the art, because her tail sweeps out to the left.
  static const feetAcross = 0.58;

  double _t = 0;
  double _stand = 0;
  double _lookBack = 0;
  double _sprayClock = 0;
  final _spray = <_Drop>[];
  final _random = Random(5);

  /// Koko turns to look over her shoulder for the next swell.
  void lookBack() => _lookBack = 0.9;

  /// A paddle splash by her hands, or a big one as a wave breaks.
  void splash({bool big = false}) {
    final n = big ? 14 : 7;
    for (var i = 0; i < n; i++) {
      final a = -pi / 2 + (_random.nextDouble() - 0.5) * 2.2;
      final speed = (big ? 0.5 : 0.3) * (0.6 + _random.nextDouble() * 0.6);
      _spray.add(
        _Drop(
          Offset(big ? -0.1 : 0.12, 0),
          Offset(cos(a) * speed, sin(a) * speed),
        ),
      );
    }
  }

  @override
  void update(double dt) {
    _t += dt;
    _lookBack = max(0, _lookBack - dt);
    final surf = game.surf;

    final target = switch (surf.phase) {
      SurfPhase.paddling || SurfPhase.settling || SurfPhase.veil => 0.0,
      _ => 1.0,
    };
    // Up quickly (the pop-up is the reward), down gently.
    final rate = target > _stand ? 1 / Surf.popUpTime : 1.2;
    _stand = target > _stand
        ? min(target, _stand + rate * dt)
        : max(target, _stand - rate * dt);

    // Spray off the tail while riding — fast water, the feeling of speed.
    if (surf.phase == SurfPhase.riding && surf.hopT == null) {
      _sprayClock += dt;
      while (_sprayClock > 0.04) {
        _sprayClock -= 0.04;
        _spray.add(
          _Drop(
            Offset(-boardLength / 2, 0),
            Offset(
              -0.25 - _random.nextDouble() * 0.2,
              -0.15 - _random.nextDouble() * 0.25,
            ),
          ),
        );
      }
    }
    for (final d in _spray) {
      d.age += dt;
      d.at += d.velocity * dt;
      d.velocity += const Offset(0, 1.1) * dt;
    }
    _spray.removeWhere((d) => d.age > 0.6);
  }

  @override
  void render(Canvas canvas) {
    final surf = game.surf;
    final unit = game.unit;
    final x = game.kokoScreenX;
    final bob = surf.phase == SurfPhase.paddling
        ? sin(_t * 2.2) * 0.006
        : 0.0;
    final boardY = game.screenY(surf.boardHeight(surf.kokoX) + bob);
    // Tilted with the water, but less than the full slope: the full slope
    // pitched her nose-down so far she looked like she was falling.
    final tilt = -atan(surf.boardSlope * 0.6).clamp(-0.3, 0.3);

    // The spray sits behind the board, in sea coordinates at Koko's feet.
    final drop = Paint()..color = const Color(0xEEFFFFFF);
    for (final d in _spray) {
      final r = (1 - d.age / 0.6) * 0.012 * unit;
      canvas.drawCircle(Offset(x, boardY) + d.at * unit, r, drop);
    }

    canvas.save();
    canvas.translate(x, boardY);
    canvas.rotate(tilt);
    _board(canvas, unit);

    // Koko, lifted by her hop, leaning a little less than the board does.
    canvas.translate(0, -surf.hopLift * unit);
    canvas.rotate(-tilt * 0.4);
    final image = game.kokoImage;
    final pop = _popSquash();
    final h = height * unit * (0.78 + 0.22 * _stand) * pop;
    final w = h * image.width / image.height / sqrt(pop);
    // Her thongs sink into the board's top edge a little, so she stands on
    // it rather than hovering.
    final feet = -boardThickness * 0.3 * unit;
    if (_lookBack > 0) canvas.scale(-1, 1);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(-w * feetAcross, feet - h, w, h),
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  /// A stretch at the top of the pop-up and a squash on landing a hop:
  /// the bounce that makes it feel springy.
  double _popSquash() {
    final surf = game.surf;
    if (surf.phase == SurfPhase.poppingUp) {
      final p = (surf.phaseTime / Surf.popUpTime).clamp(0.0, 1.0);
      return 1 + 0.18 * sin(p * pi);
    }
    final t = surf.hopT;
    if (t != null) {
      final p = t / Surf.hopTime;
      return p < 0.15 ? 1 - 0.6 * p : 1 + 0.08 * sin(p * pi);
    }
    return 1;
  }

  /// A cream board with a coral stripe and an upturned nose, facing right.
  void _board(Canvas canvas, double unit) {
    final l = boardLength * unit;
    final t = boardThickness * unit;
    final board = Path()
      ..moveTo(-l / 2, -t * 0.5)
      ..quadraticBezierTo(0, -t * 0.75, l * 0.36, -t * 0.6)
      ..quadraticBezierTo(l * 0.5, -t * 0.6, l * 0.52, -t * 1.1)
      ..quadraticBezierTo(l * 0.5, t * 0.45, l * 0.3, t * 0.5)
      ..lineTo(-l / 2 + t * 0.4, t * 0.5)
      ..quadraticBezierTo(-l / 2, t * 0.5, -l / 2, -t * 0.5)
      ..close();
    canvas.drawPath(board, Paint()..color = const Color(0xFFFBF3E4));
    canvas.drawLine(
      Offset(-l * 0.44, -t * 0.08),
      Offset(l * 0.42, -t * 0.18),
      Paint()
        ..color = const Color(0xFFF08A6E)
        ..strokeWidth = t * 0.3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(board, outlinePaint(max(2, 0.007 * unit)));
  }
}

class _Drop {
  _Drop(this.at, this.velocity);

  /// Relative to Koko's feet, in units.
  Offset at;
  Offset velocity;
  double age = 0;
}
