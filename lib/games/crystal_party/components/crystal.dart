import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../world.dart';

/// One crystal, floating and waiting to be flown through.
///
/// ## Three cues, any one of which is enough
///
/// Blue is a **pointy shard**, pink is a **round blob**, and the two ring on
/// different chime ladders. A colourblind child reads the shape; a child who
/// cannot see the shape hears the difference (CLAUDE.md §3).
///
/// ## A missed crystal is not missed
///
/// Fly past one and it does not disappear and it is not gone: [missIt] makes it
/// twinkle and drift, and the game puts the same colour back into the run
/// further along. **There is no state in which a child is one crystal short**
/// (the scope), which is what lets the arch be a guarantee rather than a goal.
class Crystal extends PositionComponent {
  Crystal({required this.colour, required super.position})
    : super(size: Vector2(46, 52), anchor: Anchor.center);

  final CrystalColour colour;

  /// Taken, and on its way to the trail. Stops being collidable at once, so one
  /// crystal can never count twice.
  bool _taken = false;
  bool get isTaken => _taken;

  /// Drifted past. Still on screen, twinkling, but no longer collidable —
  /// the same colour comes back later rather than this one being chased.
  bool _missed = false;
  bool get isMissed => _missed;

  double _time = 0;

  /// A crystal nobody has touched bobs gently, so the sky is never static.
  double get _bob => sin(_time * 2.2 + position.x * 0.01) * 4;

  Rect get hitBox {
    // Generous: bigger than the drawn shard. Flying what LOOKS like through a
    // crystal has to take it, or the child reads a near miss as the game
    // ignoring them — the same injustice as an ignored tap.
    final w = size.x * 1.15;
    final h = size.y * 1.15;
    return Rect.fromCenter(
      center: Offset(position.x, position.y + _bob),
      width: w,
      height: h,
    );
  }

  /// Flown through. Shrinks away into the trail.
  ///
  /// The flag is set FIRST and unconditionally, so a crystal counts exactly
  /// once whatever happens to the animation — the shrink is decoration, the
  /// flag is the game. The effects are only added once it is actually mounted:
  /// an effect on an unmounted component has no target and throws, and a
  /// crystal can be taken in the same frame it is added.
  void take() {
    if (_taken) return;
    _taken = true;
    if (!isMounted) {
      removeFromParent();
      return;
    }
    add(ScaleEffect.to(Vector2.zero(), EffectController(duration: 0.22)));
    add(RemoveEffect(delay: 0.24));
  }

  /// Gone past. **Not a failure and not a loss** — it twinkles and drifts off,
  /// and the world puts this colour back in front of her later.
  void missIt() => _missed = true;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final centre = Offset(size.x / 2, size.y / 2 + _bob);
    // A missed crystal fades a little and twinkles — visibly "still around",
    // never visibly lost.
    final alpha = _missed ? 0.55 + sin(_time * 6) * 0.2 : 1.0;

    // The glow, so a crystal reads as treasure rather than as a rock.
    canvas.drawCircle(
      centre,
      size.x * 0.62,
      Paint()
        ..color = _glow.withValues(alpha: alpha * 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    final paint = Paint()..color = _core.withValues(alpha: alpha);
    switch (colour) {
      case CrystalColour.blue:
        // A pointy shard. The shape cue.
        canvas.drawPath(
          Path()
            ..moveTo(centre.dx, centre.dy - size.y * 0.46)
            ..lineTo(centre.dx + size.x * 0.3, centre.dy)
            ..lineTo(centre.dx, centre.dy + size.y * 0.46)
            ..lineTo(centre.dx - size.x * 0.3, centre.dy)
            ..close(),
          paint,
        );
        // A bright facet down one edge, so it looks faceted rather than flat.
        canvas.drawPath(
          Path()
            ..moveTo(centre.dx, centre.dy - size.y * 0.46)
            ..lineTo(centre.dx + size.x * 0.3, centre.dy)
            ..lineTo(centre.dx, centre.dy + size.y * 0.46)
            ..close(),
          Paint()..color = Colors.white.withValues(alpha: alpha * 0.35),
        );
      case CrystalColour.pink:
        // A round blob. The other shape cue — unmistakable in silhouette.
        canvas.drawCircle(centre, size.x * 0.4, paint);
        canvas.drawCircle(
          Offset(centre.dx - size.x * 0.12, centre.dy - size.y * 0.12),
          size.x * 0.13,
          Paint()..color = Colors.white.withValues(alpha: alpha * 0.55),
        );
    }
  }

  Color get _core => switch (colour) {
    CrystalColour.blue => const Color(0xFF63C7F5),
    CrystalColour.pink => const Color(0xFFFF8FC4),
  };

  Color get _glow => switch (colour) {
    CrystalColour.blue => const Color(0xFFBDEBFF),
    CrystalColour.pink => const Color(0xFFFFD3E8),
  };
}
