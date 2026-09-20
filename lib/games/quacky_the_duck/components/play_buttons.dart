
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';

/// Which of the two buttons this is.
enum QuackyButtonKind {
  /// A cross duck, leaning forward. Dash. Bottom-right, under the right thumb.
  dash,

  /// A flattened duck. Duck. Bottom-left, under the left thumb.
  flat,
}

/// One of the two big picture buttons — the entire control scheme.
///
/// Rules this encodes (CLAUDE.md §3, and the scope's *Touch targets*):
///  * **No text.** A cross duck and a flat duck. The player cannot read.
///  * **[buttonSize] is 140**, well past the 80x80 floor — and the *hit area*
///    is bigger still: the parent wraps this in the whole bottom quarter of the
///    screen, so a mis-aimed thumb works anyway.
///  * **It answers instantly on press-down**, not on release.
///  * **It cannot be "wrong".** Dashing with nobody ahead is a duck running;
///    ducking with nothing overhead is a skid. No penalty, no cooldown.
///
/// **Left is "get low", right is "go", in this game and in Cat Run.** A child
/// who has played one already knows which thumb is which — consistency across
/// the app doing the job an instruction would.
class QuackyButton extends StatefulWidget {
  const QuackyButton({
    super.key,
    required this.kind,
    required this.onPressed,
    this.onReleased,
  });

  final QuackyButtonKind kind;

  /// Fired on press-down. See the class doc.
  final VoidCallback onPressed;

  /// Fired on release — only the duck uses it, to end a held skid.
  final VoidCallback? onReleased;

  /// The drawn button. The touch area is larger; see [hitAreaFraction].
  static const double buttonSize = 140;

  /// How much of the screen's width and height each button's hit area covers.
  static const double hitAreaFraction = 0.5;

  @override
  State<QuackyButton> createState() => _QuackyButtonState();
}

class _QuackyButtonState extends State<QuackyButton> {
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
      label: widget.kind == QuackyButtonKind.dash ? 'Dash' : 'Duck',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _press(),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        child: AnimatedScale(
          // A visible squash on press, so the child can see their own press
          // land even before Quacky answers.
          scale: _down ? 0.9 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            width: QuackyButton.buttonSize,
            height: QuackyButton.buttonSize,
            decoration: BoxDecoration(
              color:
                  (widget.kind == QuackyButtonKind.dash
                          ? KidPalette.playColors[1]
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
/// that the leaning duck says "dash" and the flat duck says "duck". They are
/// the only instructions in the game.
@visibleForTesting
CustomPainter quackyButtonIconPainter(QuackyButtonKind kind) =>
    _ButtonIconPainter(kind);

/// The icons, drawn rather than fonted: no Material icon says "a duck ducking".
/// A wrong icon is worse than a crude one — the icon IS the instruction here,
/// and there is no text to fall back on.
class _ButtonIconPainter extends CustomPainter {
  _ButtonIconPainter(this.kind);

  final QuackyButtonKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()..color = KidPalette.ink;
    final c = Offset(size.width / 2, size.height / 2);

    switch (kind) {
      case QuackyButtonKind.dash:
        // A duck leaning hard forward, head down, with two speed lines behind.
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(0.24);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(-size.width * 0.02, size.height * 0.06),
            width: size.width * 0.46,
            height: size.height * 0.3,
          ),
          ink,
        );
        // Head, thrust forward and low.
        canvas.drawCircle(
          Offset(size.width * 0.19, -size.height * 0.06),
          size.width * 0.11,
          ink,
        );
        canvas.restore();
        // Beak.
        canvas.drawPath(
          Path()
            ..moveTo(c.dx + size.width * 0.27, c.dy - size.height * 0.04)
            ..lineTo(c.dx + size.width * 0.42, c.dy + size.height * 0.01)
            ..lineTo(c.dx + size.width * 0.27, c.dy + size.height * 0.06)
            ..close(),
          Paint()..color = const Color(0xFFFF9F1C),
        );
        // Speed lines behind him: the shape a child reads as "fast".
        for (final dy in [-0.12, 0.0, 0.12]) {
          canvas.drawLine(
            Offset(c.dx - size.width * 0.44, c.dy + size.height * dy),
            Offset(c.dx - size.width * 0.26, c.dy + size.height * dy),
            Paint()
              ..color = KidPalette.ink.withValues(alpha: 0.5)
              ..strokeWidth = size.width * 0.045
              ..strokeCap = StrokeCap.round,
          );
        }
        // A forward-arrow hint: dash is FORWARD.
        canvas.drawPath(
          Path()
            ..moveTo(c.dx + size.width * 0.34, size.height * 0.84)
            ..lineTo(c.dx + size.width * 0.2, size.height * 0.76)
            ..lineTo(c.dx + size.width * 0.2, size.height * 0.92)
            ..close(),
          Paint()..color = KidPalette.ink.withValues(alpha: 0.45),
        );
      case QuackyButtonKind.flat:
        // A duck flat on its belly with its neck stretched forward, and a bar
        // above it with a clear gap between the two.
        //
        // REBUILT after looking at it: the first version drew the body and the
        // bar in nearly the same ink, with the head buried inside the body
        // outline, so the whole icon read as two dark stripes and said nothing
        // at all. This button is one of only two instructions in the game and
        // there is no text to fall back on, so the duck has to be a duck.
        final bodyY = c.dy + size.height * 0.2;

        // The thing being skidded under, drawn FIRST and in a lighter ink so
        // the duck reads on top of it.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.12,
              size.height * 0.16,
              size.width * 0.76,
              size.height * 0.1,
            ),
            Radius.circular(size.height * 0.05),
          ),
          Paint()..color = KidPalette.ink.withValues(alpha: 0.4),
        );
        // Its two legs, so it reads as a bench rather than a floating bar —
        // and the GAP between them is the thing the child has to see.
        for (final dx in [0.14, 0.8]) {
          canvas.drawRect(
            Rect.fromLTWH(
              size.width * dx,
              size.height * 0.26,
              size.width * 0.06,
              size.height * 0.28,
            ),
            Paint()..color = KidPalette.ink.withValues(alpha: 0.4),
          );
        }

        // The flattened body: a long low oval.
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c.dx - size.width * 0.1, bodyY),
            width: size.width * 0.56,
            height: size.height * 0.2,
          ),
          ink,
        );
        // The neck, forward and LEVEL with the body.
        canvas.drawLine(
          Offset(c.dx + size.width * 0.02, bodyY),
          Offset(c.dx + size.width * 0.22, bodyY),
          Paint()
            ..color = KidPalette.ink
            ..strokeWidth = size.height * 0.1
            ..strokeCap = StrokeCap.round,
        );
        // The head, clear of the body so it is a head and not a bulge.
        canvas.drawCircle(
          Offset(c.dx + size.width * 0.26, bodyY),
          size.width * 0.1,
          ink,
        );
        // The beak, in orange — the one bit of colour, and the thing that says
        // "bird" fastest.
        canvas.drawPath(
          Path()
            ..moveTo(c.dx + size.width * 0.34, bodyY - size.height * 0.045)
            ..lineTo(c.dx + size.width * 0.49, bodyY)
            ..lineTo(c.dx + size.width * 0.34, bodyY + size.height * 0.045)
            ..close(),
          Paint()..color = const Color(0xFFFF9F1C),
        );
        // A white eye dot, so the dark head has a face on it.
        canvas.drawCircle(
          Offset(c.dx + size.width * 0.28, bodyY - size.height * 0.025),
          size.width * 0.022,
          Paint()..color = Colors.white,
        );
        // A down-arrow hint at the bottom: duck is DOWN.
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, size.height * 0.92)
            ..lineTo(c.dx - size.width * 0.09, size.height * 0.8)
            ..lineTo(c.dx + size.width * 0.09, size.height * 0.8)
            ..close(),
          Paint()..color = KidPalette.ink.withValues(alpha: 0.5),
        );
    }
  }

  @override
  bool shouldRepaint(_ButtonIconPainter oldDelegate) =>
      oldDelegate.kind != kind;
}
