import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../../../shared/kid_shapes.dart';
import '../park.dart';

/// The park Quacky waddles through: sky, clouds, far trees, path.
///
/// Everything here is **scenery only** — nothing is ever collided with and
/// nothing can be missed. It exists so Quacky reads as chasing someone
/// *somewhere* rather than on a treadmill, which is what makes the park
/// changing at a celebration feel like a reward.
///
/// Three parallax layers (clouds slowest, trees, then the path). With a single
/// flat layer a child cannot tell he is moving at all.
///
/// Place changes are a **cross-fade, never a cut**: a hard cut is exactly the
/// kind of startling change CLAUDE.md §3 rules out, and at five it reads as the
/// game having broken.
class ParkView extends PositionComponent with HasGameReference<FlameGame> {
  ParkView({Random? random, this.groundFraction = 0.32})
    : _random = random ?? Random(),
      super(priority: -100);

  /// How much of the screen height is path and grass. The rest is sky.
  final double groundFraction;

  final Random _random;

  ParkPlace _place = ParkPlace.pond;
  ParkPlace? _incoming;
  double _fade = 0;

  static const _fadeSeconds = 1.4;

  ParkPlace get place => _place;

  final _clouds = <_Drifter>[];
  final _trees = <_Drifter>[];
  final _tufts = <_Drifter>[];

  double _scroll = 0;

  /// The ground line: where Quacky's feet and every hazard sit.
  double get groundY => size.y * (1 - groundFraction);

  @override
  void onMount() {
    super.onMount();
    _fit(game.size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _fit(size);
  }

  void _fit(Vector2 newSize) {
    if (newSize.x <= 0 || newSize.y <= 0) return;
    size = newSize;
    _build();
  }

  void _build() {
    _clouds
      ..clear()
      ..addAll(
        List.generate(
          5,
          (i) => _Drifter(
            x: _random.nextDouble() * size.x * 1.4,
            y: size.y * (0.08 + _random.nextDouble() * 0.26),
            scale: 0.5 + _random.nextDouble() * 0.7,
            parallax: 0.12,
          ),
        ),
      );
    _trees
      ..clear()
      ..addAll(
        List.generate(
          5,
          (i) => _Drifter(
            x: i * size.x * 0.45 + _random.nextDouble() * 60,
            // Bases just below the ground line, so the trees read as being
            // behind the path rather than standing on it.
            y: groundY + 6,
            scale: 0.7 + _random.nextDouble() * 0.5,
            parallax: 0.35,
          ),
        ),
      );
    _tufts
      ..clear()
      ..addAll(
        List.generate(
          16,
          (i) => _Drifter(
            x: _random.nextDouble() * size.x * 1.2,
            y: groundY + size.y * groundFraction * _random.nextDouble() * 0.7,
            scale: 0.6 + _random.nextDouble() * 0.8,
            // Fastest layer, on the ground itself: this is the one that
            // actually communicates speed.
            parallax: 1.0,
          ),
        ),
      );
  }

  /// Advance the park. [distance] is how far it scrolled this frame — zero
  /// while Quacky is sitting down, which is how "stop and look" works.
  void advance(double distance) => _scroll += distance;

  /// Start a cross-fade to the next part of the park.
  void changeTo(ParkPlace next) {
    if (next == _place) return;
    _incoming = next;
    _fade = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final incoming = _incoming;
    if (incoming != null) {
      _fade += dt / _fadeSeconds;
      if (_fade >= 1) {
        _place = incoming;
        _incoming = null;
        _fade = 0;
      }
    }
  }

  Color _blend(Color Function(ParkPlace p) pick) {
    final incoming = _incoming;
    if (incoming == null) return pick(_place);
    return Color.lerp(pick(_place), pick(incoming), _fade.clamp(0.0, 1.0))!;
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    final rect = Offset.zero & size.toSize();

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_blend((p) => p.skyTop), _blend((p) => p.skyBottom)],
        ).createShader(rect),
    );

    // The sun, fixed: it does not scroll, because the sun does not go past.
    canvas.drawCircle(
      Offset(size.x * 0.82, size.y * 0.15),
      size.y * 0.07,
      Paint()..color = KidPalette.sun,
    );

    _renderLayer(canvas, _clouds, (c, d) {
      canvas.drawPath(
        KidShapes.cloud(Offset(d.x, d.y), 120 * d.scale),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    });

    _renderLayer(canvas, _trees, (c, d) {
      // A round park tree: a trunk and a big soft canopy. Nothing in a
      // five-year-old's park has a corner on it.
      final h = size.y * 0.24 * d.scale;
      final w = size.x * 0.16 * d.scale;
      canvas.drawRect(
        Rect.fromLTWH(d.x - w * 0.07, d.y - h * 0.55, w * 0.14, h * 0.55),
        Paint()..color = const Color(0xFF9B7A50),
      );
      canvas.drawCircle(
        Offset(d.x, d.y - h * 0.72),
        w * 0.52,
        Paint()..color = _blend((p) => p.groundFar),
      );
    });

    // The path and grass.
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.x, size.y - groundY),
      Paint()..color = _blend((p) => p.groundNear),
    );
    // A darker lip along the top, so the line Quacky walks on is unmistakable —
    // the child has to see what "on the path" means to make sense of a skid.
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.x, 5),
      Paint()..color = _blend((p) => p.groundFar),
    );

    _renderLayer(canvas, _tufts, (c, d) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(d.x, d.y + 4),
          width: 22 * d.scale,
          height: 9 * d.scale,
        ),
        Paint()..color = _blend((p) => p.groundFar),
      );
    });
  }

  /// Draws a layer, wrapping each piece around the screen so the park never
  /// runs out. Wrapping rather than spawning means it can scroll forever with
  /// no allocation and no end.
  void _renderLayer(
    Canvas canvas,
    List<_Drifter> layer,
    void Function(Canvas canvas, _Drifter d) paint,
  ) {
    final span = size.x + 240;
    for (final d in layer) {
      paint(
        canvas,
        _Drifter(
          x: ((d.x - _scroll * d.parallax) % span + span) % span - 120,
          y: d.y,
          scale: d.scale,
          parallax: d.parallax,
        ),
      );
    }
  }
}

/// One piece of scenery at one depth.
class _Drifter {
  _Drifter({
    required this.x,
    required this.y,
    required this.scale,
    required this.parallax,
  });

  final double x;
  final double y;
  final double scale;

  /// How much of the park's scroll this layer gets. 1 is the ground.
  final double parallax;
}
