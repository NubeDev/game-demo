import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../obstacles.dart';

/// What the cat is doing right now.
enum CatState {
  /// Running along the ground. The default and the resting state.
  running,

  /// In the air, going up or coming down.
  jumping,

  /// Crouched low, going under something.
  ducking,

  /// Mid-slapstick after a bonk. Still moving, still fine.
  recovering,

  /// Nobody has pressed anything for a while: slowed to a trot, then sat down
  /// to sniff a flower. Presses always wake it (CLAUDE.md §3: never stuck).
  idle,
}

/// The cat. Placeholder art, drawn in code: a blob body, a round head, two
/// ears, a tail that swings, four legs that trot.
///
/// ## The jump is the whole game
///
/// It is tuned, not physical. A real gravity curve either floats (which feels
/// unresponsive) or snaps (which is unforgiving), so the arc here is explicit:
/// [jumpRise] up, a beat of hang time, then down — about [jumpDuration] end to
/// end, which is slow enough for a five-year-old to watch their own press
/// work.
///
/// ## Late and early both work (the scope's rule, load-bearing)
///
///  * a press up to [coyoteTime] AFTER the cat has left the ground still
///    jumps — the child's finger was late, not wrong;
///  * a press made at ANY point during a jump or a slapstick is remembered
///    ([jumpBufferTime]) and fires the moment the cat can act on it, so a child
///    who presses eagerly is never ignored.
///
/// Both of these exist so the child never feels the game missed their press.
/// That feeling, at five, is indistinguishable from being bad at it.
class Cat extends PositionComponent {
  Cat({required super.position, this.onLanded})
    : super(size: Vector2(112, 92), anchor: Anchor.bottomCenter);

  /// Called when the cat touches down, so the world can check what it landed
  /// on (a bouncy mushroom) and play a sound.
  final void Function()? onLanded;

  /// How high the jump goes, in logical pixels.
  ///
  /// Tuned BY LOOKING, not by arithmetic. The first version was 138 — which is
  /// 2.4x the tallest obstacle's hitbox and passed its test comfortably, but on
  /// a 720px screen it was a 19% hop by a cat only 8% of the screen tall, and
  /// it read as a shuffle rather than a jump. The cat walked up to a fence, did
  /// something small, and a player reported "the jump doesn't work".
  ///
  /// A jump has to be unmistakable at a glance: this clears roughly THREE times
  /// the cat's own height, which is the cartoon proportion a child reads as
  /// "it leapt" rather than "it stepped".
  static const jumpRise = 250.0;

  /// The smallest rise the jump is ever squeezed to, however short the screen.
  ///
  /// Below this the cat stops clearing the tallest obstacle by a margin a
  /// five-year-old's timing can hit — pinned by a test against
  /// [ObstacleKind.tallestJumpable]. Headroom loses to this, not the other way
  /// round: a jump that cannot clear a fence is a broken game, whereas a cat
  /// that briefly touches the top of the screen is merely a big jump.
  static const minJumpRise = 150.0;

  /// Space left above the cat's head at the top of its highest arc.
  static const _topMargin = 6.0;

  /// The rise this cat actually uses, once the screen size is known.
  ///
  /// [jumpRise] is the design value, tuned for a tablet. On a phone in
  /// landscape there is simply not 250px of sky above the ground line — the
  /// cat would leave the top of the screen at the peak, and a child who cannot
  /// see their cat has lost the thread of the game. [fitTo] brings it down to
  /// what the screen has.
  double _rise = jumpRise;
  double get rise => _rise;

  /// Fit the arc to the sky this screen actually has.
  ///
  /// [headroom] is the distance from the ground line to the top of the screen.
  /// The arc is fitted so the *highest* thing the cat does — a mushroom bounce,
  /// which is [bounceMultiplier] times a jump — still keeps its ears on screen.
  void fitTo({required double headroom}) {
    final ceiling = headroom - size.y - _topMargin;
    _rise = (ceiling / bounceMultiplier).clamp(minJumpRise, jumpRise);
    _ceiling = max(ceiling, minJumpRise);
  }

  /// The highest any arc may reach on this screen. Bounces are clamped to it;
  /// an ordinary jump is always well under it.
  double _ceiling = jumpRise * bounceMultiplier;

  /// How long the whole arc takes, in seconds. Slow on purpose: the child needs
  /// to see the crouch, the rise and the landing as three separate things.
  static const jumpDuration = 0.86;

  /// A press this long after leaving the ground still jumps.
  static const coyoteTime = 0.16;

  /// A press this long before the cat can act on it is remembered and fires the
  /// moment it can — on landing, or when a slapstick ends.
  ///
  /// Deliberately long enough to cover a whole jump arc ([jumpDuration]) plus a
  /// recovery. The natural eager press is *right after take-off*, which is the
  /// furthest possible moment from the landing that will honour it — a shorter
  /// window would quietly throw away exactly the press children actually make.
  static const jumpBufferTime = jumpDuration + recoveryDuration;

  /// How long a duck lasts if the button is tapped rather than held. Long
  /// enough to pass under a whole obstacle without holding — holding a button
  /// for a precise window is a fine-motor skill this age does not have.
  static const duckDuration = 0.85;

  /// How long the landing squash lasts. Short — it is a punctuation mark on
  /// the jump, not a state the child has to wait out.
  static const landSquashDuration = 0.16;

  /// How long each slapstick recovery lasts. Half a second or so: long enough
  /// to be funny, short enough that the child is never waiting.
  static const recoveryDuration = 0.6;

  /// How high a bounce off a mushroom goes, relative to a jump. The reward for
  /// landing on one is *air*, and it has to read as clearly more than a jump.
  static const bounceMultiplier = 1.45;

  CatState _state = CatState.running;
  CatState get state => _state;

  /// Height above the ground line, in logical pixels. 0 is standing.
  /// Named `airHeight` rather than `height`, which PositionComponent already
  /// owns as the component's drawn height.
  double _height = 0;
  double get airHeight => _height;

  /// Progress through the current jump arc, 0..1.
  double _jumpTime = 0;

  /// How high the current jump reaches — a bounce is higher than a jump.
  double _jumpPeak = jumpRise;

  /// Seconds left of the current duck, or 0.
  double _duckLeft = 0;

  /// Seconds since the cat left the ground, for the coyote window.
  double _sinceGrounded = 0;

  /// Seconds left on a remembered early press, or 0.
  double _bufferedJump = 0;

  /// Seconds into the current slapstick, and which one.
  double _recoveryLeft = 0;
  MissStyle _missStyle = MissStyle.none;
  MissStyle get missStyle => _missStyle;

  /// Animation clock for the trot, the tail and the ears.
  double _time = 0;

  /// Seconds left of the squash on touchdown, or 0. Purely cosmetic — it never
  /// gates input, so a child pressing again the instant they land still jumps.
  double _landSquash = 0;

  /// 0..1 — how flat the ears are. Raised by the world a beat before a duck
  /// obstacle arrives, which is the game's only "look out" signal and the
  /// reason a duck is fair (CLAUDE.md §3: telegraph, never surprise).
  double _earFlatten = 0;

  /// How wide the cat's body is at the ground, for collision. Narrower than the
  /// drawn sprite so a graze is not a bonk.
  static const bodyWidth = 68.0;

  /// The cat's collision height when running, and when ducked. Ducking must
  /// clear the duck obstacles' bottoms — pinned by a test.
  static const standingHeight = 84.0;
  static const duckedHeight = 44.0;

  /// The box the world collides against: at the cat's feet, as wide as
  /// [bodyWidth], as tall as its current posture.
  Rect get hitBox {
    final h = _state == CatState.ducking ? duckedHeight : standingHeight;
    // The pancake is flat, so a cat mid-pancake genuinely fits under things.
    final flattened = _isPancaking ? duckedHeight * 0.55 : h;
    return Rect.fromLTWH(
      position.x - bodyWidth / 2,
      position.y - _height - flattened,
      bodyWidth,
      flattened,
    );
  }

  bool get _isPancaking =>
      _state == CatState.recovering && _missStyle == MissStyle.pancake;

  /// Whether the cat is on the ground (so a bounce or a bonk can happen).
  bool get isGrounded => _height <= 0.01 && _state != CatState.jumping;

  /// Whether a press right now would be accepted as a jump. True on the ground
  /// and for [coyoteTime] after leaving it.
  bool get canJump =>
      _state != CatState.recovering &&
      (isGrounded ||
          (_state == CatState.jumping &&
              _sinceGrounded <= coyoteTime &&
              _jumpTime == 0));

  /// The paw button was pressed.
  ///
  /// Never refuses outright: if the cat cannot jump this instant the press is
  /// remembered ([jumpBufferTime]) and fires the moment it can. A press that
  /// does nothing at all reads to a five-year-old as the game ignoring them.
  void jump({double? peak}) {
    if (_state == CatState.idle) wake();
    if (_state == CatState.recovering) {
      // Mid-tumble. Remember it: the cat is about to be upright again, and the
      // child's press should not be thrown away because of the slapstick.
      _bufferedJump = jumpBufferTime;
      return;
    }
    if (_state == CatState.jumping && _jumpTime > 0) {
      // Already in the air. Buffer it so an eager double-press jumps again on
      // landing rather than being lost. NOT a double jump — one jump at a time
      // keeps the arc learnable.
      _bufferedJump = jumpBufferTime;
      return;
    }
    _state = CatState.jumping;
    _jumpTime = 0;
    // Clamped to the screen's ceiling so no arc, however it was asked for,
    // takes the cat off the top.
    _jumpPeak = min(peak ?? _rise, _ceiling);
    _duckLeft = 0;
  }

  /// A mushroom, a snail or a cushion was landed on: straight back up, higher.
  void bounce() => jump(peak: _rise * bounceMultiplier);

  /// The crouching-cat button was pressed.
  void duck() {
    if (_state == CatState.idle) wake();
    if (_state == CatState.recovering) return;
    // A duck pressed in mid-air is not refused — it starts the moment the cat
    // lands, for the same reason jumps are buffered.
    _duckLeft = duckDuration;
    if (isGrounded) _state = CatState.ducking;
  }

  /// The button was released. The duck still runs its minimum, so a child who
  /// stabs the button rather than holding it still gets under the obstacle.
  void releaseDuck() {
    if (_duckLeft > duckDuration * 0.45) _duckLeft = duckDuration * 0.45;
  }

  /// Bonked into something. Plays the matching slapstick and carries on — this
  /// is the *whole* answer to "a runner is failure-shaped" (CLAUDE.md §3).
  void bonk(MissStyle style) {
    if (_state == CatState.recovering) return;
    _missStyle = style;
    _state = CatState.recovering;
    _recoveryLeft = recoveryDuration;
    _height = 0;
    _jumpTime = 0;
    _duckLeft = 0;
  }

  /// Nobody is playing: slow to a trot and sit down. Not a penalty and not a
  /// pause — the world stops scrolling so the child can look at things.
  void sit() {
    if (_state == CatState.running) _state = CatState.idle;
  }

  /// Any press wakes the cat up.
  void wake() {
    if (_state == CatState.idle) _state = CatState.running;
  }

  /// Flatten the ears — the duck telegraph. 1 is fully flat.
  set earFlatten(double value) => _earFlatten = value.clamp(0.0, 1.0);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_bufferedJump > 0) _bufferedJump -= dt;
    if (_landSquash > 0) _landSquash -= dt;

    switch (_state) {
      case CatState.jumping:
        _advanceJump(dt);
      case CatState.ducking:
        _duckLeft -= dt;
        if (_duckLeft <= 0) _state = CatState.running;
      case CatState.recovering:
        _recoveryLeft -= dt;
        if (_recoveryLeft <= 0) {
          _missStyle = MissStyle.none;
          _state = CatState.running;
          _takeBufferedJump();
        }
      case CatState.running:
        _sinceGrounded = 0;
        if (_duckLeft > 0) _state = CatState.ducking;
        _takeBufferedJump();
      case CatState.idle:
        break;
    }
  }

  void _advanceJump(double dt) {
    _jumpTime += dt;
    _sinceGrounded += dt;
    final p = (_jumpTime / jumpDuration).clamp(0.0, 1.0);
    // sin gives a soft launch and a soft landing with a hang at the top —
    // which is the shape a child can actually read and time against. A
    // parabola lands hard and reads as falling.
    _height = sin(p * pi) * _jumpPeak;
    if (_jumpTime >= jumpDuration) {
      _height = 0;
      _jumpTime = 0;
      _landSquash = landSquashDuration;
      _sinceGrounded = 0;
      _state = _duckLeft > 0 ? CatState.ducking : CatState.running;
      onLanded?.call();
      // A landing is the moment a buffered press pays off, and it has to be
      // checked AFTER onLanded so a bounce off a mushroom wins over it.
      if (_state != CatState.jumping) _takeBufferedJump();
    }
  }

  void _takeBufferedJump() {
    if (_bufferedJump <= 0) return;
    _bufferedJump = 0;
    jump();
  }

  /// How far through the current recovery, 0..1. Drives the slapstick drawing.
  double get _recoveryProgress =>
      1 - (_recoveryLeft / recoveryDuration).clamp(0.0, 1.0);

  @override
  void render(Canvas canvas) {
    // Every posture is a squash/stretch of the same blob, so the cat always
    // reads as the same animal — a different silhouette per state would look
    // like several cats to a five-year-old.
    var squashX = 1.0;
    var squashY = 1.0;
    var lean = 0.0;
    var spin = 0.0;
    var sink = 0.0;

    /// Whether [spin] pivots about the cat's middle rather than its feet. Only
    /// the tumble does — see MissStyle.tumble below.
    var spinAboutCentre = false;

    switch (_state) {
      case CatState.running:
      case CatState.idle:
        // A gentle bob in time with the trot.
        final bob = sin(_time * (_state == CatState.idle ? 4 : 12));
        // The landing. A jump that simply stops looks like the cat was
        // switched off at the ground; the squash is what makes it land.
        final land = (_landSquash / landSquashDuration).clamp(0.0, 1.0);
        squashY = 1 + bob * 0.04 - land * 0.22;
        squashX = 1 - bob * 0.03 + land * 0.18;
        if (_state == CatState.idle) sink = 10; // sitting down
      case CatState.jumping:
        final p = (_jumpTime / jumpDuration).clamp(0.0, 1.0);
        // Stretch follows SPEED, not height. The height curve is sin(p*pi), so
        // the cat's vertical speed is its derivative, cos(p*pi): fastest at the
        // launch and at the touchdown, and momentarily still at the apex.
        //
        // The first version stretched by sin(p*pi) — peaking at the apex, the
        // one moment the cat is not moving at all — so the cat was longest
        // while it hung and shortest while it shot upwards, which is squash and
        // stretch exactly backwards. Now it stretches out of the launch,
        // rounds off at the top, and stretches again into the landing.
        final speed = cos(p * pi).abs();
        squashY = 1 + speed * 0.16;
        squashX = 1 - speed * 0.11;
        lean = sin(p * pi * 2) * 0.12;
      case CatState.ducking:
        squashY = 0.55;
        squashX = 1.25;
      case CatState.recovering:
        final p = _recoveryProgress;
        switch (_missStyle) {
          case MissStyle.tumble:
            // One full roll, landing on its feet. Funny, not painful.
            //
            // The roll has to happen about the cat's MIDDLE. Rotating about the
            // feet (where the anchor is) swings the whole body below the ground
            // line and off the bottom of the screen — it reads as the cat
            // falling through the floor rather than tumbling, which is exactly
            // the "falling off the bottom" this game must never show.
            // [_spinAboutCentre] lifts the pivot for this one case.
            spin = p * pi * 2;
            squashY = 1 - sin(p * pi) * 0.1;
            spinAboutCentre = true;
          case MissStyle.pancake:
            // Flat, then springs back with a wobble.
            //
            // Squashed to 0.45, not 0.25: flatter than this and the head loses
            // its shape entirely, so the cat stops reading as a cat and starts
            // reading as a smear. "Squashed flat and fine" is funny; an
            // unrecognisable shape is just alarming.
            final flat = p < 0.55 ? 1.0 : 1 - (p - 0.55) / 0.45;
            squashY = 1 - flat * 0.55;
            squashX = 1 + flat * 0.4;
          case MissStyle.splash:
            // Belly-flop: low and wide, then floats back up.
            final dunk = sin(min(1.0, p * 1.4) * pi);
            sink = dunk * 16;
            squashY = 1 - dunk * 0.35;
            squashX = 1 + dunk * 0.3;
          case MissStyle.none:
            break;
        }
    }

    canvas.save();
    // THE JUMP'S ACTUAL TRAVEL. `position` stays pinned to the ground line —
    // the game sets it there and `hitBox` measures up from it — so the air the
    // cat has gained is applied here, at draw time.
    //
    // Without this line the cat's hitbox rose and every jump test passed while
    // the cat visibly stayed on the ground: all a player saw was the squash
    // and the legs tucking up. A jump you cannot see is not a jump.
    //
    // Before the rotate/scale on purpose: applied after them, the squash would
    // scale the travel and the cat would drift as it stretched.
    canvas.translate(0, -_height);
    // Anchor is bottom-centre, so the feet stay on the ground through every
    // squash — a cat whose feet left the floor when it ducked would read as
    // floating. The tumble is the exception: it pivots about the body's middle,
    // or the roll swings the cat through the floor.
    final pivotY = spinAboutCentre ? size.y * 0.55 : size.y;
    canvas.translate(size.x / 2, pivotY + sink);
    canvas.rotate(spin + lean);
    canvas.scale(squashX, squashY);
    canvas.translate(-size.x / 2, -pivotY);

    _paintCat(canvas);
    canvas.restore();
  }

  void _paintCat(Canvas canvas) {
    final body = Paint()..color = _bodyColor;
    final ink = Paint()
      ..color = KidPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final w = size.x;
    final h = size.y;
    final trot = _state == CatState.running || _state == CatState.idle
        ? sin(_time * 12)
        : 0.0;

    // Tail: swings behind. A tail is most of what makes a blob read as a cat.
    final tailLift = _state == CatState.jumping ? -14.0 : 0.0;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.12, h * 0.62)
        ..quadraticBezierTo(
          -w * 0.08,
          h * 0.5 + tailLift + trot * 5,
          w * 0.06,
          h * 0.22 + tailLift,
        ),
      Paint()
        ..color = _bodyColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );

    // Legs: two pairs, trotting. Tucked up in a jump.
    final legDrop = _state == CatState.jumping ? h * 0.06 : h * 0.16;
    for (final (i, x) in [w * 0.3, w * 0.42, w * 0.66, w * 0.78].indexed) {
      final swing = trot * (i.isEven ? 4 : -4);
      canvas.drawLine(
        Offset(x, h * 0.74),
        Offset(x + swing, h * 0.74 + legDrop),
        ink,
      );
    }

    // Body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.42, w * 0.66, h * 0.36),
        Radius.circular(h * 0.18),
      ),
      body,
    );

    // Head.
    final headCentre = Offset(w * 0.76, h * 0.32);
    final headR = h * 0.22;
    canvas.drawCircle(headCentre, headR, body);

    // Ears. These flatten as the duck telegraph — the only warning in the game.
    for (final side in [-1.0, 1.0]) {
      final base = Offset(
        headCentre.dx + side * headR * 0.55,
        headCentre.dy - headR * 0.62,
      );
      // Flat ears rotate outward and shrink, which is how a real cat says
      // "something is coming".
      final tipUp = headR * (0.85 - _earFlatten * 0.7);
      final tipOut = side * headR * (0.35 + _earFlatten * 0.75);
      canvas.drawPath(
        Path()
          ..moveTo(base.dx - headR * 0.3, base.dy + headR * 0.25)
          ..lineTo(base.dx + tipOut, base.dy - tipUp + headR * 0.25)
          ..lineTo(base.dx + headR * 0.3, base.dy + headR * 0.3)
          ..close(),
        body,
      );
    }

    // Face: two eyes and a nose. Closed eyes when sitting or mid-slapstick —
    // a cat with its eyes shut reads as "having a moment", not as hurt.
    final eyesShut = _state == CatState.idle || _state == CatState.recovering;
    final eyePaint = Paint()..color = KidPalette.ink;
    for (final side in [-1.0, 0.45]) {
      final c = Offset(
        headCentre.dx + side * headR * 0.42,
        headCentre.dy - headR * 0.05,
      );
      if (eyesShut) {
        canvas.drawLine(
          Offset(c.dx - 4, c.dy),
          Offset(c.dx + 4, c.dy),
          Paint()
            ..color = KidPalette.ink
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawCircle(c, 3.2, eyePaint);
      }
    }
    // A smile. Always smiling, including through a bonk — the cat is never
    // hurt, and a five-year-old reads a hurt animal as real (CLAUDE.md §3).
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(
          headCentre.dx + headR * 0.1,
          headCentre.dy + headR * 0.3,
        ),
        radius: headR * 0.4,
      ),
      0.15,
      pi - 0.3,
      false,
      Paint()
        ..color = KidPalette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Placeholder cat colour. One warm ginger, so the cat is the same animal
  /// every session — a randomised character is a different friend each time.
  static const _catColor = Color(0xFFFFB07C);

  Color get _bodyColor => _catColor;
}
