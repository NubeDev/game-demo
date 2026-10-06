import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../assets.dart';
import '../little_train_game.dart';
import '../ride.dart';
import 'draw.dart';
import 'train.dart';

/// Every passenger who is NOT sitting in a wagon: waiting, trotting over,
/// chasing, mid-leap, or hopping off at the station.
///
/// ## Why there are two of these layers
///
/// Passengers wait on the NEAR side of the track, in front of the train. The
/// first browser run had them behind it, and the arriving train covered the
/// very animal the child was trying to stop beside — the one thing in this
/// game that must always be visible.
///
/// But a passenger climbing IN has to end up behind the wagon's side, or they
/// would float over it. So the game adds this component twice: once [front]
/// (drawn after the train) and once behind (drawn before it), and each leap
/// passes from one to the other at its top, where the switch cannot be seen.
class Passengers extends Component with HasGameReference<LittleTrainGame> {
  Passengers({required this.front});

  /// Drawn in front of the train (true) or behind it.
  final bool front;

  /// A waiting passenger is the thing the child is looking for, so they are
  /// big: about as tall as the engine's body.
  static const standHeight = 0.24;

  double _clock = 0;

  @override
  void update(double dt) => _clock += dt;

  @override
  void render(Canvas canvas) {
    final g = game;
    final ground = g.frontLine;
    for (final p in g.ride.passengers) {
      if (_isInFront(p) != front) continue;
      switch (p.state) {
        case PassengerState.waiting:
          _waiting(canvas, g, p, ground);
        case PassengerState.hurrying:
        case PassengerState.chasing:
          _hopping(canvas, g, p, ground);
        case PassengerState.boarding:
          _leaping(canvas, g, p, ground);
        case PassengerState.leaving:
          _leaving(canvas, g, p, ground);
        case PassengerState.riding:
        case PassengerState.gone:
          break;
      }
    }
  }

  /// In front of the train while on the ground; behind it once inside the
  /// wagon's sides. The switch is at the top of each leap.
  static bool _isInFront(Passenger p) => switch (p.state) {
    PassengerState.boarding => p.t < 0.5,
    PassengerState.leaving => p.t >= 0.5,
    _ => true,
  };

  /// Waving at the train: a gentle sway and a little bounce. Each animal gets
  /// its own phase from its name, so a row of them is not in lockstep.
  void _waiting(Canvas canvas, LittleTrainGame g, Passenger p, double ground) {
    final image = g.images.fromCache(LittleTrainAssets.waiting(p.animal));
    final phase = p.animal.hashCode % 7.0;
    final bounce = sin(_clock * 5 + phase).abs() * 0.012 * g.unit;
    final rect = standing(
      image,
      g.screenX(p.x),
      ground - bounce,
      standHeight * g.unit,
    );
    if (rect.right < 0 || rect.left > g.size.x) return;
    drawPicture(
      canvas,
      image,
      rect,
      rotation: sin(_clock * 3 + phase) * 0.06,
    );
  }

  /// Trotting or chasing: quick hops. Chasers hop faster and higher — the
  /// scamper is the slapstick that makes a missed stop funny, not sad.
  void _hopping(Canvas canvas, LittleTrainGame g, Passenger p, double ground) {
    final image = g.images.fromCache(LittleTrainAssets.waiting(p.animal));
    final chasing = p.state == PassengerState.chasing;
    final rate = chasing ? 16.0 : 11.0;
    final lift = (chasing ? 0.07 : 0.04) * g.unit;
    final hop = sin(_clock * rate).abs() * lift;
    final lean = chasing ? 0.18 : 0.08;
    drawPicture(
      canvas,
      image,
      standing(image, g.screenX(p.x), ground - hop, standHeight * g.unit),
      rotation: lean * (g.ride.doorX(p.wagon!) >= p.x ? 1 : -1),
    );
  }

  /// The leap in: an arc from where they stood to just above their wagon,
  /// shrinking to riding size and switching to the arms-up picture at the top.
  void _leaping(Canvas canvas, LittleTrainGame g, Passenger p, double ground) {
    final t = p.t;
    final toX = g.ride.doorX(p.wagon!);
    final x = p.fromX + (toX - p.fromX) * t;
    final seatBottom = TrainView.riderBottom(g);
    final baseY = ground + (seatBottom - ground) * t;
    final arc = sin(t * pi) * 0.2 * g.unit;
    final height =
        (standHeight + (TrainView.riderHeight - standHeight) * t) * g.unit;
    final image = g.images.fromCache(
      t < 0.5
          ? LittleTrainAssets.waiting(p.animal)
          : LittleTrainAssets.riding(p.animal),
    );
    drawPicture(
      canvas,
      image,
      standing(image, g.screenX(x), baseY - arc, height),
      rotation: sin(t * pi * 2) * 0.25,
    );
  }

  /// At the station: one hop down to the platform, then waving until they
  /// fade away into the station.
  void _leaving(Canvas canvas, LittleTrainGame g, Passenger p, double ground) {
    final t = p.t;
    final leap = t.clamp(0.0, 1.0);
    final x = p.fromX + (p.toX - p.fromX) * leap;
    final seatBottom = TrainView.riderBottom(g);
    final baseY = seatBottom + (ground - seatBottom) * leap;
    final arc = sin(leap * pi) * 0.22 * g.unit;
    final wave = t > 1 ? sin(_clock * 6) * 0.08 : 0.0;
    final image = g.images.fromCache(
      t < 0.5
          ? LittleTrainAssets.riding(p.animal)
          : LittleTrainAssets.waiting(p.animal),
    );
    drawPicture(
      canvas,
      image,
      standing(image, g.screenX(x), baseY - arc, standHeight * g.unit),
      rotation: wave,
      // Fade only in the last stretch, after a good long wave.
      opacity: t < 3 ? 1 : 4 - t,
    );
  }
}
