import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../../../shared/kid_shapes.dart';
import '../obstacles.dart';

/// The world the cat runs through: sky, clouds, far hills, ground.
///
/// Everything here is **scenery only** — nothing in this component is ever
/// collided with, and nothing here can be missed. It exists to make the cat
/// read as running *somewhere* rather than on a treadmill, which is what makes
/// the world changing at a celebration feel like a reward.
///
/// ## Parallax, cheaply
///
/// Three layers at different speeds (clouds slowest, hills, then ground
/// fastest). That is the whole depth trick, and it is worth it here: with a
/// single flat layer, a child cannot tell the cat is moving at all.
///
/// ## Scene changes are a cross-fade, never a cut
///
/// A hard cut to a new place is exactly the kind of startling change
/// CLAUDE.md §3 rules out — and at five it reads as the game having broken.
/// [changeTo] fades over [_fadeSeconds] while the run carries on underneath.
class Scenery extends PositionComponent with HasGameReference<FlameGame> {
  Scenery({Random? random, this.groundFraction = 0.3})
    : _random = random ?? Random(),
      super(priority: -100);

  /// How much of the screen height is ground. The rest is sky.
  final double groundFraction;

  final Random _random;

  /// The scene being shown, and the one being faded in.
  Scene _scene = Scene.garden;
  Scene? _incoming;
  double _fade = 0;

  static const _fadeSeconds = 1.4;

  Scene get scene => _scene;

  final _clouds = <_Drifter>[];
  final _hills = <_Drifter>[];
  final _tufts = <_Drifter>[];

  /// How far the world has scrolled, in logical pixels. Driven by the game, so
  /// the scenery stops when the cat sits down.
  double _scroll = 0;

  /// The ground line: where the cat's feet and every obstacle sit.
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
        _spread(
          5,
          (i) => _Drifter(
            x: _random.nextDouble() * size.x * 1.4,
            y: size.y * (0.08 + _random.nextDouble() * 0.28),
            scale: 0.5 + _random.nextDouble() * 0.7,
            // Slowest layer: barely moves, so it reads as far away.
            parallax: 0.12,
          ),
        ),
      );
    _hills
      ..clear()
      ..addAll(
        _spread(
          4,
          (i) => _Drifter(
            x: i * size.x * 0.55 + _random.nextDouble() * 60,
            // Their bases sit slightly BELOW the ground line, so the hills read
            // as being behind the ground rather than standing on it. With the
            // two lines identical the cat appeared to be running along the
            // distant horizon instead of on the ground in front of it.
            y: groundY + 6,
            scale: 0.7 + _random.nextDouble() * 0.6,
            parallax: 0.35,
          ),
        ),
      );
    _tufts
      ..clear()
      ..addAll(
        _spread(
          14,
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

  List<_Drifter> _spread(int count, _Drifter Function(int i) make) =>
      List.generate(count, make);

  /// Advance the world. [distance] is how far it scrolled this frame — zero
  /// while the cat is sitting, which is how "stop and look at things" works.
  void advance(double distance) => _scroll += distance;

  /// Start a cross-fade to the next place.
  void changeTo(Scene next) {
    if (next == _scene) return;
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
        _scene = incoming;
        _incoming = null;
        _fade = 0;
      }
    }
  }

  /// The colour to draw, part way through a cross-fade.
  Color _blend(Color Function(Scene s) pick) {
    final incoming = _incoming;
    if (incoming == null) return pick(_scene);
    return Color.lerp(pick(_scene), pick(incoming), _fade.clamp(0.0, 1.0))!;
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    final rect = Offset.zero & size.toSize();

    // Sky.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_blend((s) => s.skyTop), _blend((s) => s.skyBottom)],
        ).createShader(rect),
    );

    // The sun, fixed: it does not scroll, because the sun does not go past.
    canvas.drawCircle(
      Offset(size.x * 0.82, size.y * 0.16),
      size.y * 0.075,
      Paint()..color = KidPalette.sun,
    );

    _renderLayer(canvas, _clouds, (c, d) {
      canvas.drawPath(
        KidShapes.cloud(Offset(d.x, d.y), 120 * d.scale),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    });

    _renderLayer(canvas, _hills, (c, d) {
      final w = size.x * 0.5 * d.scale;
      final h = size.y * 0.2 * d.scale;
      canvas.drawPath(
        Path()
          ..moveTo(d.x - w / 2, d.y)
          ..quadraticBezierTo(d.x, d.y - h * 2, d.x + w / 2, d.y)
          ..close(),
        Paint()..color = _blend((s) => s.groundFar),
      );
    });

    // Ground.
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.x, size.y - groundY),
      Paint()..color = _blend((s) => s.groundNear),
    );
    // A darker lip along the top of the ground, so the line the cat runs on is
    // unmistakable — the child has to be able to see what "on the ground"
    // means to make sense of a jump.
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.x, 5),
      Paint()..color = _blend((s) => s.groundFar),
    );

    _renderLayer(canvas, _tufts, (c, d) {
      // A tuft of grass, a pebble on the beach, a snow lump — the same shape
      // in the scene's own colour, which is enough at placeholder stage.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(d.x, d.y + 4),
          width: 22 * d.scale,
          height: 9 * d.scale,
        ),
        Paint()..color = _blend((s) => s.groundFar),
      );
    });
  }

  /// Draws a layer, wrapping each piece around the screen so the world never
  /// runs out. Wrapping (rather than spawning) means a scene can scroll
  /// forever with no allocation and no end.
  void _renderLayer(
    Canvas canvas,
    List<_Drifter> layer,
    void Function(Canvas canvas, _Drifter d) paint,
  ) {
    final span = size.x + 240;
    for (final d in layer) {
      final shifted = _Drifter(
        x: ((d.x - _scroll * d.parallax) % span + span) % span - 120,
        y: d.y,
        scale: d.scale,
        parallax: d.parallax,
      );
      paint(canvas, shifted);
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

  /// How much of the world's scroll this layer gets. 1 is the ground.
  final double parallax;
}
