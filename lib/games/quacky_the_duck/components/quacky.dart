import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../park.dart';

/// What Quacky is doing right now.
enum QuackyState {
  /// Waddling along the path. The default and the resting state.
  waddling,

  /// Head down, wings out, feet going — closing the gap.
  dashing,

  /// Flat on his belly, skidding under something.
  ducking,

  /// Mid-slapstick after a beak-bonk. Still moving, still fine.
  huffing,

  /// Nobody has pressed anything for a while: sat down on the path, grumbling
  /// to himself. Presses always wake him (CLAUDE.md §3: never stuck).
  sitting,
}

/// Quacky. Placeholder art, drawn in code: a fat oval body, a round head, an
/// orange triangle beak, and two cross little eyebrow lines that lift as he
/// cheers up.
///
/// ## The eyebrows are a progress bar
///
/// [mood] drives how cross he looks, and the game only ever raises it within a
/// round. It is the second progress signal (the bread rolls are the first) and
/// the one a child will actually read, because it is drawn on the character
/// they are already watching (CLAUDE.md §3: progress, never a score).
///
/// ## Late and early both work (load-bearing)
///
///  * a press up to [duckBufferTime] before he can act on it is remembered and
///    fires the moment he can, so an eager child is never ignored;
///  * a tapped duck lasts [duckDuration] on its own — holding a button for a
///    precise window is a fine-motor skill this age does not have.
class Quacky extends PositionComponent {
  Quacky({required super.position})
    : super(size: Vector2(126, 104), anchor: Anchor.bottomCenter);

  /// How long a duck lasts if the button is tapped rather than held.
  ///
  /// **Derived, not guessed.** It has to outlast the WIDEST duck hazard passing
  /// at `QuackyWorld.scrollSpeed` — the washing line is 215px at 180px/s, which
  /// is 1.19s — or a tapped duck ends halfway under the thing and the child
  /// gets bonked for a press that was perfectly good. Generous on purpose: a
  /// duck that only just works is a duck that mostly does not.
  ///
  /// A test pins this against the widest hazard there is, so adding a wider one
  /// fails the test rather than silently breaking the button.
  static const duckDuration = 1.6;

  /// A press this long before he can act on it is remembered and fires the
  /// moment he can — when a huff ends, or when a duck finishes.
  static const duckBufferTime = 0.7;

  /// How long a beak-bonk lasts. Long enough to be funny, short enough that
  /// the child is never waiting.
  static const huffDuration = 0.55;

  /// How long one dash burst lasts.
  ///
  /// A **burst, not a hold** — holding a button tires a small hand (Crystal
  /// Party flagged this). A single tap gives a whole burst; holding just
  /// chains them.
  static const dashDuration = 0.6;

  /// How tall he is when flat on his belly. Every duck hazard is placed
  /// against this, and a test pins it against [HazardKind.deepestDuckable].
  static const duckedHeight = 44.0;

  QuackyState _state = QuackyState.waddling;
  QuackyState get state => _state;

  /// How cross he is. Set by the game; only ever climbs within a round.
  Mood mood = Mood.furious;

  double _stateTime = 0;
  double _waddle = 0;
  double _bufferedDuck = -1;

  /// Whether the duck button is currently held down.
  bool _duckHeld = false;

  /// 0..1 — how far into a dash burst he is, for the lean and the feathers.
  double _dashPower = 0;
  double get dashPower => _dashPower;

  bool get isDucking => _state == QuackyState.ducking;
  bool get isDashing => _state == QuackyState.dashing;
  bool get isSitting => _state == QuackyState.sitting;

  /// How tall his body is right now — full height, or flat if ducking.
  double get bodyHeight =>
      _state == QuackyState.ducking ? duckedHeight : size.y;

  /// What the park actually collides with.
  ///
  /// Narrower than the art on purpose, for the same reason hazards are: a child
  /// who pressed a frame late should still get under the bench.
  Rect get hitBox {
    final h = bodyHeight;
    const inset = 18.0;
    return Rect.fromLTWH(
      position.x - size.x / 2 + inset,
      position.y - h,
      size.x - inset * 2,
      h,
    );
  }

  // --- the controls -------------------------------------------------------

  /// The dash button. Cannot be "wrong": dashing with nothing ahead is just a
  /// duck running, with no penalty and no cooldown to be caught out by.
  void dash() {
    if (_state == QuackyState.huffing) return;
    _state = QuackyState.dashing;
    _stateTime = 0;
    _dashPower = 1;
  }

  /// The duck button, pressed.
  void duck() {
    if (_state == QuackyState.huffing) {
      // Remembered, and fired the moment the huff ends.
      _bufferedDuck = 0;
      return;
    }
    _duckHeld = true;
    _state = QuackyState.ducking;
    _stateTime = 0;
  }

  /// The duck button, released. A tap still gets the full [duckDuration].
  void releaseDuck() => _duckHeld = false;

  /// Bonked his beak. Slapstick, then straight back to waddling.
  ///
  /// Note what is NOT here: no life lost, no progress removed, no restart, no
  /// pause, no sad noise, and **the chase gap is untouched** — the thing he was
  /// chasing waits for him (the scope's promise).
  void bonk() {
    _state = QuackyState.huffing;
    _stateTime = 0;
    _dashPower = 0;
  }

  /// Nobody is playing: sit down on the path and grumble.
  void sit() {
    if (_state == QuackyState.sitting) return;
    _state = QuackyState.sitting;
    _stateTime = 0;
  }

  /// Any press wakes him.
  void wake() {
    if (_state == QuackyState.sitting) {
      _state = QuackyState.waddling;
      _stateTime = 0;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _stateTime += dt;
    if (_state != QuackyState.sitting) _waddle += dt;

    // The dash decays rather than stopping dead, so the burst has a shape.
    _dashPower = max(0, _dashPower - dt / dashDuration);

    if (_bufferedDuck >= 0) _bufferedDuck += dt;

    switch (_state) {
      case QuackyState.dashing:
        if (_dashPower <= 0) _state = QuackyState.waddling;
      case QuackyState.ducking:
        // A held button keeps him down; a tap gets the full duration.
        if (!_duckHeld && _stateTime >= duckDuration) {
          _state = QuackyState.waddling;
        }
      case QuackyState.huffing:
        if (_stateTime >= huffDuration) {
          _state = QuackyState.waddling;
          // Honour an eager press made during the huff.
          if (_bufferedDuck >= 0 && _bufferedDuck <= duckBufferTime) {
            _bufferedDuck = -1;
            duck();
          }
        }
      case QuackyState.waddling:
      case QuackyState.sitting:
        break;
    }

    if (_bufferedDuck > duckBufferTime) _bufferedDuck = -1;
  }

  @override
  void render(Canvas canvas) {
    final ducking = _state == QuackyState.ducking;
    final sitting = _state == QuackyState.sitting;
    final h = bodyHeight;

    // A bouncier waddle the happier he is — the mood shows in the walk as well
    // as the face, so it reads even when he is small on screen.
    final bounce = sitting
        ? 0.0
        : sin(_waddle * 9) * (2 + mood.brightness * 3.5);
    // Head down and leaning forward when dashing. Pronounced on purpose: at
    // the first value (0.22 rad at full power) the lean was about six degrees
    // and simply could not be seen, so the dash button looked like it did
    // nothing — and a button that looks like it does nothing is a button a
    // five-year-old stops pressing.
    final lean = _dashPower * 0.45;

    canvas.save();
    // The component's own origin is bottom-centre; draw in local space with
    // the feet at (size.x / 2, size.y).
    canvas.translate(size.x / 2, size.y);
    canvas.rotate(lean);

    final ink = Paint()
      ..color = KidPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    // Body: a fat oval, squashed flat when ducking.
    final bodyRect = Rect.fromCenter(
      center: Offset(0, -h * 0.45 + bounce),
      width: size.x * (ducking ? 1.08 : 0.86),
      height: h * 0.82,
    );
    canvas.drawOval(bodyRect, Paint()..color = _bodyColour);
    canvas.drawOval(bodyRect, ink);

    // A wing, out and back when dashing.
    final wingSpread = _dashPower * 1.15;
    canvas.save();
    canvas.translate(-size.x * 0.06, -h * 0.5 + bounce);
    canvas.rotate(-wingSpread);
    final wing = Rect.fromCenter(
      center: Offset.zero,
      width: size.x * 0.42,
      height: h * (ducking ? 0.3 : 0.38),
    );
    canvas.drawOval(wing, Paint()..color = _wingColour);
    canvas.drawOval(wing, ink);
    canvas.restore();

    // Tail, a little triangle at the back.
    canvas.drawPath(
      Path()
        ..moveTo(-size.x * 0.4, -h * 0.55 + bounce)
        ..lineTo(-size.x * 0.56, -h * 0.72 + bounce)
        ..lineTo(-size.x * 0.34, -h * 0.4 + bounce)
        ..close(),
      Paint()..color = _bodyColour,
    );

    // Head. A ducking bird stretches its neck FORWARD and keeps the head level
    // with its body — it does not tuck the head underneath itself.
    //
    // The head also has to SHRINK when flat, because at the standing radius it
    // was wider than the whole ducked body is tall: the first version drew a
    // ball hanging below the flattened body, which read as a duck that had
    // fallen over rather than one sliding under a bench.
    final headR = size.x * (ducking ? 0.175 : 0.26);
    final headCentre = Offset(
      size.x * (ducking ? 0.52 : 0.3) + _dashPower * 10,
      (ducking ? -h * 0.5 : -h * 1.0) + bounce,
    );
    canvas.drawCircle(headCentre, headR, Paint()..color = _bodyColour);
    canvas.drawCircle(headCentre, headR, ink);

    // Neck, joining head to body — a thick stroke, so a flat duck still reads
    // as one animal rather than two shapes. It leaves the body at shoulder
    // height when standing and at body height when flat.
    canvas.drawLine(
      Offset(size.x * 0.1, (ducking ? -h * 0.5 : -h * 0.62) + bounce),
      headCentre,
      Paint()
        ..color = _bodyColour
        ..strokeWidth = size.x * (ducking ? 0.2 : 0.17)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(headCentre, headR, Paint()..color = _bodyColour);
    canvas.drawCircle(headCentre, headR, ink);

    _renderFace(canvas, headCentre, headR);

    // Motion streaks behind him while dashing. Cheap, and the clearest "fast"
    // signal there is at this age — much more legible than a pose alone.
    if (_dashPower > 0.05) {
      final streak = Paint()
        ..color = KidPalette.ink.withValues(alpha: 0.28 * _dashPower)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      for (final dy in [0.35, 0.6, 0.85]) {
        canvas.drawLine(
          Offset(-size.x * 0.55, -h * dy + bounce),
          Offset(-size.x * (0.55 + 0.3 * _dashPower), -h * dy + bounce),
          streak,
        );
      }
    }

    // Feet: two little orange paddles, going like mad during a dash.
    final stride = sitting ? 0.0 : sin(_waddle * (9 + _dashPower * 18)) * 9;
    for (final (i, side) in [-1.0, 1.0].indexed) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              side * size.x * 0.13 + (i == 0 ? stride : -stride),
              sitting ? -2 : 0,
            ),
            width: size.x * 0.2,
            height: 9,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = _beakColour,
      );
    }

    canvas.restore();
  }

  /// The face. The beak, the eye, and the two eyebrows that are the whole
  /// progress story.
  void _renderFace(Canvas canvas, Offset head, double r) {
    final ink = Paint()..color = KidPalette.ink;

    // Beak: an orange triangle, pointing the way he is going.
    canvas.drawPath(
      Path()
        ..moveTo(head.dx + r * 0.55, head.dy - r * 0.1)
        ..lineTo(head.dx + r * 1.42, head.dy + r * 0.16)
        ..lineTo(head.dx + r * 0.55, head.dy + r * 0.42)
        ..close(),
      Paint()..color = _beakColour,
    );
    canvas.drawPath(
      Path()
        ..moveTo(head.dx + r * 0.55, head.dy - r * 0.1)
        ..lineTo(head.dx + r * 1.42, head.dy + r * 0.16)
        ..lineTo(head.dx + r * 0.55, head.dy + r * 0.42)
        ..close(),
      Paint()
        ..color = KidPalette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Eye.
    canvas.drawCircle(Offset(head.dx + r * 0.22, head.dy - r * 0.22), 4.6, ink);

    // The eyebrow. THE progress signal, so it has to read at arm's length on a
    // tablet: one thick stroke that ROTATES about the eye rather than sliding
    // up and down the skull.
    //
    // Both of those are corrections. The first version drew it as a line whose
    // ends moved independently at a fixed height — which put it ON the head
    // outline, where at furious it merged into the stroke and at delighted it
    // floated off above the head as a detached dash. Neither read as an
    // eyebrow at all, and this is the one bit of art the whole progress signal
    // rests on.
    //
    // `brightness` runs 0 (furious) .. 1 (delighted), so a future Rive Quacky
    // takes exactly this number on a bound property and nothing else changes.
    final cross = 1 - mood.brightness;
    final eye = Offset(head.dx + r * 0.22, head.dy - r * 0.22);
    // Furious: the inner end drops hard towards the beak. Delighted: it lifts
    // past level into a surprised arch.
    final tilt = cross * 0.85 - mood.brightness * 0.25;
    // And it sits further from the eye the happier he is — a raised brow.
    final lift = r * (0.42 + mood.brightness * 0.2);
    final halfLen = r * 0.46;

    canvas.save();
    canvas.translate(eye.dx, eye.dy - lift);
    canvas.rotate(tilt);
    canvas.drawLine(
      Offset(-halfLen, 0),
      Offset(halfLen, 0),
      Paint()
        ..color = KidPalette.ink
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  /// He warms up in colour as he cheers up — a second, non-shape cue for the
  /// same signal, so it does not depend on seeing one thin eyebrow.
  Color get _bodyColour =>
      Color.lerp(const Color(0xFFCBBE88), const Color(0xFFFFE156),
          mood.brightness)!;

  Color get _wingColour =>
      Color.lerp(const Color(0xFFB3A77A), const Color(0xFFFFC94D),
          mood.brightness)!;

  static const _beakColour = Color(0xFFFF9F1C);
}
