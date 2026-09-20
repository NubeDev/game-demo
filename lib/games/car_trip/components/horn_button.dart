import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';

/// The horn.
///
/// The only button in the app that does nothing to the game. It beeps, the cows
/// wave, and that is the entire feature — a five-year-old will press it far
/// more than they steer, and that is a perfectly good way to play (the scope's
/// open question about whether the horn steals the road is deliberately still
/// open; this is the version that finds out).
///
/// Rules it keeps (CLAUDE.md §3):
///  * [size] is 140 — far past the 80×80 minimum, because it is pressed with a
///    thumb while the other hand is steering.
///  * A picture, no text.
///  * Bottom-LEFT, opposite the home button in the top right, and sitting on
///    top of the steering area so a press on it never also swerves the car.
class HornButton extends StatefulWidget {
  const HornButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const double size = 140;

  @override
  State<HornButton> createState() => _HornButtonState();
}

class _HornButtonState extends State<HornButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Horn',
      button: true,
      child: GestureDetector(
        // On tap-DOWN, not tap-up: a five-year-old's finger slides between the
        // two, and a honk that did not happen reads as the game being broken.
        onTapDown: (_) {
          setState(() => _pressed = true);
          widget.onPressed();
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            width: HornButton.size,
            height: HornButton.size,
            decoration: BoxDecoration(
              color: KidPalette.playColors[2],
              shape: BoxShape.circle,
              border: Border.all(color: KidPalette.ink, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              // A horn, not a speaker: the child has to read it as "make a
              // noise at the cow", not as a volume control.
              Icons.campaign_rounded,
              size: HornButton.size * 0.54,
              color: KidPalette.ink,
            ),
          ),
        ),
      ),
    );
  }
}
