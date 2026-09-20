import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_shapes.dart';
import '../road.dart';

/// The world the car drives through: sky, fields, tarmac, verges, and the
/// dashes down the middle.
///
/// Everything here is **scenery only** — nothing in this component is ever
/// collided with and nothing here can be missed. It exists so the car reads as
/// going *somewhere*, which is what makes arriving feel like arriving.
///
/// ## The dashes are doing the most work
///
/// A flat grey trapezoid tells a child nothing about whether they are moving.
/// The centre dashes and the kerb stripes sliding toward the car are the whole
/// sensation of speed, and they are also the only thing on screen that shows
/// the road *stopping* when the child lifts their thumb.
///
/// ## Arriving is a cross-fade, never a cut
///
/// A hard change of place is exactly the startling change CLAUDE.md §3 rules
/// out, and at five it reads as the game having broken. [changeTo] fades over
/// [_fadeSeconds] while the driving carries on underneath.
class RoadView extends PositionComponent with HasGameReference<FlameGame> {
  RoadView({Random? random}) : _random = random ?? Random(), super(priority: -100);

  final Random _random;

  Destination _place = Destination.farm;
  Destination? _incoming;
  double _fade = 0;

  static const _fadeSeconds = 1.6;

  Destination get place => _place;

  /// How far the trip has come, in world pixels. Driven by the game, so the
  /// road stops when the child lifts their thumb.
  double _scrolled = 0;

  /// Hills and clouds on the horizon. They barely move: they are a long way
  /// away, and something that slid past quickly up there would fight the road
  /// for the child's attention.
  final _hills = <_Distant>[];
  final _clouds = <_Distant>[];

  Perspective get view => Perspective(width: size.x, height: size.y);

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
    _hills
      ..clear()
      ..addAll(
        List.generate(
          6,
          (i) => _Distant(
            x: i * size.x * 0.34 + _random.nextDouble() * 60,
            scale: 0.6 + _random.nextDouble() * 0.7,
            drift: 0.03,
          ),
        ),
      );
    _clouds
      ..clear()
      ..addAll(
        List.generate(
          5,
          (i) => _Distant(
            x: _random.nextDouble() * size.x * 1.3,
            y: size.y * (0.05 + _random.nextDouble() * 0.2),
            scale: 0.5 + _random.nextDouble() * 0.7,
            drift: 0.015,
          ),
        ),
      );
  }

  /// Advance the world. [distance] is how far it moved this frame — zero while
  /// the car is stopped at the kerb, which is how "stop and look at the cows"
  /// works.
  void advance(double distance) => _scrolled += distance;

  double get scrolled => _scrolled;

  /// Start a cross-fade to the next place.
  void changeTo(Destination next) {
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

  /// The colour to draw part way through a cross-fade.
  Color _blend(Color Function(Destination d) pick) {
    final incoming = _incoming;
    if (incoming == null) return pick(_place);
    return Color.lerp(pick(_place), pick(incoming), _fade.clamp(0.0, 1.0))!;
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    final v = view;

    _renderSky(canvas, v);
    _renderGround(canvas, v);
    _renderRoad(canvas, v);
    _renderMarkings(canvas, v);
  }

  void _renderSky(Canvas canvas, Perspective v) {
    final sky = Rect.fromLTWH(0, 0, size.x, v.horizonY + 1);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_blend((d) => d.skyTop), _blend((d) => d.skyBottom)],
        ).createShader(sky),
    );

    for (final cloud in _clouds) {
      final x = _wrapped(cloud.x - _scrolled * cloud.drift, size.x + 260) - 130;
      canvas.drawPath(
        KidShapes.cloud(Offset(x, cloud.y), 120 * cloud.scale),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }

    // Hills sitting ON the horizon line, so the road appears to come out from
    // behind them rather than from the sky.
    for (final hill in _hills) {
      final x = _wrapped(hill.x - _scrolled * hill.drift, size.x + 300) - 150;
      final w = size.x * 0.34 * hill.scale;
      final h = size.y * 0.1 * hill.scale;
      canvas.drawPath(
        Path()
          ..moveTo(x - w / 2, v.horizonY)
          ..quadraticBezierTo(x, v.horizonY - h * 2, x + w / 2, v.horizonY)
          ..close(),
        Paint()..color = _blend((d) => d.fieldFar),
      );
    }
  }

  void _renderGround(Canvas canvas, Perspective v) {
    canvas.drawRect(
      Rect.fromLTWH(0, v.horizonY, size.x, size.y - v.horizonY),
      Paint()..color = _blend((d) => d.field),
    );
    // A paler band just under the horizon: the fields far away catch more
    // light, and without it the ground is one flat slab of colour.
    canvas.drawRect(
      Rect.fromLTWH(0, v.horizonY, size.x, (size.y - v.horizonY) * 0.18),
      Paint()..color = _blend((d) => d.fieldFar),
    );
  }

  void _renderRoad(Canvas canvas, Perspective v) {
    // The tarmac and the two grass verges, as trapezoids from just under the
    // car out to the horizon. The verge is drawn as road, not as scenery,
    // because it IS drivable — see `driveableLateral`.
    const near = -120.0;
    const far = Perspective.viewDepth;

    _quad(canvas, v, -driveableLateral, driveableLateral, near, far,
        Paint()..color = _blend((d) => d.verge));
    _quad(canvas, v, -tarmacLateral, tarmacLateral, near, far,
        Paint()..color = _blend((d) => d.tarmac));
  }

  void _renderMarkings(Canvas canvas, Perspective v) {
    // Dashes are placed at fixed world distances and the world slides past
    // them, which is what makes them read as the road moving rather than as an
    // animation playing.
    const spacing = 150.0;
    const dashLength = 70.0;

    final first = (_scrolled / spacing).floorToDouble() * spacing;
    final white = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final kerb = Paint()..color = Colors.white.withValues(alpha: 0.6);

    for (var i = 0; i < 12; i++) {
      final worldAt = first + i * spacing;
      final depth = worldAt - _scrolled;
      if (depth > Perspective.viewDepth) break;
      final dFar = depth + dashLength;

      // Centre line.
      _quad(canvas, v, -0.045, 0.045, depth, dFar, white);
      // Kerb stripes, just inside the tarmac edge, offset half a dash so the
      // eye always has something moving somewhere.
      final kerbNear = depth + spacing / 2;
      _quad(canvas, v, -1.0, -0.93, kerbNear, kerbNear + dashLength, kerb);
      _quad(canvas, v, 0.93, 1.0, kerbNear, kerbNear + dashLength, kerb);
    }
  }

  /// One shape on the road surface, between two depths and two lateral edges.
  void _quad(
    Canvas canvas,
    Perspective v,
    double left,
    double right,
    double near,
    double far,
    Paint paint,
  ) {
    final yNear = v.yAt(near);
    final yFar = v.yAt(far);
    canvas.drawPath(
      Path()
        ..moveTo(v.xAt(left, near), yNear)
        ..lineTo(v.xAt(right, near), yNear)
        ..lineTo(v.xAt(right, far), yFar)
        ..lineTo(v.xAt(left, far), yFar)
        ..close(),
      paint,
    );
  }

  double _wrapped(double x, double span) => ((x % span) + span) % span;
}

/// Something a long way off: hills and clouds.
class _Distant {
  _Distant({
    required this.x,
    required this.scale,
    required this.drift,
    this.y = 0,
  });

  final double x;
  final double y;
  final double scale;

  /// How much of the trip's distance this gets. Tiny — it is far away.
  final double drift;
}
