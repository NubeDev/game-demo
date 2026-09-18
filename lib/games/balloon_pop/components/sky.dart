import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
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
/// **The sun and the clouds answer a tap.** A five-year-old taps everything on
/// screen, and at this age a thing that does nothing when touched is not
/// scenery — it is broken. The sun spins out a burst of rays; a cloud squashes
/// and puffs. Neither fills a star, so balloons stay the point, but it means a
/// tap that missed a balloon can still be *something the child did* rather than
/// a near-miss.
///
/// [containsLocalPoint] is overridden so this only claims taps that actually
/// land on the sun or a cloud. Everything else falls straight through to the
/// game's own handler, and balloons — at a higher priority — always win.
class Sky extends PositionComponent
    with HasGameReference<FlameGame>, TapCallbacks {
  Sky({Random? random, this.onSunTapped, this.onCloudTapped})
      : _random = random ?? Random(),
        super(priority: -100);

  /// Called when the child taps the sun, so the game can answer with a sound.
  final void Function(Vector2 at)? onSunTapped;

  /// Called when the child taps a cloud, with the point to sparkle at.
  final void Function(Vector2 at)? onCloudTapped;

  final Random _random;
  final _clouds = <_Cloud>[];

  /// How far up the screen the hills reach.
  static const _hillHeight = 0.16;

  /// How long the sun's and a cloud's reactions last.
  static const _reactionTime = 0.8;

  double _time = 0;

  /// Seconds since the sun was last tapped, or null if it is idle.
  double? _sunPokedAt;

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

  /// Where the sun sits, and how big it is. Left of centre and high up: clear
  /// of the home button (top-right) and of the progress stars (top-left).
  Offset get _sunCentre => Offset(size.x * 0.46, size.y * 0.13);
  double get _sunRadius => size.y * 0.075;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    for (final cloud in _clouds) {
      cloud.x -= cloud.speed * dt;
      // Wrap around rather than respawning, so the sky never runs out and no
      // cloud ever pops into existence in view.
      if (cloud.x < -cloud.width) cloud.x = size.x + cloud.width;
      final poked = cloud.pokedAt;
      if (poked != null) {
        cloud.pokedAt = poked + dt < _reactionTime ? poked + dt : null;
      }
    }
    final sun = _sunPokedAt;
    if (sun != null) {
      _sunPokedAt = sun + dt < _reactionTime ? sun + dt : null;
    }
  }

  /// Only the sun and the clouds are tappable. Anything else in the sky is not
  /// claimed at all, so the tap reaches the game and gets the usual answer.
  @override
  bool containsLocalPoint(Vector2 point) =>
      _sunHit(point) || _cloudAt(point) != null;

  bool _sunHit(Vector2 point) {
    // A generous target: the visible disc plus its halo, comfortably past
    // 80x80 on any phone (CLAUDE.md §3).
    final reach = max(_sunRadius * 1.6, 48.0);
    return (Offset(point.x, point.y) - _sunCentre).distance <= reach;
  }

  _Cloud? _cloudAt(Vector2 point) {
    for (final cloud in _clouds) {
      // An ellipse around the cloud's lobes, padded so a small cloud is still
      // a big enough thing to hit.
      final dx = (point.x - cloud.x) / max(cloud.width * 0.5, 44.0);
      final dy = (point.y - cloud.y) / max(cloud.width * 0.26, 40.0);
      if (dx * dx + dy * dy <= 1) return cloud;
    }
    return null;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final point = event.localPosition;
    if (_sunHit(point)) {
      _sunPokedAt = 0;
      onSunTapped?.call(Vector2(_sunCentre.dx, _sunCentre.dy));
      return;
    }
    final cloud = _cloudAt(point);
    if (cloud != null) {
      cloud.pokedAt = 0;
      onCloudTapped?.call(Vector2(cloud.x, cloud.y));
    }
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    _renderGradient(canvas);
    _renderSun(canvas);
    for (final cloud in _clouds) {
      // A poked cloud squashes and springs back. Slow enough to read, small
      // enough that it never competes with a balloon for attention.
      final poked = cloud.pokedAt;
      final squash =
          poked == null ? 0.0 : sin((poked / _reactionTime) * pi) * 0.22;
      canvas.save();
      canvas.translate(cloud.x, cloud.y);
      canvas.scale(1 + squash, 1 - squash * 0.7);
      canvas.drawPath(
        KidShapes.cloud(Offset.zero, cloud.width),
        Paint()..color = Colors.white.withValues(alpha: cloud.opacity),
      );
      canvas.restore();
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
    final centre = _sunCentre;
    final r = _sunRadius;
    // A slow breath, not a pulse. 8 seconds per cycle and only a few percent
    // of scale — noticeable only if you look for it.
    final breath = 1 + 0.04 * sin(_time * (2 * pi / 8));
    final poked = _sunPokedAt;
    // A poked sun swells and turns out a set of rays, then settles back.
    final wake = poked == null ? 0.0 : sin((poked / _reactionTime) * pi);

    canvas.drawCircle(
      centre,
      r * (2.1 + wake * 0.5) * breath,
      Paint()..color = KidPalette.star.withValues(alpha: 0.13 + wake * 0.1),
    );
    canvas.drawCircle(
      centre,
      r * 1.45 * breath,
      Paint()..color = KidPalette.star.withValues(alpha: 0.2),
    );

    if (wake > 0) _renderSunRays(canvas, centre, r, poked!, wake);

    canvas.drawCircle(
      centre,
      r * (1 + wake * 0.12),
      Paint()..color = KidPalette.sun,
    );
  }

  void _renderSunRays(
    Canvas canvas,
    Offset centre,
    double r,
    double poked,
    double wake,
  ) {
    // Eight soft rays turning slowly outward. Rounded caps and a warm colour:
    // nothing spiky, nothing that strobes (CLAUDE.md §3).
    final spin = (poked / _reactionTime) * 0.6;
    final paint = Paint()
      ..color = KidPalette.star.withValues(alpha: wake * 0.75)
      ..strokeWidth = r * 0.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 8; i++) {
      final a = spin + i * pi / 4;
      final inner = r * (1.25 + wake * 0.25);
      final outer = inner + r * 0.55 * wake;
      canvas.drawLine(
        centre + Offset(cos(a) * inner, sin(a) * inner),
        centre + Offset(cos(a) * outer, sin(a) * outer),
        paint,
      );
    }
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

  /// Seconds since this cloud was tapped, or null if it is idle.
  double? pokedAt;
}
