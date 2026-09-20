import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';

/// A big round picture button — GO, stop, again, and the length choices.
///
/// Sized well past the 80x80 floor (CLAUDE.md §3) and round, because a circle
/// has no corner a child can be "just outside". Nothing here carries text.
class BigButton extends StatefulWidget {
  const BigButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 120,
    this.selected = false,
    this.semanticLabel,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  /// Shown ringed, for the length currently chosen. A picture of the choice,
  /// never a tick or the word "on".
  final bool selected;

  /// For tests and screen readers only — never rendered.
  final String? semanticLabel;

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTap: () {
          setState(() => _down = false);
          widget.onTap();
        },
        // A fixed box around the whole button. Without it the button takes
        // its width from its parent's constraints, and in an unbounded slot —
        // a Center inside a Positioned, which is how the "again" button sits
        // — it collapsed to zero width while keeping its height, landing
        // off-screen and unhittable. A touch target has to be the size it
        // says it is, whatever it is put inside (CLAUDE.md §3).
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedScale(
            // A press the finger can see under itself, since the finger covers
            // most of the button at this age.
            scale: _down ? 0.92 : 1,
            duration: const Duration(milliseconds: 90),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.selected ? KidPalette.ink : Colors.white,
                  width: widget.selected ? 7 : 5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                size: widget.size * 0.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
