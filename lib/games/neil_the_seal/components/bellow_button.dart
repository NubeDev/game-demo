import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import 'neil_painter.dart';

/// The bellow.
///
/// Like Car Trip's horn, it does nothing to the game — and unlike Car Trip's
/// horn, what it does instead is start a round: Neil lets out a low comedy
/// bellow and the town answers one voice at a time, in an order it has never
/// been in before. That difference is deliberate; two games with the same
/// useless-button gag start to look like one game (the scope's *Kid-rules
/// impact*).
///
/// Rules it keeps (CLAUDE.md §3):
///  * [size] is 140 — far past the 80×80 minimum.
///  * **It wears Neil's face, not an icon.** The player cannot read, so the
///    only way to say "this button makes the seal noise" is to show them the
///    seal. A speaker icon would read as a volume control, which is the one
///    thing it must not be mistaken for.
///  * **Bottom-right**, the opposite corner from Car Trip's horn and diagonally
///    as far as possible from the home button. There is no steering thumb to
///    keep clear of here, so it goes where a hand resting on a tablet already
///    is.
class BellowButton extends StatefulWidget {
  const BellowButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const double size = 140;

  @override
  State<BellowButton> createState() => _BellowButtonState();
}

class _BellowButtonState extends State<BellowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Bellow',
      button: true,
      child: GestureDetector(
        // On tap-DOWN, not tap-up: a five-year-old's finger slides between the
        // two, and a bellow that did not happen reads as the game being broken.
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
            width: BellowButton.size,
            height: BellowButton.size,
            decoration: BoxDecoration(
              color: KidPalette.playColors[4],
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
            child: CustomPaint(
              painter: _SealFace(open: _pressed),
              size: const Size.square(BellowButton.size),
            ),
          ),
        ),
      ),
    );
  }
}

/// Neil's face on the button, mid-bellow while it is held down.
class _SealFace extends CustomPainter {
  const _SealFace({required this.open});

  final bool open;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.27;
    // Shifted left and up, because the snout and whiskers stick out to the
    // right and down — this centres the whole head in the button rather than
    // the skull, which otherwise leaves his face crowded into one corner.
    final centre = Offset(size.width * 0.36, size.height * 0.46);
    NeilPainter.paintHead(canvas, centre, r, open: open ? 1 : 0, happy: true);
  }

  @override
  bool shouldRepaint(_SealFace old) => old.open != open;
}
