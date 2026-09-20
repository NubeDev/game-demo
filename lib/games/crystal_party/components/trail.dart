import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../world.dart';

/// The string of crystals streaming out behind her — **the progress readout,
/// and it is a picture** (CLAUDE.md §3: a progress count is allowed, a score is
/// not).
///
/// Everything about this is chosen so it cannot be read as a score:
///
///  * **It only ever gets longer.** Nothing removes a crystal from the trail.
///    There is no way to drop one, lose one or have one taken back.
///  * **There is no number**, and the crystals are not even in a countable row
///    — they wave, so at a glance it is a length, not a quantity.
///  * **It empties only at the party**, in the same frame the confetti arrives,
///    so the child never watches it drain (the same rule as Balloon Pop's
///    stars).
class Trail extends PositionComponent {
  Trail({required super.position}) : super(priority: 5);

  /// The crystals gathered, oldest first.
  final _crystals = <CrystalColour>[];

  /// How far apart they sit along the ribbon.
  static const _spacing = 26.0;

  /// The newest one pops in, so the eye lands on the thing that just happened.
  double _popIn = 0;

  double _time = 0;

  int get length => _crystals.length;

  /// Where the trail starts. Driven by the game so it follows her into the air.
  ///
  /// Named `origin` rather than `anchor` because [PositionComponent] already
  /// has an `anchor` of its own, of a different type.
  Vector2 origin = Vector2.zero();

  void add_(CrystalColour colour) {
    _crystals.add(colour);
    _popIn = 1;
  }

  /// Emptied at the party, never before.
  void clear() => _crystals.clear();

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_popIn > 0) _popIn = max(0, _popIn - dt * 3);
  }

  @override
  void render(Canvas canvas) {
    if (_crystals.isEmpty) return;

    // Drawn back to front so the newest crystal (nearest her) is on top.
    for (var i = _crystals.length - 1; i >= 0; i--) {
      // Distance back along the ribbon, newest first.
      final back = _crystals.length - 1 - i;
      final x = origin.x - back * _spacing;
      // Off the left of the screen: the trail is longer than the screen once
      // it gets going, and that is fine — it is a length, not a list to count.
      if (x < -40) break;

      // The wave. This is what stops it reading as a countable row.
      final y = origin.y + sin(_time * 3 - back * 0.5) * 9;

      final isNewest = back == 0;
      final scale = isNewest ? 1 + _popIn * 0.5 : 1.0;
      final r = 9.0 * scale;
      final colour = _crystals[i];

      canvas.drawCircle(
        Offset(x, y),
        r * 1.7,
        Paint()
          ..color = _glow(colour).withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      final paint = Paint()..color = _core(colour);
      switch (colour) {
        case CrystalColour.blue:
          // The same shard silhouette as in the world, so a child can see
          // which ones they have got without being able to read anything.
          canvas.drawPath(
            Path()
              ..moveTo(x, y - r)
              ..lineTo(x + r * 0.62, y)
              ..lineTo(x, y + r)
              ..lineTo(x - r * 0.62, y)
              ..close(),
            paint,
          );
        case CrystalColour.pink:
          canvas.drawCircle(Offset(x, y), r * 0.85, paint);
      }
    }
  }

  static Color _core(CrystalColour c) => switch (c) {
    CrystalColour.blue => const Color(0xFF63C7F5),
    CrystalColour.pink => const Color(0xFFFF8FC4),
  };

  static Color _glow(CrystalColour c) => switch (c) {
    CrystalColour.blue => const Color(0xFFBDEBFF),
    CrystalColour.pink => const Color(0xFFFFD3E8),
  };
}
