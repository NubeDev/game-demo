import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../town.dart';

/// Sky, sea and ground — the town behind the town.
///
/// Tasmania is weatherboard, kelp, wallabies and a big grey sky, and this is
/// the grey sky. It is deliberately the quietest thing on screen: the props are
/// what a child is looking for, so the background stays muted and low-contrast
/// (the same rule that keeps `KidPalette`'s backgrounds pale).
///
/// **No text anywhere** — no place names, no signs, no numbers on anything
/// (CLAUDE.md §3).
///
/// A location change cross-fades rather than cutting, so waking up somewhere
/// new after a nap is a gentle arrival rather than the screen being swapped
/// out from under a half-asleep child.
class TownBackdrop extends PositionComponent with HasGameReference<FlameGame> {
  TownBackdrop({required TownPlace place})
      : _from = place,
        _to = place,
        super(priority: -100);

  TownPlace _from;
  TownPlace _to;

  /// 0..1 through the cross-fade. 1 means settled.
  double _t = 1;

  /// How long a location takes to arrive. Slow on purpose.
  static const double _fadeSeconds = 1.1;

  TownPlace get place => _to;

  void changeTo(TownPlace next) {
    if (next == _to) return;
    _from = _to;
    _to = next;
    _t = 0;
  }

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
  void update(double dt) {
    super.update(dt);
    if (_t < 1) _t = min(1, _t + dt / _fadeSeconds);
  }

  Color _blend(Color Function(TownPlace) pick) =>
      Color.lerp(pick(_from), pick(_to), Curves.easeInOut.transform(_t))!;

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    final v = view;
    final sky = _blend((p) => p.sky);
    final sea = _blend((p) => p.sea);
    final far = _blend((p) => p.groundFar);
    final near = _blend((p) => p.groundNear);

    final whole = Offset.zero & size.toSize();

    // Sky: big, pale and empty. Most of the top half of the screen.
    canvas.drawRect(
      whole,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sky, Color.lerp(sky, Colors.white, 0.45)!],
        ).createShader(whole),
    );

    // A headland, so the horizon is not a ruled line.
    _headland(canvas, v, sea);

    // The sea, between the headland and the shore.
    final seaTop = v.horizonY - v.height * 0.12;
    final seaRect = Rect.fromLTRB(0, seaTop, size.x, v.horizonY);
    canvas.drawRect(
      seaRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(sea, Colors.white, 0.25)!, sea],
        ).createShader(seaRect),
    );

    // Three slow lines of swell. Nothing moves fast in this town.
    final swell = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, v.height * 0.006)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = seaTop + seaRect.height * (0.35 + i * 0.22);
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.x; x += size.x / 12) {
        path.lineTo(x, y + sin(x / size.x * pi * 4 + i) * v.height * 0.004);
      }
      canvas.drawPath(path, swell);
    }

    // The ground Neil is on: far colour at the shore, near colour at the
    // child's end of the town.
    final ground = Rect.fromLTRB(0, v.horizonY, size.x, size.y);
    canvas.drawRect(
      ground,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [far, near],
        ).createShader(ground),
    );
  }

  /// A low hill across the back of the sea. Shape only — no detail, because
  /// nothing back there is a thing a child can do anything with.
  void _headland(Canvas canvas, TownView v, Color sea) {
    final top = v.horizonY - v.height * 0.12;
    canvas.drawPath(
      Path()
        ..moveTo(0, top)
        ..lineTo(0, top - v.height * 0.05)
        ..quadraticBezierTo(
          size.x * 0.22,
          top - v.height * 0.12,
          size.x * 0.48,
          top - v.height * 0.04,
        )
        ..quadraticBezierTo(
          size.x * 0.74,
          top + v.height * 0.02,
          size.x,
          top - v.height * 0.06,
        )
        ..lineTo(size.x, top)
        ..close(),
      Paint()..color = Color.lerp(sea, Colors.black, 0.12)!.withValues(alpha: 0.8),
    );
  }
}
