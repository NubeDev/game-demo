import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../shared/celebration.dart';
import '../../shared/kid_haptics.dart';
import '../../shared/kid_sounds.dart';
import 'assets.dart';
import 'components/passengers.dart';
import 'components/scenery.dart';
import 'components/train.dart';
import 'lands.dart';
import 'ride.dart';

/// Little Train.
///
/// A toy steam train chuffs through a meadow, a forest, the seaside and the
/// snow. Animals wait beside the line, waving. **Tap anywhere and the train
/// stops** — stop beside a passenger and they hop straight in. Three
/// passengers fill the three wagons, and then the train rolls into the
/// station for a party, everyone waves goodbye, and it's off to the next land.
///
/// The new verb is **stop at the right place** — set against Cat Run's timed
/// press, Car Trip's steer and Crystal Party's hold. The rules that make it
/// fair, and the one rule that makes it legal, live in [Ride].
///
/// This is also the first game here built on **generated** art and voice: every
/// picture and line was made with Google's Gemini models by the scripts in
/// `tools/`, ahead of time. At runtime it is as offline as the rest of the app.
class LittleTrainGame extends FlameGame {
  LittleTrainGame({required this.sounds});

  final KidSounds sounds;

  /// All the rules and the state. Pure, so tests drive it directly.
  final ride = Ride();

  /// Pixels per ride unit. The train is designed against a 16:9 screen; on a
  /// squarer one (a 4:3 tablet) everything shrinks so there is still line
  /// ahead of the engine to see passengers coming.
  double get unit => min(size.y, size.x / 1.78);

  /// Where the wheels touch the rails.
  double get railY => size.y * 0.82;

  /// Where things beside the line stand: just behind the far rail.
  double get backLine => railY - Scenery.gaugeOnScreen * unit * 1.1;

  /// Where passengers stand: on the near side, in front of the track, so the
  /// train passing can never hide the animal the child is stopping for.
  double get frontLine => railY + 0.075 * unit;

  /// Where the front of the engine sits on screen. Far enough right that the
  /// whole train fits, and no further — every pixel to the right of it is
  /// line ahead, which is where the passengers come from.
  double get frontX =>
      max(size.x * 0.55, (Ride.trainLength + 0.06) * unit);

  /// Screen x of a point on the line.
  double screenX(double rideX) => frontX + (rideX - ride.trainX) * unit;

  String get stopPostPath => LittleTrainAssets.stopPost;

  late final TrainView _train;
  late final Celebration _celebration;
  bool _loaded = false;

  @visibleForTesting
  TrainView get train => _train;

  @override
  Color backgroundColor() => lands.first.skyColor;

  @override
  Future<void> onLoad() async {
    // Every land up front: ~2MB of webp, and it means the cross-fade to the
    // next land can never hitch on a load.
    await images.loadAll([
      LittleTrainAssets.engine,
      LittleTrainAssets.wagon,
      LittleTrainAssets.stopPost,
      for (final land in lands) ...land.allPaths,
    ]);
    add(Scenery());
    // Passengers twice, either side of the train: see [Passengers].
    add(Passengers(front: false));
    _train = TrainView();
    add(_train);
    add(Passengers(front: true));
    _celebration = Celebration();
    add(_celebration);
    add(_Veil());
    _loaded = true;
  }

  /// The child's one control: a tap anywhere below the home button.
  void tap() {
    // A tap during loading is dropped rather than queued — the train is not
    // on screen yet, so there is nothing for it to have meant.
    if (!_loaded) return;
    ride.tap();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_loaded) return;
    ride.viewAhead = (size.x - frontX) / unit;
    ride.update(dt);
    for (final (event, passenger) in ride.drainEvents()) {
      _onEvent(event, passenger);
    }
  }

  /// Turns what the ride decided into what the child sees, hears and feels.
  ///
  /// Every line is spoken: the players cannot read (CLAUDE.md §3), so the
  /// voice IS the instruction — "Next stop!" as a passenger comes into view,
  /// "Hop on!" when the train stops beside them.
  void _onEvent(RideEvent event, Passenger? p) {
    switch (event) {
      case RideEvent.allAboard:
        sounds.say(TrainLine.allAboard);
        _train.toot();
      case RideEvent.nextStop:
        sounds.say(TrainLine.nextStop);
      case RideEvent.braking:
        KidHaptics.tap();
      case RideEvent.perfectStop:
        sounds.say(TrainLine.hopOn);
        KidHaptics.pop();
      case RideEvent.hurry:
        sounds.say(TrainLine.hopOn);
      case RideEvent.waitForMe:
        // The miss. It is a funny scamper and a shout, never a sad sound —
        // and the passenger always catches the train (see [Ride]).
        sounds.say(TrainLine.waitForMe);
      case RideEvent.boarded:
        sounds.say(p!.perfect ? TrainLine.thankYou : TrainLine.yay);
        sounds.pop(progress: ride.wagonsFilled / passengersPerLand);
        KidHaptics.pop();
        final at = Vector2(screenX(ride.doorX(p.wagon!)), railY - 0.18 * unit);
        // A stop right beside them earns the bigger sparkle. A chase still
        // earns one: it is a different good moment, not a lesser one.
        _celebration.puff(at, pieces: p.perfect ? 14 : 8);
      case RideEvent.stoppedAlone:
      case RideEvent.toot:
        sounds.say(TrainLine.tootToot);
        _train.toot();
      case RideEvent.depart:
        sounds.say(TrainLine.hereWeGo);
        _train.toot();
      case RideEvent.arrived:
        sounds.say(TrainLine.weAreHere);
        sounds.celebrate();
        KidHaptics.celebrate();
        _celebration.burst(size);
      case RideEvent.unload:
        if (p == ride.passengers.first) sounds.say(TrainLine.byeBye);
      case RideEvent.landChanged:
        break;
    }
  }
}

/// The soft cover between lands, in the new land's sky colour, so the scenery
/// swaps out of sight. A slow fade, never a flash (CLAUDE.md §3).
class _Veil extends Component with HasGameReference<LittleTrainGame> {
  @override
  void render(Canvas canvas) {
    final veil = game.ride.veil;
    if (veil <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      Paint()..color = game.ride.land.skyColor.withValues(alpha: veil),
    );
  }
}
