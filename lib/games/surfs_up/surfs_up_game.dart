import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../shared/celebration.dart';
import '../../shared/kid_haptics.dart';
import '../../shared/kid_sounds.dart';
import '../../shared/lantern_cast.dart';
import 'assets.dart';
import 'beaches.dart';
import 'components/hud.dart';
import 'components/koko.dart';
import 'components/sea.dart';
import 'components/shells.dart';
import 'surf.dart';

/// Surf's Up — the first Lantern Island game.
///
/// Koko the quokka sits on her board out at sea. Swells roll in from behind
/// her: **tap as one lifts her** and she pops up and rides it towards the
/// beach, hopping for shells on the way. Three waves, and she glides up the
/// sand to a party with the friends waiting there.
///
/// The verb is **catch the moment** — set against Little Train's "stop at the
/// right place". There the target waits for the child; here it comes from
/// behind and goes past. What keeps that fair, and legal, is in [Surf].
class SurfsUpGame extends FlameGame {
  SurfsUpGame({required this.sounds, Random? random})
    : surf = Surf(random: random);

  final KidSounds sounds;

  /// All the rules and the state. Pure, so tests drive it directly.
  final Surf surf;

  /// Pixels per [Surf] unit. Designed against 16:9; on a squarer screen
  /// everything shrinks so there is still sea behind Koko to see swells come.
  double get unit => min(size.y, size.x / 1.78);

  /// Koko stays put on screen and the sea moves. Left of centre, so there is
  /// room behind her to watch a swell coming and room ahead for the beach.
  double get kokoScreenX => size.x * 0.34;

  /// The flat sea level on screen, where Koko sits between waves.
  double get seaY => size.y * 0.72;

  /// Where the far sea meets the sky.
  double get horizonY => size.y * 0.46;

  double screenX(double x) => kokoScreenX + (x - surf.kokoX) * unit;
  double worldX(double sx) => surf.kokoX + (sx - kokoScreenX) / unit;
  double screenY(double height) => seaY - height * unit;

  Beach get beach => beachFor(surf.trip);

  late final ui.Image kokoImage;
  final friendImages = <LanternFriend, ui.Image>{};

  late final KokoOnBoard _koko;
  late final Celebration _celebration;
  bool _loaded = false;

  @visibleForTesting
  KokoOnBoard get koko => _koko;

  @override
  ui.Color backgroundColor() => beaches.first.skyTop;

  @override
  Future<void> onLoad() async {
    // Every friend up front, so a beach never hitches when it slides in.
    kokoImage = await rasterizeSvg(SurfsUpAssets.kokoSurfing);
    for (final friend in {for (final b in beaches) ...b.friends}) {
      friendImages[friend] = await rasterizeSvg(friend.svg, height: 400);
    }
    add(Sky());
    add(Sea());
    add(BeachAhead());
    add(Shells());
    _koko = KokoOnBoard();
    add(_koko);
    _celebration = Celebration();
    add(_celebration);
    add(WaveDots());
    add(Veil());
    _loaded = true;
  }

  /// The child's one control: a tap anywhere below the home button.
  void tap() {
    // Dropped during loading: Koko isn't on screen yet.
    if (!_loaded) return;
    surf.tap();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_loaded) return;
    surf.update(dt);
    for (final event in surf.drainEvents()) {
      _onEvent(event);
    }
  }

  /// Where Koko's head is on screen, for sparkles.
  Vector2 get kokoHead => Vector2(
    kokoScreenX,
    screenY(surf.boardHeight(surf.kokoX) + surf.hopLift) -
        KokoOnBoard.height * unit,
  );

  /// Turns what the sea decided into what the child sees, hears and feels.
  ///
  /// There is no voice yet: this game was built in a session without the
  /// generation key. The cues stand in for the lines it wants ("Here it
  /// comes!", "Up!", counting the shells) — see the README.
  void _onEvent(SurfEvent event) {
    switch (event) {
      case SurfEvent.swellComing:
        _koko.lookBack();
      case SurfEvent.paddle:
        // The too-early tap. A splash and a soft tick, never a wobble — it is
        // not a mistake, it is paddling.
        sounds.tap();
        _koko.splash();
      case SurfEvent.caught:
        sounds.boing(springingBack: true);
        KidHaptics.pop();
        _celebration.puff(kokoHead, pieces: 12);
      case SurfEvent.helpedCatch:
        // Koko caught this one herself. Same cheer: the ride is the same ride.
        sounds.boing(springingBack: true);
        _celebration.puff(kokoHead, pieces: 8);
      case SurfEvent.missed:
        // Not a failure cue. She just turns to watch for the next one.
        _koko.lookBack();
      case SurfEvent.hop:
        sounds.flump(variant: 1);
        KidHaptics.tap();
      case SurfEvent.shell:
        // The pop ladder climbs through the ride's shells, so the sound
        // itself counts them up.
        sounds.pop(progress: surf.shellsThisRide / Surf.shellsPerRide);
        KidHaptics.pop();
        _celebration.puff(kokoHead, pieces: 6);
      case SurfEvent.waveDone:
        _koko.splash(big: true);
      case SurfEvent.landed:
        break;
      case SurfEvent.party:
        sounds.celebrate();
        KidHaptics.celebrate();
        _celebration.burst(size);
      case SurfEvent.nextTrip:
        break;
    }
  }
}
