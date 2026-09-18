import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../../../shared/kid_shapes.dart';

/// The world the balloons float through.
///
/// A flat gradient is not a place. Clouds that drift, a sun that breathes and
/// hills along the bottom give the balloons somewhere to rise *from* and *to*,
/// which is what makes a balloon reaching the top read as "it floated away"
/// rather than "it vanished off the edge" — and that reading is what keeps a
/// missed balloon from feeling like a loss (CLAUDE.md §3).
///
/// Everything here is calm and slow: clouds cross the screen in about a minute,
/// the sun's halo takes eight seconds to swell, nothing crosses the play area
/// fast enough to pull the eye off a balloon.
///
/// It is deliberately NOT interactive and sits at a low priority, so a tap
/// always reaches a balloon or the game's empty-sky handler, never the scenery.
class Sky extends PositionComponent with HasGameReference<FlameGame> {
  Sky({Random? random})
      : _random = random ?? Random(),
        super(priority: -100);

  final Random _random;
  final _clouds = <_Cloud>[];

  /// How far up the screen the hills reach.
  static const _hillHeight = 0.16;

  double _time = 0;

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
    _buildClouds();
  }

  void _buildClouds() {
    _clouds.clear();
    // Two depths. The far layer is smaller, paler and slower, which is the
    // whole parallax trick — it makes the sky feel deep on one flat canvas.
    for (var i = 0; i < 4; i++) {
      _clouds.add(_Cloud(
        x: _random.nextDouble() * size.x,
        y: size.y * (0.08 + _random.nextDouble() * 0.22),
        width: size.x * (0.10 + _random.nextDouble() * 0.05),
        speed: 5 + _random.nextDouble() * 4,
        opacity: 0.45,
      ));
    }
    for (var i = 0; i < 3; i++) {
      _clouds.add(_Cloud(
        x: _random.nextDouble() * size.x,
        y: size.y * (0.16 + _random.nextDouble() * 0.30),
        width: size.x * (0.17 + _random.nextDouble() * 0.08),
        speed: 11 + _random.nextDouble() * 7,
        opacity: 0.8,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    for (final cloud in _clouds) {
      cloud.x -= cloud.speed * dt;
      // Wrap around rather than respawning, so the sky never runs out and no
      // cloud ever pops into existence in view.
      if (cloud.x < -cloud.width) cloud.x = size.x + cloud.width;
    }
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    _renderGradient(canvas);
    _renderSun(canvas);
    for (final cloud in _clouds) {
      canvas.drawPath(
        KidShapes.cloud(Offset(cloud.x, cloud.y), cloud.width),
        Paint()..color = Colors.white.withValues(alpha: cloud.opacity),
      );
    }
    _renderHills(canvas);
  }

  void _renderGradient(Canvas canvas) {
    final rect = Offset.zero & size.toSize();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [KidPalette.skyTop, KidPalette.skyBottom],
        ).createShader(rect),
    );
  }

  void _renderSun(Canvas canvas) {
    // Left of centre and high up: clear of the home button (top-right) and of
    // the progress stars (top-left).
    final centre = Offset(size.x * 0.46, size.y * 0.13);
    final r = size.y * 0.075;
    // A slow breath, not a pulse. 8 seconds per cycle and only a few percent
    // of scale — noticeable only if you look for it.
    final breath = 1 + 0.04 * sin(_time * (2 * pi / 8));

    canvas.drawCircle(
      centre,
      r * 2.1 * breath,
      Paint()..color = KidPalette.star.withValues(alpha: 0.13),
    );
    canvas.drawCircle(
      centre,
      r * 1.45 * breath,
      Paint()..color = KidPalette.star.withValues(alpha: 0.2),
    );
    canvas.drawCircle(centre, r, Paint()..color = KidPalette.sun);
  }

  void _renderHills(Canvas canvas) {
    final base = size.y;
    final h = size.y * _hillHeight;

    // Back hill, then front hill, both wide low arcs. Rounded, never a peak:
    // the horizon should read as friendly ground, not mountains.
    final back = Path()
      ..moveTo(-10, base)
      ..quadraticBezierTo(size.x * 0.28, base - h * 1.5, size.x * 0.62, base)
      ..lineTo(-10, base)
      ..close();
    canvas.drawPath(back, Paint()..color = KidPalette.hillFar);

    final front = Path()
      ..moveTo(size.x * 0.25, base)
      ..quadraticBezierTo(size.x * 0.7, base - h * 1.25, size.x + 10, base)
      ..lineTo(size.x * 0.25, base)
      ..close();
    canvas.drawPath(front, Paint()..color = KidPalette.hillNear);

    // A flat strip of ground underneath, so no gap shows on a tall screen.
    canvas.drawRect(
      Rect.fromLTRB(0, base - h * 0.18, size.x, base),
      Paint()..color = KidPalette.hillNear,
    );
  }
}

class _Cloud {
  _Cloud({
    required this.x,
    required this.y,
    required this.width,
    required this.speed,
    required this.opacity,
  });

  double x;
  final double y;
  final double width;
  final double speed;
  final double opacity;
}
