import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../assets.dart';
import '../little_train_game.dart';
import '../ride.dart';
import 'draw.dart';

/// The engine, its wagons, whoever is riding in them, and the steam.
///
/// The train never moves across the screen — the world scrolls under it — so
/// everything here is drawn relative to [LittleTrainGame.frontX].
class TrainView extends Component with HasGameReference<LittleTrainGame> {
  /// How tall a rider is drawn. Their lower half is hidden behind the wagon
  /// side, so what shows is a cheering head and arms over the edge.
  static const riderHeight = 0.23;

  /// Where a rider's feet are: inside the wagon, below its rim.
  static double riderBottom(LittleTrainGame g) => g.railY - 0.063 * g.unit;

  double _clock = 0;
  final _puffs = <_Puff>[];
  double _sincePuff = 0;
  final _random = Random(3);

  /// A big double puff — the visible half of a toot.
  void toot() {
    for (var i = 0; i < 4; i++) {
      _puff(scale: 1.4, delay: i * 0.08);
    }
  }

  @override
  void update(double dt) {
    final ride = game.ride;
    final pace = ride.speed / Ride.cruiseSpeed;
    _clock += dt * (0.3 + pace);

    // Chuff faster the faster it goes, and a lazy puff now and then at rest
    // so a stopped train still looks alive.
    _sincePuff += dt;
    final every = pace > 0.05 ? 0.45 / pace.clamp(0.4, 1.0) : 1.6;
    if (_sincePuff >= every) {
      _sincePuff = 0;
      _puff(scale: pace > 0.05 ? 1 : 0.7);
    }

    final drift = ride.speed * game.unit;
    for (final p in _puffs) {
      p.update(dt, drift);
    }
    _puffs.removeWhere((p) => p.done);
  }

  void _puff({double scale = 1, double delay = 0}) {
    _puffs.add(_Puff(
      x: 0,
      y: 0,
      radius: (0.022 + _random.nextDouble() * 0.012) * scale,
      age: -delay,
    ));
  }

  @override
  void render(Canvas canvas) {
    final g = game;
    final ride = g.ride;
    final unit = g.unit;
    final pace = ride.speed / Ride.cruiseSpeed;
    final wagon = g.images.fromCache(LittleTrainAssets.wagon);
    final engine = g.images.fromCache(LittleTrainAssets.engine);

    // Each car rocks on its own beat, so the train reads as several things
    // coupled together rather than one stiff picture.
    double bob(int i) =>
        -sin(_clock * 13 + i * 1.7).abs() * 0.007 * unit * pace.clamp(0.0, 1.0);

    // Riders first, so the wagon sides cover their legs.
    for (final p in ride.passengers) {
      if (p.state != PassengerState.riding) continue;
      final image = g.images.fromCache(LittleTrainAssets.riding(p.animal));
      final i = p.wagon!;
      final wiggle = sin(_clock * 4 + i * 2.1) * 0.1;
      drawPicture(
        canvas,
        image,
        standing(
          image,
          g.screenX(ride.doorX(i)),
          riderBottom(g) + bob(i) * 2,
          riderHeight * unit,
        ),
        rotation: wiggle,
      );
    }

    for (var i = 0; i < 3; i++) {
      final width = Ride.wagonWidth * unit;
      final height = width * wagon.height / wagon.width;
      final cx = g.screenX(ride.doorX(i));
      drawPicture(
        canvas,
        wagon,
        Rect.fromLTWH(cx - width / 2, g.railY - height + bob(i + 1), width, height),
      );
    }

    final width = Ride.engineWidth * unit;
    final height = width * engine.height / engine.width;
    final right = g.frontX;
    // A small nod forward while braking: the train is SEEN to answer the tap
    // the instant it lands, before the slowing down is noticeable.
    final nod = ride.phase == TrainPhase.braking ? 0.035 : 0.0;
    final engineRect = Rect.fromLTWH(
      right - width,
      g.railY - height + bob(0),
      width,
      height,
    );
    // Generated facing left; the train goes right.
    drawPicture(canvas, engine, engineRect, flip: true, rotation: nod);

    // Steam leaves the chimney, which on the flipped picture is ~70% of the
    // way along and a quarter of the way down.
    final chimney = Offset(
      engineRect.left + engineRect.width * 0.7,
      engineRect.top + engineRect.height * 0.22,
    );
    final paint = Paint();
    for (final p in _puffs) {
      if (p.age < 0) continue;
      paint.color = Color.fromRGBO(255, 255, 255, p.opacity * 0.75);
      canvas.drawCircle(
        chimney + Offset(p.x, p.y) * unit,
        p.radius * unit * (1 + p.age * 1.4),
        paint,
      );
    }
  }
}

/// One soft round steam puff. Rises, swells and fades; never flashes.
class _Puff {
  _Puff({required this.x, required this.y, required this.radius, required this.age});

  double x;
  double y;
  final double radius;
  double age;

  static const life = 1.4;

  bool get done => age >= life;
  double get opacity => (1 - age / life).clamp(0.0, 1.0);

  void update(double dt, double drift) {
    age += dt;
    if (age < 0) return;
    y -= 0.12 * dt;
    // Left behind by the moving train, in ride units.
    x -= (drift > 0 ? 0.25 : 0.03) * dt;
  }
}
