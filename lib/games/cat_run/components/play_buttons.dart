import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';

/// Which of the two buttons this is.
enum PlayButtonKind {
  /// A paw. Jump. Bottom-right, under the right thumb.
  paw,

  /// A crouching cat. Duck. Bottom-left, under the left thumb.
  crouch,
}

/// One of the two big picture buttons — the entire control scheme.
///
/// Rules this encodes (CLAUDE.md §3, and the scope's *Touch targets*):
///  * **No text.** A paw and a crouching cat. The player cannot read.
///  * **[buttonSize] is 140**, well past the 80x80 floor — and the *hit area*
///    is bigger still: the parent wraps this in the whole bottom quarter of the
///    screen, so a mis-aimed thumb works anyway.
///  * **It answers instantly on press-down**, not on release. A button that
///    waits for the finger to lift feels broken to a child, and in a timing
///    game it would also make every press late.
///  * **It cannot be "wrong".** Pressing jump with nothing to jump over is a
///    jump; there is no penalty and no cooldown to be caught out by.
class PlayButton extends StatefulWidget {
  const PlayButton({
    super.key,
    required this.kind,
    required this.onPressed,
    this.onReleased,
  });

  final PlayButtonKind kind;

  /// Fired on press-down. See the class doc.
  final VoidCallback onPressed;

  /// Fired on release — only the duck uses it, to end a held crouch.
  final VoidCallback? onReleased;

  /// The drawn button. The touch area is larger; see [hitAreaFraction].
  static const double buttonSize = 140;

  /// How much of the screen's width and height each button's hit area covers.
  /// The bottom-left and bottom-right quarters, as the scope asks.
  static const double hitAreaFraction = 0.5;

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> {
  bool _down = false;

  void _press() {
    setState(() => _down = true);
    widget.onPressed();
  }

  void _release() {
    if (!_down) return;
    setState(() => _down = false);
    widget.onReleased?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // For a screen reader / a parent's accessibility tooling only. Nothing
      // here is drawn as text.
      label: widget.kind == PlayButtonKind.paw ? 'Jump' : 'Duck',
      button: true,
      child: GestureDetector(
        // Down, not up: see the class doc.
        onTapDown: (_) => _press(),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        child: AnimatedScale(
          // A visible squash on press, so the child can see their own press
          // land even before the cat answers.
          scale: _down ? 0.9 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            width: PlayButton.buttonSize,
            height: PlayButton.buttonSize,
            decoration: BoxDecoration(
              color:
                  (widget.kind == PlayButtonKind.paw
                          ? KidPalette.playColors[3]
                          : KidPalette.playColors[4])
                      .withValues(alpha: 0.92),
              shape: BoxShape.circle,
              border: Border.all(color: KidPalette.ink, width: 5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: CustomPaint(painter: _ButtonIconPainter(widget.kind)),
          ),
        ),
      ),
    );
  }
}

/// The button icons, for the render test — which exists so a human can check
/// that the paw says "jump" and the crouching cat says "duck". They are the
/// only instructions in the game.
@visibleForTesting
CustomPainter buttonIconPainter(PlayButtonKind kind) =>
    _ButtonIconPainter(kind);

/// The icons, drawn rather than fonted: a paw print and a crouching cat.
///
/// Drawn because no Material icon says "crouch". A wrong icon is worse than a
/// crude one — the icon IS the instruction here, and there is no text to fall
/// back on.
class _ButtonIconPainter extends CustomPainter {
  _ButtonIconPainter(this.kind);

  final PlayButtonKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = KidPalette.ink;
    final c = Offset(size.width / 2, size.height / 2);

    switch (kind) {
      case PlayButtonKind.paw:
        // A big pad and four toes. Reads as a paw at arm's length.
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c.dx, c.dy + size.height * 0.12),
            width: size.width * 0.42,
            height: size.height * 0.34,
          ),
          paint,
        );
        for (final (i, a) in [-0.95, -0.35, 0.35, 0.95].indexed) {
          final r = size.width * (i == 1 || i == 2 ? 0.34 : 0.3);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(
                c.dx + sin(a) * r,
                c.dy - size.height * 0.14 - cos(a) * size.height * 0.1,
              ),
              width: size.width * 0.17,
              height: size.height * 0.21,
            ),
            paint,
          );
        }
        // An up-arrow hint under the paw: jump is UP. Not text — a shape a
        // child reads as direction.
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, size.height * 0.12)
            ..lineTo(c.dx - size.width * 0.1, size.height * 0.24)
            ..lineTo(c.dx + size.width * 0.1, size.height * 0.24)
            ..close(),
          Paint()..color = KidPalette.ink.withValues(alpha: 0.45),
        );
      case PlayButtonKind.crouch:
        // A flattened cat: low wide body, head down, ears back. The same
        // silhouette the cat itself takes when ducking, so the button is a
        // picture of what will happen.
        final bodyY = c.dy + size.height * 0.1;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(c.dx - size.width * 0.04, bodyY),
              width: size.width * 0.52,
              height: size.height * 0.22,
            ),
            Radius.circular(size.height * 0.11),
          ),
          paint,
        );
        canvas.drawCircle(
          Offset(c.dx + size.width * 0.22, bodyY - size.height * 0.02),
          size.width * 0.11,
          paint,
        );
        // Ears swept BACK along the head, not up.
        //
        // Drawn as two low triangles pointing backwards (towards the tail),
        // which is what a real cat's ears do when it flattens. The first
        // version pointed them up and apart and read as a spiky scribble above
        // the head — and this icon is one of only two instructions in the
        // entire game, so it has to be legible at a glance.
        for (final lift in [0.0, 0.055]) {
          canvas.drawPath(
            Path()
              ..moveTo(c.dx + size.width * 0.2, bodyY - size.height * 0.06)
              ..lineTo(
                c.dx + size.width * 0.06,
                bodyY - size.height * (0.1 + lift),
              )
              ..lineTo(c.dx + size.width * 0.2, bodyY - size.height * 0.01)
              ..close(),
            paint,
          );
        }
        // Tail low.
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - size.width * 0.28, bodyY)
            ..quadraticBezierTo(
              c.dx - size.width * 0.4,
              bodyY + size.height * 0.08,
              c.dx - size.width * 0.34,
              bodyY + size.height * 0.16,
            ),
          Paint()
            ..color = KidPalette.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width * 0.05
            ..strokeCap = StrokeCap.round,
        );
        // A down-arrow hint above: duck is DOWN.
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, size.height * 0.26)
            ..lineTo(c.dx - size.width * 0.1, size.height * 0.14)
            ..lineTo(c.dx + size.width * 0.1, size.height * 0.14)
            ..close(),
          Paint()..color = KidPalette.ink.withValues(alpha: 0.45),
        );
    }
  }

  @override
  bool shouldRepaint(_ButtonIconPainter oldDelegate) =>
      oldDelegate.kind != kind;
}
