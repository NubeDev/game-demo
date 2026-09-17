import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../shared/celebration.dart';
import '../../shared/kid_palette.dart';
import '../../shared/kid_sounds.dart';
import '../../shared/rive_character.dart';
import 'assets.dart';
import 'components/balloon.dart';
import 'components/progress_stars.dart';

/// Balloon Pop.
///
/// Balloons float up from the bottom; tapping one pops it with a sound and a
/// burst. Every [popsPerCelebration] pops there is a celebration, then more
/// balloons. It never ends and it cannot be lost:
///
///  * a balloon that reaches the top just drifts away — no sound, no penalty,
///    nothing subtracted;
///  * there is no timer, no miss counter, no accuracy, no streak;
///  * the progress stars only ever fill.
class BalloonPopGame extends FlameGame {
  BalloonPopGame({required this.sounds});

  final KidSounds sounds;

  /// How many pops earn a celebration. Small enough that a child gets there
  /// quickly and often.
  static const popsPerCelebration = 10;

  /// Drawn balloon radius. The touch target is larger — see [Balloon].
  static const balloonRadius = 46.0;

  final _random = Random();

  late final Celebration _celebration;
  late final ProgressStars _stars;
  RiveCharacter? _character;

  /// Pops since the last celebration.
  int _popsThisRound = 0;

  /// Seconds until the next balloon spawns.
  double _spawnCountdown = 0;

  /// Paused only while a celebration plays, so the screen isn't busy at once.
  bool _spawning = true;

  @override
  Color backgroundColor() => KidPalette.skyBottom;

  @override
  Future<void> onLoad() async {
    // Sky gradient, behind everything.
    add(_Sky());

    _stars = ProgressStars(
      total: popsPerCelebration,
      // Top-left, clear of the home button (which the screen puts top-right).
      position: Vector2(24, 24),
    );
    add(_stars);

    _celebration = Celebration();
    add(_celebration);

    // The Rive character watches from the bottom-left corner.
    //
    // It is added optimistically: if the file or its properties are missing,
    // RiveCharacter logs and does nothing, and the game still plays. A missing
    // character must never block the child.
    final character = RiveCharacter(
      assetPath: BalloonPopAssets.character,
      properties: balloonPopCharacterProperties,
      // Small and cornered: rewards.riv is a stand-in (it is a whole rewards
      // SCREEN, not a character), so it is kept out of the play area until real
      // character art replaces it.
      size: Vector2(150, 150),
      position: Vector2(16, size.y - 166),
    );
    _character = character;
    add(character);

    // A few balloons to start, so the screen is never empty on arrival.
    for (var i = 0; i < 2; i++) {
      _spawnBalloon(startY: size.y * (0.75 + i * 0.3));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_spawning) {
      _spawnCountdown -= dt;
      if (_spawnCountdown <= 0) {
        _spawnBalloon();
        // Sparse on purpose: too many balloons at once reads as chaos.
        // 1.4-2.4s keeps a few on screen without crowding.
        _spawnCountdown = 1.4 + _random.nextDouble() * 1.0;
      }
    }

    // Retire balloons that floated off the top. Not a failure — see class doc.
    for (final balloon in children.query<Balloon>()) {
      if (balloon.position.y < -balloon.size.y) {
        balloon.driftAway();
      }
    }
  }

  void _spawnBalloon({double? startY}) {
    // Keep clear of the screen edges so nothing spawns half-off.
    final margin = balloonRadius * 1.6;
    final x = margin + _random.nextDouble() * (size.x - margin * 2);

    add(Balloon(
      color: KidPalette.playColors[_random.nextInt(
        KidPalette.playColors.length,
      )],
      // Slow and varied. The slowest is well within a five-year-old's reach;
      // the fastest still gives several seconds of screen time.
      riseSpeed: 34 + _random.nextDouble() * 26,
      radius: balloonRadius,
      position: Vector2(x, startY ?? size.y + balloonRadius * 2),
      onPopped: _onBalloonPopped,
    ));
  }

  void _onBalloonPopped(Balloon balloon) {
    sounds.pop();
    _popsThisRound++;
    _stars.filled = _popsThisRound;

    // Build anticipation as the stars fill.
    _character?.setExcitement(_popsThisRound / popsPerCelebration);

    if (_popsThisRound >= popsPerCelebration) {
      _celebrate();
    }
  }

  void _celebrate() {
    sounds.celebrate();
    _celebration.burst(size);
    _character?.celebrate();

    // Pause spawning briefly so the confetti is the thing on screen, then roll
    // straight back into play. There is no "well done" screen to dismiss: a
    // child cannot read one, and stopping play to acknowledge success breaks
    // the rhythm.
    _spawning = false;
    _popsThisRound = 0;
    _stars.filled = 0;

    add(TimerComponent(
      period: 1.8,
      removeOnFinish: true,
      onTick: () {
        _spawning = true;
        _character?.setExcitement(0);
      },
    ));
  }
}

/// What the character's `.riv` file must expose.
///
/// These names match `rewards.riv` from the official flame_rive example, which
/// is a stand-in until real art exists. A custom file swaps these names and
/// needs no Dart changes — see `README.md` in this folder.
const balloonPopCharacterProperties = RiveCharacterProperties(
  // rewards.riv has no triggers of its own; it exposes nested numbers. The
  // excitement number below drives its coin counter, which is enough to prove
  // the data binding works end to end.
  excitementNumber: 'Coin/Item_Value',
  excitementScale: 100,
);

/// A soft vertical gradient behind the play area.
class _Sky extends PositionComponent with HasGameReference<BalloonPopGame> {
  _Sky() : super(priority: -100);

  @override
  void onMount() {
    super.onMount();
    size = game.size;
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
  }

  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & size.toSize();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [KidPalette.skyTop, KidPalette.skyBottom],
        ).createShader(rect),
    );
  }
}
