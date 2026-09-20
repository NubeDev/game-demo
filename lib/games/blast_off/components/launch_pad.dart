import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/kid_palette.dart';
import '../../../shared/kid_shapes.dart';
import '../countdown.dart';

/// The sky behind the rocket, and the ground it stands on.
///
/// Scenery, never a play object — but not a dead backdrop either: the clouds
/// drift, and they can be poked (see [cloudAt]), so a tap that hit nothing in
/// particular is still something the child did rather than a near miss.
///
/// The sky brightens very slightly as zero approaches. It is far too subtle to
/// notice deliberately and that is the point — no flashing, nothing startling
/// (CLAUDE.md §3).
class LaunchPad extends PositionComponent {
  LaunchPad({required this.countdown, required Vector2 size})
    : super(size: size, priority: -10);

  final Countdown countdown;

  /// How much of the bottom of the screen the control buttons own.
  ///
  /// Set by the game from what the screen actually lays out. The grass grows
  /// to cover this band, so the buttons sit ON the ground rather than in front
  /// of the rocket — see [groundHeight].
  double bottomInset = 0;

  final _clouds = <_Cloud>[];
  final _random = Random();

  /// Set when a cloud is poked, so it puffs up briefly.
  final _poked = <_Cloud, double>{};

  @override
  void onLoad() {
    for (var i = 0; i < 4; i++) {
      _clouds.add(
        _Cloud(
          at: Vector2(
            _random.nextDouble() * size.x,
            40 + _random.nextDouble() * size.y * 0.34,
          ),
          width: 90 + _random.nextDouble() * 80,
          speed: 5 + _random.nextDouble() * 10,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final cloud in _clouds) {
      cloud.at.x += cloud.speed * dt;
      if (cloud.at.x - cloud.width > size.x) cloud.at.x = -cloud.width;
      final poke = _poked[cloud];
      if (poke != null) {
        final next = poke - dt * 1.6;
        if (next <= 0) {
          _poked.remove(cloud);
        } else {
          _poked[cloud] = next;
        }
      }
    }
  }

  /// The cloud under [point], if any — used so a tap on the sky has an answer.
  /// The hit area is generous, because a five-year-old aims at "the cloud",
  /// not at its outline.
  bool cloudAt(Vector2 point) {
    for (final cloud in _clouds) {
      if ((cloud.at - point).length < cloud.width * 0.7) {
        _poked[cloud] = 1;
        return true;
      }
    }
    return false;
  }

  @override
  void render(Canvas canvas) {
    // A whisper of extra warmth as the count runs down.
    final warmth = countdown.phase == CountdownPhase.counting
        ? countdown.progress * 0.12
        : 0.0;

    canvas.drawRect(
      size.toRect(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(KidPalette.skyTop, KidPalette.sun, warmth)!,
            KidPalette.skyBottom,
          ],
        ).createShader(size.toRect()),
    );

    for (final cloud in _clouds) {
      final swell = 1 + (_poked[cloud] ?? 0) * 0.28;
      canvas.drawPath(
        KidShapes.cloud(Offset(cloud.at.x, cloud.at.y), cloud.width * swell),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }

    // The ground: a simple band, with a pad under the rocket.
    final top = groundTop;
    canvas.drawRect(
      Rect.fromLTWH(0, top, size.x, size.y - top),
      Paint()..color = KidPalette.hillNear,
    );
    final padWidth = 220 * sceneScale;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x / 2 - padWidth / 2, top - 14, padWidth, 26),
        const Radius.circular(12),
      ),
      Paint()..color = KidPalette.hillFar,
    );
  }

  /// The grass with nothing standing on it — the height it has when the
  /// controls are narrower than this.
  static const minGroundHeight = 70.0;

  /// How far the pad lifts the rocket above the grass.
  static const _padLift = 12.0;

  /// The rocket at full size, and the clear sky the smallest one still needs
  /// above the pad. Used to stop the grass growing so tall it pushes the
  /// rocket off the top of the screen.
  static const rocketHeight = 220.0;
  static const _skyHeadroom = 12.0;

  /// The floor on [sceneScale].
  ///
  /// The rocket is tappable — it honks when poked — so it is a touch target
  /// and may not shrink below 80 logical px wide (CLAUDE.md §3). It is 120
  /// wide at full size, and this is the ratio that keeps it legal.
  static const minSceneScale = 80 / 120;

  static const _minSkyDepth =
      rocketHeight * minSceneScale + _padLift + _skyHeadroom;

  /// How tall the grass is.
  ///
  /// It grows to cover [bottomInset] so the controls rest on it. It stops
  /// growing once the sky above would no longer hold the smallest rocket we
  /// allow: past that point the rocket gets pushed off the top of the screen,
  /// which is worse than a button overlapping some grass.
  double get groundHeight {
    final ceiling = max(minGroundHeight, size.y - _minSkyDepth);
    return max(minGroundHeight, min(bottomInset, ceiling));
  }

  /// The y where the grass starts.
  double get groundTop => size.y - groundHeight;

  /// The y the rocket stands on.
  double get padTop => groundTop - _padLift;

  /// How much the rocket and the star jar shrink to fit the sky left above
  /// the pad. 1 whenever there is room, which is the normal case on a tablet.
  double get sceneScale => min(1, maxSceneScale);

  /// The biggest the rocket may be drawn and still stand clear of the top of
  /// the screen.
  ///
  /// [sceneScale] is this capped at 1 — the size the scene draws at normally.
  /// The rocket is allowed past that cap, because it grows with the chosen
  /// countdown length (see CountdownLength.sizeFactor), and this is the
  /// ceiling that growth stops at. On a tall screen it is way above 1; on a
  /// short one it is the same number as [sceneScale], so a long countdown
  /// simply stops getting bigger rather than sailing off the top.
  double get maxSceneScale {
    final sky = padTop - _skyHeadroom;
    return max(minSceneScale, sky / rocketHeight);
  }

  /// The star jar at full size, and the band the home button owns at the top
  /// right: its 20px inset, its 96px self, and a little clear air beneath.
  static const jarHeight = 190.0;
  static const homeButtonReserve = 20.0 + 96.0 + 12.0;

  /// How much the star jar shrinks: the same as the rest of the scene.
  ///
  /// It is NOT shrunk to duck under the home button. The jar is the countdown
  /// made visible for a child who cannot read a digit (CLAUDE.md §3), so it is
  /// load-bearing and has to stay legible; an earlier version of this fix
  /// capped its height to clear the corner and left it a thumbnail. It moves
  /// out of the corner instead — see [jarRight].
  double get jarScale => sceneScale;

  /// How far in from the right edge the jar's centre sits.
  ///
  /// Normally a jar's width in, tucked low on the right. When the ground has
  /// risen far enough that a full-height jar would reach into the home
  /// button's corner, it slides further left instead of getting smaller — the
  /// home button must never be covered (the child has to be able to leave),
  /// and the jar must stay readable. There is plenty of room sideways in a
  /// landscape-only game; it is only height that is ever short.
  double get jarRight {
    final normal = (130 * jarScale).clamp(70.0, 130.0);
    final jarTop = padTop + 4 - jarHeight * jarScale;
    if (jarTop >= homeButtonReserve) return normal;
    // Clear of the home button's left edge, plus the jar's own half-width.
    return homeButtonWidth + 20 + (jarWidth * jarScale) / 2 + 12;
  }

  /// The home button's own size, and the star jar's width at full size.
  static const homeButtonWidth = 96.0;
  static const jarWidth = 140.0;
}

class _Cloud {
  _Cloud({required this.at, required this.width, required this.speed});

  final Vector2 at;
  final double width;
  final double speed;
}
