import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../surf.dart';
import '../surfs_up_game.dart';
import 'draw.dart';

/// The shells along a ride, drawn in code in the soft-outline style.
///
/// Low shells float on the water and ride up the wave's face as it reaches
/// them, so they arrive right at Koko's feet. High ones bob in a bubble above
/// her head — a hop reaches them.
class Shells extends Component with HasGameReference<SurfsUpGame> {
  /// How far above the water a high shell floats, in units. Above Koko's
  /// head when she stands, so it reads as "jump for it", not "walk into it".
  static const highAbove = 0.31;
  static const radius = 0.034;

  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final surf = game.surf;
    final unit = game.unit;
    for (final shell in surf.shells) {
      if (shell.state == ShellState.collected) continue;
      final sx = game.screenX(shell.x);
      if (sx < -unit * 0.1 || sx > game.size.x + unit * 0.1) continue;
      final bob = sin(_t * 2.5 + shell.x * 3) * 0.008;
      final h = surf.seaHeight(shell.x) + (shell.high ? highAbove : 0.02) + bob;
      final at = Offset(sx, game.screenY(h));
      final r = radius * unit;
      _shell(canvas, ShellKind.values[shell.kind], at, r);
      if (shell.high) {
        canvas.drawCircle(at, r * 1.7, Paint()..color = const Color(0x33FFFFFF));
        canvas.drawCircle(
          at,
          r * 1.7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(2, r * 0.12)
            ..color = const Color(0xCCFFFFFF),
        );
        canvas.drawCircle(
          at + Offset(-r * 0.8, -r * 0.8),
          r * 0.25,
          Paint()..color = const Color(0xDDFFFFFF),
        );
      }
    }
  }

  void _shell(Canvas canvas, ShellKind kind, Offset at, double r) {
    final outline = outlinePaint(max(2, r * 0.14));
    switch (kind) {
      case ShellKind.scallop:
        // A fan with ridges, pink like Biggy's flower.
        final fan = Path()
          ..moveTo(at.dx, at.dy + r * 0.9)
          ..lineTo(at.dx - r * 1.0, at.dy - r * 0.2)
          ..arcToPoint(
            Offset(at.dx + r * 1.0, at.dy - r * 0.2),
            radius: Radius.circular(r * 1.05),
          )
          ..close();
        canvas.drawPath(fan, Paint()..color = const Color(0xFFF7B6D2));
        for (var i = -2; i <= 2; i++) {
          canvas.drawLine(
            Offset(at.dx, at.dy + r * 0.8),
            Offset(at.dx + i * r * 0.38, at.dy - r * 0.65 + i.abs() * r * 0.12),
            outlinePaint(max(1, r * 0.07), alpha: 0.6),
          );
        }
        canvas.drawPath(fan, outline);
      case ShellKind.spiral:
        final cone = Path()
          ..moveTo(at.dx - r, at.dy + r * 0.6)
          ..quadraticBezierTo(at.dx - r * 0.2, at.dy - r * 1.2, at.dx + r, at.dy - r * 0.2)
          ..quadraticBezierTo(at.dx + r * 0.6, at.dy + r * 0.8, at.dx - r, at.dy + r * 0.6)
          ..close();
        canvas.drawPath(cone, Paint()..color = const Color(0xFFF4C95D));
        canvas.drawArc(
          Rect.fromCircle(center: at + Offset(-r * 0.1, r * 0.1), radius: r * 0.4),
          0,
          pi * 1.5,
          false,
          outlinePaint(max(1, r * 0.09), alpha: 0.7),
        );
        canvas.drawPath(cone, outline);
      case ShellKind.starfish:
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final a = -pi / 2 + i * pi / 5;
          final d = i.isEven ? r * 1.1 : r * 0.5;
          final p = at + Offset(cos(a) * d, sin(a) * d);
          i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
        }
        star.close();
        canvas.drawPath(star, Paint()..color = const Color(0xFFF08A6E));
        canvas.drawPath(star, outline);
        canvas.drawCircle(at, r * 0.14, Paint()..color = const Color(0xFFFBF3E4));
    }
  }
}
