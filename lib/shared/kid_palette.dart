import 'package:flutter/material.dart';

/// The colour vocabulary for everything a child sees.
///
/// Bright and saturated enough to be exciting, but nothing harsh: no pure
/// black, no fully saturated red (which reads as "wrong" / "stop" even to a
/// child who cannot read), and backgrounds stay pale so the play objects are
/// always the loudest thing on screen.
class KidPalette {
  const KidPalette._();

  /// Sky behind the games and the menu. Deliberately low-contrast so balloons,
  /// buttons and characters pop against it.
  static const skyTop = Color(0xFFBDE8FF);
  static const skyBottom = Color(0xFFEAF8FF);

  /// Menu background.
  static const menuBackground = Color(0xFFFFF6E0);

  /// The balloon / button colours. Six is enough variety to feel playful
  /// without any two being confusable at a glance.
  static const playColors = <Color>[
    Color(0xFFFF6B8A), // pink
    Color(0xFFFFB03A), // orange
    Color(0xFFFFE156), // yellow
    Color(0xFF6FD97F), // green
    Color(0xFF4FC3F7), // blue
    Color(0xFFB07BE8), // purple
  ];

  /// Used for the progress dots and celebration stars.
  static const star = Color(0xFFFFD23F);
  /// Unfilled dots. Needs to read clearly against the pale sky, so this is a
  /// soft ink wash rather than translucent white.
  static const starEmpty = Color(0x334A3B33);

  /// Soft ink for outlines. Not black — a warm dark brown is friendlier and
  /// still passes contrast against the pale backgrounds.
  static const ink = Color(0xFF4A3B33);

  /// The adult corner: muted on purpose so it does not invite a child's eye.
  static const parentGrey = Color(0xFF9E9E9E);
}
