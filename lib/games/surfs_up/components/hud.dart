import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../surf.dart';
import '../surfs_up_game.dart';
import 'draw.dart';

/// Three dots, top-left, one per wave of the trip, filling as Koko rides.
///
/// A progress count, not a score (CLAUDE.md §3): never a number, never
/// emptying within a trip. A dot fills the moment she catches a wave, not
/// when the ride ends, so the reward is tied to the tap that earned it.
class WaveDots extends Component with HasGameReference<SurfsUpGame> {
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final surf = game.surf;
    final riding =
        surf.phase == SurfPhase.poppingUp || surf.phase == SurfPhase.riding;
    final filled = surf.wavesCaught + (riding ? 1 : 0);
    final r = max(14.0, 0.032 * game.unit);
    for (var i = 0; i < Surf.wavesPerTrip; i++) {
      final at = Offset(28 + r + i * r * 2.6, 28 + r);
      final on = i < filled;
      // The newest dot breathes gently while that wave is being ridden.
      final grow = on && riding && i == filled - 1 ? 1 + 0.08 * sin(_t * 5) : 1.0;
      canvas.drawCircle(
        at,
        r * grow,
        Paint()
          ..color = on ? const Color(0xFFF4C95D) : const Color(0x66FFFFFF),
      );
      canvas.drawCircle(at, r * grow, outlinePaint(max(2, r * 0.14)));
      if (on) {
        // A little wave curl inside each filled dot.
        final curl = Path()
          ..moveTo(at.dx - r * 0.55, at.dy + r * 0.2)
          ..quadraticBezierTo(at.dx - r * 0.1, at.dy - r * 0.6, at.dx + r * 0.45, at.dy - r * 0.1)
          ..quadraticBezierTo(at.dx + r * 0.05, at.dy - r * 0.15, at.dx + r * 0.1, at.dy + r * 0.25);
        canvas.drawPath(curl, outlinePaint(max(2, r * 0.13)));
      }
    }
  }
}

/// The soft cover between trips, in the next beach's sky colour. A slow fade,
/// never a flash (CLAUDE.md §3).
class Veil extends Component with HasGameReference<SurfsUpGame> {
  @override
  void render(Canvas canvas) {
    final veil = game.surf.veil;
    if (veil <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      Paint()..color = game.beach.skyBottom.withValues(alpha: veil),
    );
  }
}
