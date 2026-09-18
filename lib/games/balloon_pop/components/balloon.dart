import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../../../shared/kid_shapes.dart';
import 'pop_burst.dart';

/// One balloon: floats up, pops when tapped or swiped through.
///
/// Placeholder art — drawn in code, but drawn properly: a balloon body with a
/// knot, a swinging string, a highlight that makes it read as round, and a tilt
/// that follows its own drift so it looks like it is riding the air rather than
/// sliding along a track.
///
/// A balloon can need more than one tap ([taps]). A big one takes three, and
/// **inflates visibly** on each: a five-year-old cannot be told "keep going",
/// so the balloon has to say it. Every tap still counts as progress, so mashing
/// is rewarded and a half-inflated balloon that floats away costs nothing.
///
/// Replacing it with a sprite means changing [render] and reading the path from
/// `assets.dart`; nothing else here changes.
class Balloon extends PositionComponent with TapCallbacks {
  Balloon({
    required this.color,
    required this.riseSpeed,
    required this.onPopped,
    required super.position,
    required double radius,
    this.sparkly = false,
    this.taps = 1,
  })  : _radius = radius,
        _tapsLeft = taps,
        super(
          // Size is the TOUCH TARGET, not the drawn balloon. It is deliberately
          // larger than the art (see BalloonPopGame.balloonRadii): a
          // five-year-old aiming at the balloon and landing just outside it
          // should still pop it. A tap that visibly misses but felt on-target
          // reads to them as the game ignoring them.
          size: Vector2.all(radius * touchTargetRatio),
          anchor: Anchor.center,
        );

  /// How much bigger the touch target is than the balloon's radius.
  ///
  /// Exposed so the game and its tests can check the smallest balloon it ever
  /// spawns still clears the 80x80 floor (CLAUDE.md §3).
  static const touchTargetRatio = 2.6;

  final Color color;

  /// Logical pixels per second upward. Gentle and varied.
  final double riseSpeed;

  /// A rare balloon that glitters and bursts into stars. Worth no more progress
  /// than any other — there is no score, so a "better" balloon can only ever
  /// mean a better *moment*, never a bigger number (CLAUDE.md §3).
  final bool sparkly;

  /// How many taps this balloon takes. One for an ordinary balloon; a big one
  /// takes three and swells between them.
  final int taps;

  /// Called on every tap that counted — including the squeezes of a multi-tap
  /// balloon, so persistence is rewarded rather than only completion. Check
  /// [isSpent] to tell a squeeze from the final burst. Not called when the
  /// balloon drifts away.
  final void Function(Balloon balloon) onPopped;

  final double _radius;
  int _tapsLeft;
  final _random = Random();

  /// The drawn radius, which is smaller than the touch target.
  double get radius => _radius;

  /// Taps still needed before this balloon bursts.
  int get tapsRemaining => _tapsLeft;

  /// A balloon that takes more than one tap.
  bool get isBig => taps > 1;

  /// How much it has swollen from being squeezed, 0 upwards. Drives the "it is
  /// about to go" reading that replaces any written instruction.
  double _inflation = 0;

  /// Horizontal drift, so balloons don't rise in straight mechanical lines.
  late final double _driftPhase = _random.nextDouble() * pi * 2;
  late final double _driftAmount = 8 + _random.nextDouble() * 14;

  /// Each balloon breathes at its own rate, so a screenful never pulses in
  /// unison — that would read as one machine rather than several balloons.
  late final double _breathPhase = _random.nextDouble() * pi * 2;
  late final double _breathRate = 1.6 + _random.nextDouble() * 0.7;

  double _time = 0;

  /// 0..1, faded out while drifting away off the top.
  double _alpha = 1;

  /// Set once popping starts, so a child mashing the same balloon can't count
  /// it twice while the pop animation plays.
  bool _isPopping = false;

  /// Set once it has left the top of the screen, so the game's per-frame sweep
  /// can call [driftAway] repeatedly without restarting the fade.
  bool _isLeaving = false;

  /// True once this balloon can no longer be popped — it is bursting, or it has
  /// already floated away.
  bool get isSpent => _isPopping || _isLeaving;

  @override
  void update(double dt) {
    super.update(dt);
    if (_isPopping) return;

    _time += dt;
    position.y -= riseSpeed * dt;

    // Gentle sine sway. Small amplitude — it should read as floating, not
    // as the balloon dodging the child's finger.
    final sway = sin(_time * 1.2 + _driftPhase);
    position.x += sway * _driftAmount * dt;

    // Lean into the drift, like a real balloon on a string. Tiny (about 4
    // degrees) — enough to look alive, not enough to move the touch target.
    angle = cos(_time * 1.2 + _driftPhase) * 0.07;

    if (_isLeaving) {
      // Shrink and fade on the way out instead of blinking off, so a balloon
      // the child was reaching for visibly *leaves* rather than being taken.
      _alpha = (_alpha - dt * 1.6).clamp(0.0, 1.0);
      final s = (scale.x - dt * 0.5).clamp(0.2, 1.0);
      scale.setValues(s, s);
      if (_alpha <= 0) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final centre = Offset(size.x / 2, size.y / 2);
    // Breathing squash-and-stretch: helium balloons never hold still.
    final breath = sin(_time * _breathRate + _breathPhase) * 0.03;
    // Each squeeze leaves the balloon fatter and rounder — tauter, closer to
    // going. This is the whole instruction for a multi-tap balloon.
    final swell = 1 + _inflation;
    final bodyWidth = _radius * 1.85 * (1 - breath) * swell;
    final bodyHeight = _radius * 2.1 * (1 + breath) * (1 + _inflation * 0.6);

    _renderString(canvas, centre);
    _renderBody(canvas, centre, bodyWidth, bodyHeight);
    if (sparkly) _renderGlitter(canvas, centre);
    _renderHighlight(canvas, centre);
  }

  void _renderString(Canvas canvas, Offset centre) {
    // The string trails opposite the sway, which is what sells "floating".
    final swing = sin(_time * 1.2 + _driftPhase + pi) * _radius * 0.35;
    final path = Path()
      ..moveTo(centre.dx, centre.dy + _radius)
      ..quadraticBezierTo(
        centre.dx + swing,
        centre.dy + _radius * 1.5,
        centre.dx + swing * 0.5,
        centre.dy + _radius * 1.95,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = KidPalette.ink.withValues(alpha: 0.5 * _alpha)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _renderBody(
    Canvas canvas,
    Offset centre,
    double bodyWidth,
    double bodyHeight,
  ) {
    final body = Rect.fromCenter(
      center: centre,
      width: bodyWidth,
      height: bodyHeight,
    );

    // A soft shadow inside the lower edge, so the balloon reads as a volume
    // rather than a flat sticker. Radial, not a drop shadow: no hard edges.
    canvas.drawOval(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [
            _lighten(color, 0.30).withValues(alpha: _alpha),
            color.withValues(alpha: _alpha),
            _darken(color, 0.18).withValues(alpha: _alpha),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(body),
    );

    // Knot: a small triangle under the body, like the pinched neck.
    final knotY = centre.dy + bodyHeight / 2;
    canvas.drawPath(
      Path()
        ..moveTo(centre.dx - _radius * 0.13, knotY - _radius * 0.04)
        ..lineTo(centre.dx + _radius * 0.13, knotY - _radius * 0.04)
        ..lineTo(centre.dx, knotY + _radius * 0.16)
        ..close(),
      Paint()..color = _darken(color, 0.12).withValues(alpha: _alpha),
    );
  }

  void _renderHighlight(Canvas canvas, Offset centre) {
    // The wet-look glint. Two blobs read as a curved surface; one reads as a
    // smudge.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centre.dx - _radius * 0.38, centre.dy - _radius * 0.52),
        width: _radius * 0.46,
        height: _radius * 0.66,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.5 * _alpha),
    );
    canvas.drawCircle(
      Offset(centre.dx - _radius * 0.18, centre.dy - _radius * 0.16),
      _radius * 0.1,
      Paint()..color = Colors.white.withValues(alpha: 0.28 * _alpha),
    );
  }

  void _renderGlitter(Canvas canvas, Offset centre) {
    // Three small stars twinkling out of phase with each other. Twinkle, not
    // flash: alpha never leaves the 0.15-0.85 band, and nothing strobes
    // (CLAUDE.md §3 — no flashing).
    const spots = [Offset(-0.3, 0.25), Offset(0.28, -0.1), Offset(0.02, 0.5)];
    for (var i = 0; i < spots.length; i++) {
      final twinkle = 0.5 + 0.35 * sin(_time * 2.4 + i * 2.1);
      canvas.drawPath(
        KidShapes.star(
          Offset(
            centre.dx + spots[i].dx * _radius,
            centre.dy + spots[i].dy * _radius,
          ),
          _radius * 0.18,
        ),
        Paint()..color = Colors.white.withValues(alpha: twinkle * _alpha),
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Pop on tap DOWN, not tap up: a five-year-old's finger often slides
    // between the two, and an ignored tap reads to them as the game being
    // broken.
    pop();
  }

  /// Pops with a quick squash-and-vanish and leaves a [PopBurst] behind — or,
  /// on a multi-tap balloon with taps to spare, swells instead.
  void pop() {
    if (isSpent) return;

    if (_tapsLeft > 1) {
      _tapsLeft--;
      _squeeze();
      // A squeeze counts. Progress only ever rises, so rewarding the tap that
      // did not finish the job costs nothing and means a child who taps once
      // and wanders off still got something (CLAUDE.md §3).
      onPopped(this);
      return;
    }

    _isPopping = true;
    onPopped(this);

    parent?.add(PopBurst(
      color: color,
      radius: _radius,
      position: position.clone(),
      sparkly: sparkly,
    ));

    // Brief over-inflate then out — the balloon "bursts" rather than blinking
    // off, and the burst above takes over where it disappears.
    add(ScaleEffect.to(
      Vector2.all(1.35),
      EffectController(duration: 0.07),
      onComplete: () {
        add(ScaleEffect.to(
          Vector2.zero(),
          EffectController(duration: 0.1),
          onComplete: removeFromParent,
        ));
      },
    ));
  }

  /// A squeeze that did not finish the balloon: it swells, wobbles, and waits.
  ///
  /// The wobble is emphatic on purpose. A tap that produced no visible change
  /// would read as the game ignoring them, which is the one thing a multi-tap
  /// balloon must not do.
  void _squeeze() {
    _inflation += 0.16;
    add(ScaleEffect.to(
      Vector2.all(1.14),
      EffectController(duration: 0.09, reverseDuration: 0.16),
    ));
  }

  /// A balloon that reached the top and drifted away. NOT a failure: nothing is
  /// lost, no sound plays, no counter moves (CLAUDE.md §3). It fades out over
  /// the next fraction of a second and then removes itself.
  void driftAway() {
    if (isSpent) return;
    _isLeaving = true;
  }

  static Color _lighten(Color c, double amount) =>
      Color.lerp(c, Colors.white, amount)!;

  static Color _darken(Color c, double amount) =>
      Color.lerp(c, KidPalette.ink, amount)!;
}
