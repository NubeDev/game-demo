import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import 'kid_palette.dart';

/// Confetti. The whole reward loop of this app lives here.
///
/// With no score and no winning, this is the *only* thing that says "you did
/// it" — so it is deliberately generous. But it must not be startling
/// (CLAUDE.md §3): pieces fall at a calm speed, fade out rather than vanishing,
/// and the burst is spread over time rather than flashing all at once.
///
/// Overlays play rather than interrupting it, so the child never waits.
class Celebration extends Component {
  Celebration({this.pieceCount = 40});

  /// Enough to feel like a party, few enough to stay readable on a small
  /// screen. Not tuned to a frame rate — these are big soft shapes, not a
  /// particle storm.
  final int pieceCount;

  final _random = Random();

  /// Drops confetti across the given area (normally the whole screen).
  void burst(Vector2 area) {
    for (var i = 0; i < pieceCount; i++) {
      add(_ConfettiPiece(
        random: _random,
        // Start just above the top edge, spread across the full width.
        position: Vector2(_random.nextDouble() * area.x, -20),
        fallDistance: area.y + 60,
      ));
    }
  }
}

class _ConfettiPiece extends RectangleComponent {
  _ConfettiPiece({
    required Random random,
    required super.position,
    required this.fallDistance,
  })  : _random = random,
        super(
          size: Vector2(14, 18),
          anchor: Anchor.center,
          paint: Paint()
            ..color = KidPalette
                .playColors[random.nextInt(KidPalette.playColors.length)],
        );

  final Random _random;
  final double fallDistance;

  @override
  Future<void> onLoad() async {
    // Vary the fall so the pieces don't move as one block — 1.6-2.8s reads as
    // "drifting down", not "dropped".
    final duration = 1.6 + _random.nextDouble() * 1.2;
    // A small stagger, so the burst arrives as a shower rather than a flash.
    final delay = _random.nextDouble() * 0.5;

    add(MoveByEffect(
      Vector2(_random.nextDouble() * 80 - 40, fallDistance),
      EffectController(duration: duration, startDelay: delay),
    ));

    // Lazy tumble. Slow on purpose: fast spinning reads as frantic.
    add(RotateEffect.by(
      _random.nextDouble() * 4 - 2,
      EffectController(duration: duration, startDelay: delay),
    ));

    // Fade out at the end instead of blinking out of existence, then remove
    // itself so pieces never accumulate.
    add(OpacityEffect.fadeOut(
      EffectController(
        duration: 0.5,
        startDelay: delay + duration - 0.5,
      ),
      onComplete: removeFromParent,
    ));
  }
}
