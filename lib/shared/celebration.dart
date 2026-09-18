import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import 'kid_palette.dart';
import 'kid_shapes.dart';

/// Confetti. The whole reward loop of this app lives here.
///
/// With no score and no winning, this is the *only* thing that says "you did
/// it" — so it is deliberately generous. But it must not be startling
/// (CLAUDE.md §3): pieces fall at a calm speed, fade out rather than vanishing,
/// and the burst is spread over time rather than flashing all at once.
///
/// Overlays play rather than interrupting it, so the child never waits.
///
/// Two flavours:
///  * [burst] — the big one, a screenful, after a set of successes;
///  * [puff] — a small local shower at one spot, for a single lucky moment.
class Celebration extends Component {
  Celebration({this.pieceCount = 56});

  /// Enough to feel like a party, few enough to stay readable on a small
  /// screen. Not tuned to a frame rate — these are big soft shapes, not a
  /// particle storm.
  final int pieceCount;

  /// The share of a [burst] that floats UP instead of falling. Confetti alone
  /// all moves one way, which reads as weather; a few pieces rising reads as
  /// something bubbling over.
  static const _risingShare = 0.25;

  final _random = Random();

  /// Drops confetti across the given area (normally the whole screen).
  void burst(Vector2 area) {
    final rising = (pieceCount * _risingShare).round();
    for (var i = 0; i < pieceCount; i++) {
      final isRising = i < rising;
      add(_ConfettiPiece(
        random: _random,
        shape: _ConfettiShape
            .values[_random.nextInt(_ConfettiShape.values.length)],
        // Rising pieces start just off the bottom, falling ones just off the
        // top — so nothing ever appears out of thin air mid-screen.
        position: Vector2(
          _random.nextDouble() * area.x,
          isRising ? area.y + 20 : -20,
        ),
        travel: isRising ? -(area.y + 60) : area.y + 60,
      ));
    }
  }

  /// A small shower at one point — used for the rare sparkly balloon, where the
  /// reward should be felt exactly where the child was looking.
  ///
  /// Much smaller than [burst]: a full celebration for a single balloon would
  /// make the every-ten-pops celebration mean less.
  void puff(Vector2 at, {int pieces = 10}) {
    for (var i = 0; i < pieces; i++) {
      add(_ConfettiPiece(
        random: _random,
        shape: _ConfettiShape.star,
        position: at.clone(),
        travel: 90 + _random.nextDouble() * 70,
        spread: 150,
        duration: 0.9,
      ));
    }
  }
}

enum _ConfettiShape { rectangle, circle, star }

class _ConfettiPiece extends PositionComponent with HasPaint {
  _ConfettiPiece({
    required Random random,
    required this.shape,
    required super.position,
    required this.travel,
    this.spread = 80,
    this.duration,
  })  : _random = random,
        _color =
            KidPalette.playColors[random.nextInt(KidPalette.playColors.length)],
        super(size: Vector2(15, 19), anchor: Anchor.center);

  final Random _random;
  final _ConfettiShape shape;
  final Color _color;

  /// Vertical distance travelled; negative floats up.
  final double travel;

  /// How far a piece can wander sideways on the way.
  final double spread;

  /// Overridden for [Celebration.puff], which is quicker than a full burst.
  final double? duration;

  @override
  Future<void> onLoad() async {
    paint.color = _color;

    // Vary the fall so the pieces don't move as one block — 1.6-2.8s reads as
    // "drifting down", not "dropped".
    final seconds = duration ?? (1.6 + _random.nextDouble() * 1.2);
    // A small stagger, so the burst arrives as a shower rather than a flash.
    final delay = duration == null ? _random.nextDouble() * 0.5 : 0.0;

    add(MoveByEffect(
      Vector2(_random.nextDouble() * spread - spread / 2, travel),
      EffectController(duration: seconds, startDelay: delay),
    ));

    // Lazy tumble. Slow on purpose: fast spinning reads as frantic.
    add(RotateEffect.by(
      _random.nextDouble() * 4 - 2,
      EffectController(duration: seconds, startDelay: delay),
    ));

    // Fade out at the end instead of blinking out of existence, then remove
    // itself so pieces never accumulate.
    final fade = min(0.5, seconds * 0.5);
    add(OpacityEffect.fadeOut(
      EffectController(
        duration: fade,
        startDelay: delay + seconds - fade,
      ),
      onComplete: removeFromParent,
    ));
  }

  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & size.toSize();
    switch (shape) {
      case _ConfettiShape.rectangle:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          paint,
        );
      case _ConfettiShape.circle:
        canvas.drawCircle(rect.center, size.x / 2, paint);
      case _ConfettiShape.star:
        canvas.drawPath(KidShapes.star(rect.center, size.x / 2), paint);
    }
  }
}
