import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../../../shared/kid_shapes.dart';
import '../lands.dart';

/// The land she flies through: sky, clouds, far hills, ground, and the friendly
/// things that notice her.
///
/// Everything here is **scenery only** — nothing in this component is ever
/// collided with, nothing here can be missed, and nothing here wants anything
/// from the child. The dragon opens one eye and puffs a smoke ring; the rabbits
/// wave; the sheep bounce. **None of it is in the way** (the scope), and in
/// particular nothing here ever wakes up angry, chases, or catches up —
/// anything catching up is pressure, which is the same shape as failure.
///
/// ## Four layers of parallax, because height has to read
///
/// Cat Run needs three; this one needs the sky to have depth too, or rising
/// does not feel like rising. Clouds drift slowest, then hills, then the ground
/// tufts. The unicorn's own height does the rest.
///
/// ## A land change is a cross-fade, never a cut
///
/// A hard cut is exactly the startling change CLAUDE.md §3 rules out, and at
/// five it reads as the game having broken. [changeTo] fades over
/// [_fadeSeconds] while the flight carries on underneath.
class Sky extends PositionComponent with HasGameReference<FlameGame> {
  Sky({Random? random, this.groundFraction = 0.2})
    : _random = random ?? Random(),
      super(priority: -100);

  /// How much of the screen height is ground. Less than Cat Run's 0.3: this
  /// game needs sky, because the sky is where half the crystals live.
  final double groundFraction;

  final Random _random;

  Land _land = Land.meadow;
  Land? _incoming;
  double _fade = 0;
  double _time = 0;

  static const _fadeSeconds = 1.6;

  Land get land => _land;

  final _clouds = <_Drifter>[];
  final _hills = <_Drifter>[];
  final _tufts = <_Drifter>[];
  final _sparks = <_Drifter>[];
  final _friends = <_Friend>[];

  double _scroll = 0;

  /// The ground line: where her hooves and every ground-standing prop sit.
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
      ..addAll(List.generate(
        6,
        (i) => _Drifter(
          x: _random.nextDouble() * size.x * 1.4,
          y: size.y * (0.05 + _random.nextDouble() * 0.34),
          scale: 0.5 + _random.nextDouble() * 0.8,
          parallax: 0.1,
        ),
      ));
    _hills
      ..clear()
      ..addAll(List.generate(
        4,
        (i) => _Drifter(
          x: i * size.x * 0.55 + _random.nextDouble() * 60,
          // Bases slightly below the ground line, so the hills read as being
          // behind the ground rather than standing on it.
          y: groundY + 6,
          scale: 0.7 + _random.nextDouble() * 0.6,
          parallax: 0.32,
        ),
      ));
    _tufts
      ..clear()
      ..addAll(List.generate(
        14,
        (i) => _Drifter(
          x: _random.nextDouble() * size.x * 1.2,
          y: groundY + size.y * groundFraction * _random.nextDouble() * 0.7,
          scale: 0.6 + _random.nextDouble() * 0.8,
          parallax: 1.0,
        ),
      ));
    // Floating lights for the cave and the night sky. They DRIFT — they never
    // blink, which is the photosensitivity rule in a place it would be easy to
    // break (CLAUDE.md §3).
    _sparks
      ..clear()
      ..addAll(List.generate(
        18,
        (i) => _Drifter(
          x: _random.nextDouble() * size.x * 1.3,
          y: size.y * (0.08 + _random.nextDouble() * 0.7),
          scale: 0.5 + _random.nextDouble() * 0.9,
          parallax: 0.55,
        ),
      ));
    _friends
      ..clear()
      ..addAll(List.generate(
        4,
        (i) => _Friend(
          kind: _FriendKind.values[i % _FriendKind.values.length],
          x: _random.nextDouble() * size.x * 2,
          scale: 0.8 + _random.nextDouble() * 0.4,
        ),
      ));
  }

  /// Advance the world. Zero while she is resting, which is how "the world
  /// waits" works.
  void advance(double distance) => _scroll += distance;

  /// Start a cross-fade to the next land.
  void changeTo(Land next) {
    if (next == _land) return;
    _incoming = next;
    _fade = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final incoming = _incoming;
    if (incoming != null) {
      _fade += dt / _fadeSeconds;
      if (_fade >= 1) {
        _land = incoming;
        _incoming = null;
        _fade = 0;
      }
    }
  }

  Color _blend(Color Function(Land l) pick) {
    final incoming = _incoming;
    if (incoming == null) return pick(_land);
    return Color.lerp(pick(_land), pick(incoming), _fade.clamp(0.0, 1.0))!;
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
          colors: [_blend((l) => l.skyTop), _blend((l) => l.skyBottom)],
        ).createShader(rect),
    );

    // The sun. Fixed — the sun does not go past.
    canvas.drawCircle(
      Offset(size.x * 0.84, size.y * 0.14),
      size.y * 0.07,
      Paint()..color = KidPalette.sun.withValues(alpha: _land.glow ? 0.35 : 1),
    );

    if (_land.glow || (_incoming?.glow ?? false)) _renderSparks(canvas);

    _renderLayer(canvas, _clouds, (c, d) {
      canvas.drawPath(
        KidShapes.cloud(Offset(d.x, d.y), 130 * d.scale),
        Paint()..color = Colors.white.withValues(alpha: _land.glow ? 0.3 : 0.85),
      );
    });

    _renderLayer(canvas, _hills, (c, d) {
      final w = size.x * 0.5 * d.scale;
      final h = size.y * 0.22 * d.scale;
      canvas.drawPath(
        Path()
          ..moveTo(d.x - w / 2, d.y)
          ..quadraticBezierTo(d.x, d.y - h * 2, d.x + w / 2, d.y)
          ..close(),
        Paint()..color = _blend((l) => l.groundFar),
      );
    });

    // Ground.
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.x, size.y - groundY),
      Paint()..color = _blend((l) => l.groundNear),
    );
    // A darker lip along the top, so the line she gallops on is unmistakable.
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.x, 5),
      Paint()..color = _blend((l) => l.groundFar),
    );

    // Shallow water where a land has it. It sits AT the ground line, never
    // below it: there is no drop anywhere in this game.
    final water = _land.water;
    if (water != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, groundY + 10, size.x, size.y - groundY - 10),
        Paint()..color = water.withValues(alpha: 0.75),
      );
    }

    _renderLayer(canvas, _tufts, (c, d) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(d.x, d.y + 4),
          width: 24 * d.scale,
          height: 10 * d.scale,
        ),
        Paint()..color = _blend((l) => l.groundFar),
      );
    });

    _renderFriends(canvas);
  }

  void _renderSparks(Canvas canvas) {
    final span = size.x + 240;
    for (var i = 0; i < _sparks.length; i++) {
      final d = _sparks[i];
      final x = ((d.x - _scroll * d.parallax) % span + span) % span - 120;
      // A slow drift up and down, well under the 2 Hz ceiling.
      final y = d.y + sin(_time * 0.7 + i) * 10;
      canvas.drawCircle(
        Offset(x, y),
        3.5 * d.scale,
        Paint()
          ..color = const Color(0xFFFFF3B0).withValues(alpha: 0.75)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  /// The creatures who notice her. Scenery with a personality, and nothing
  /// more: they are never in the way, they never want anything, and none of
  /// them can be interacted with, missed, or made angry.
  void _renderFriends(Canvas canvas) {
    final span = size.x * 2.2;
    for (final friend in _friends) {
      final x = ((friend.x - _scroll * 0.9) % span + span) % span - 120;
      if (x < -140 || x > size.x + 140) continue;
      // Each friend animates on its own slow clock.
      final beat = sin(_time * 1.6 + friend.x * 0.01);
      switch (friend.kind) {
        case _FriendKind.dragon:
          _dragon(canvas, x, friend.scale, beat);
        case _FriendKind.rabbits:
          _rabbits(canvas, x, friend.scale, beat);
        case _FriendKind.sheep:
          _sheep(canvas, x, friend.scale, beat);
        case _FriendKind.whale:
          _whale(canvas, x, friend.scale, beat);
      }
    }
  }

  void _dragon(Canvas canvas, double x, double scale, double beat) {
    final base = groundY;
    final s = 40.0 * scale;
    // Asleep on a rock, round and soft. Nothing about this shape is spiky.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, base - s * 0.55, s * 1.9, s * 0.55),
        Radius.circular(s * 0.27),
      ),
      Paint()..color = const Color(0xFF8FD79B),
    );
    canvas.drawCircle(
      Offset(x + s * 1.75, base - s * 0.72),
      s * 0.34,
      Paint()..color = const Color(0xFF8FD79B),
    );
    // One eye, opening slowly as she passes.
    final open = (beat * 0.5 + 0.5).clamp(0.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x + s * 1.84, base - s * 0.78),
        width: s * 0.12,
        height: s * 0.12 * open,
      ),
      Paint()..color = KidPalette.ink,
    );
    // A smoke ring, drifting up. Slow.
    final puff = (_time * 0.4 + x * 0.002) % 1;
    canvas.drawCircle(
      Offset(x + s * 2.1 + puff * 18, base - s * 0.95 - puff * 40),
      s * 0.13 * (0.5 + puff),
      Paint()
        ..color = Colors.white.withValues(alpha: (1 - puff) * 0.5)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  void _rabbits(Canvas canvas, double x, double scale, double beat) {
    final base = groundY;
    final s = 20.0 * scale;
    // A burrow.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x + s, base),
        width: s * 2.2,
        height: s * 0.8,
      ),
      Paint()..color = const Color(0xFF8A6A4B),
    );
    for (var i = 0; i < 2; i++) {
      final rx = x + s * (0.55 + i * 0.9);
      // Popping up and down out of the burrow.
      final up = (sin(_time * 1.2 + i * 2) * 0.5 + 0.5) * s * 0.8;
      canvas.drawCircle(
        Offset(rx, base - up),
        s * 0.32,
        Paint()..color = const Color(0xFFF6EDE2),
      );
      // Ears.
      for (var e = -1; e <= 1; e += 2) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(rx + e * s * 0.14, base - up - s * 0.42),
            width: s * 0.13,
            height: s * 0.4,
          ),
          Paint()..color = const Color(0xFFF6EDE2),
        );
      }
    }
  }

  void _sheep(Canvas canvas, double x, double scale, double beat) {
    final base = groundY;
    final s = 26.0 * scale;
    for (var i = 0; i < 2; i++) {
      // Bouncing, gently and out of phase.
      final hop = max(0.0, sin(_time * 2.2 + i * 1.7)) * s * 0.5;
      final sx = x + i * s * 1.6;
      canvas.drawCircle(
        Offset(sx, base - s * 0.4 - hop),
        s * 0.4,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(sx + s * 0.36, base - s * 0.52 - hop),
        s * 0.18,
        Paint()..color = const Color(0xFF4A3B33),
      );
    }
  }

  void _whale(Canvas canvas, double x, double scale, double beat) {
    // Only where there is sea. On land this friend simply does not appear —
    // it is never "missing", because nothing here is ever counted.
    if (_land.water == null) return;
    final base = groundY + size.y * groundFraction * 0.45;
    final s = 46.0 * scale;
    // Breaching: a slow rise and fall, mostly below the water line.
    final rise = max(0.0, sin(_time * 0.55 + x * 0.004)) * s * 0.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, base - rise),
        width: s * 2,
        height: s * 0.7,
      ),
      Paint()..color = const Color(0xFF5E86B8),
    );
    // The spout. Soft, never a jet.
    if (rise > s * 0.3) {
      canvas.drawCircle(
        Offset(x - s * 0.5, base - rise - s * 0.6),
        s * 0.15,
        Paint()..color = Colors.white.withValues(alpha: 0.6),
      );
    }
  }

  /// Draws a layer, wrapping each piece around the screen so the world never
  /// runs out and nothing has to be allocated as it scrolls.
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

  /// How much of the world's scroll this layer gets. 1 is the ground.
  final double parallax;
}

enum _FriendKind { dragon, rabbits, sheep, whale }

class _Friend {
  _Friend({required this.kind, required this.x, required this.scale});

  final _FriendKind kind;
  final double x;
  final double scale;
}
